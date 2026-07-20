import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/services/checkout_service.dart';
import 'package:latercia/core/services/shift_service.dart';

void main() {
  late AppDatabase db;
  late ShiftService shiftService;
  late CheckoutService checkout;

  setUp(() async {
    // Fresh in-memory DB per test. onCreate runs the seeder, so employee id
    // 1 (admin) already exists.
    db = AppDatabase.forTesting(NativeDatabase.memory());
    shiftService = ShiftService(db);
    checkout = CheckoutService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('apertura de turno', () {
    test('no se puede abrir un turno si ya hay uno abierto', () async {
      await shiftService.openShift(employeeId: 1, startingCash: 100);
      expect(
        () => shiftService.openShift(employeeId: 1, startingCash: 200),
        throwsA(isA<StateError>()),
      );
      // Still just the one shift open.
      final open = await db.shiftsDao.getCurrentOpenShift();
      expect(open!.startingCash, 100);
    });
  });

  group('CheckoutService.checkout estampa shiftId', () {
    test('deja shiftId null cuando no hay turno abierto', () async {
      final result = await checkout.checkout(
        cartItems: const [],
        type: 'para_llevar',
        employeeId: 1,
        total: 50,
        paymentMethod: 'efectivo',
        amountTendered: 50,
      );
      expect(result.order.shiftId, isNull);
      final payments =
          await db.paymentsDao.getPaymentsForOrder(result.order.id);
      expect(payments.single.shiftId, isNull);
    });

    test('estampa shiftId del turno abierto en orden y pago', () async {
      final shift =
          await shiftService.openShift(employeeId: 1, startingCash: 100);

      final result = await checkout.checkout(
        cartItems: const [],
        type: 'para_llevar',
        employeeId: 1,
        total: 50,
        paymentMethod: 'efectivo',
        amountTendered: 50,
      );

      expect(result.order.shiftId, shift.id);
      final payments =
          await db.paymentsDao.getPaymentsForOrder(result.order.id);
      expect(payments.single.shiftId, shift.id);
    });
  });

  group('arqueo de caja', () {
    test(
        'esperado combina fondo inicial, ventas en efectivo, depósitos '
        'y retiros; la diferencia se calcula contra lo contado', () async {
      final shift =
          await shiftService.openShift(employeeId: 1, startingCash: 100);

      // Cash sale.
      await checkout.checkout(
        cartItems: const [],
        type: 'para_llevar',
        employeeId: 1,
        total: 80,
        paymentMethod: 'efectivo',
        amountTendered: 100,
        changeGiven: 20,
      );
      // Card sale — must not affect cash math.
      await checkout.checkout(
        cartItems: const [],
        type: 'para_llevar',
        employeeId: 1,
        total: 40,
        paymentMethod: 'tarjeta',
        amountTendered: 40,
      );

      await shiftService.addCashMovement(
        shiftId: shift.id,
        employeeId: 1,
        type: 'deposito',
        amount: 50,
      );
      await shiftService.addCashMovement(
        shiftId: shift.id,
        employeeId: 1,
        type: 'retiro',
        amount: 30,
        reason: 'compra insumos',
      );

      // startingCash 100 + cashSales(100-20=80) + deposits 50 - withdrawals 30 = 200
      final summary = await shiftService.computeSummary(shift.id);
      expect(summary.cashSales, 80);
      expect(summary.deposits, 50);
      expect(summary.withdrawals, 30);
      expect(summary.expectedCash, 200);
      expect(summary.paymentsByMethod['tarjeta'], 40);

      final withCount =
          await shiftService.computeSummary(shift.id, countedCash: 195);
      expect(withCount.difference, -5);
    });
  });

  group('zNumber consecutivo', () {
    test('sube de 1 en 1 entre turnos cerrados', () async {
      final s1 = await shiftService.openShift(employeeId: 1, startingCash: 0);
      final z1 = await shiftService.closeShift(
          shiftId: s1.id, employeeId: 1, countedCash: 0);
      expect(z1.shift.zNumber, 1);

      final s2 = await shiftService.openShift(employeeId: 1, startingCash: 0);
      final z2 = await shiftService.closeShift(
          shiftId: s2.id, employeeId: 1, countedCash: 0);
      expect(z2.shift.zNumber, 2);

      final s3 = await shiftService.openShift(employeeId: 1, startingCash: 0);
      final z3 = await shiftService.closeShift(
          shiftId: s3.id, employeeId: 1, countedCash: 0);
      expect(z3.shift.zNumber, 3);

      final closed = await db.shiftsDao.getClosedShifts();
      expect(closed, hasLength(3));
    });

    test('cerrar un turno libera el sistema para abrir otro', () async {
      final s1 = await shiftService.openShift(employeeId: 1, startingCash: 0);
      await shiftService.closeShift(
          shiftId: s1.id, employeeId: 1, countedCash: 0);
      expect(await db.shiftsDao.getCurrentOpenShift(), isNull);
      final s2 = await shiftService.openShift(employeeId: 1, startingCash: 20);
      expect(s2.startingCash, 20);
    });
  });

  group('Corte Z: desglose por método y descuentos', () {
    test('los totales cuadran con las órdenes/pagos del turno', () async {
      final shift =
          await shiftService.openShift(employeeId: 1, startingCash: 0);

      await checkout.checkout(
        cartItems: const [],
        type: 'mesa',
        employeeId: 1,
        subtotal: 100,
        discountAmount: 10,
        total: 90,
        paymentMethod: 'efectivo',
        amountTendered: 90,
      );
      await checkout.checkout(
        cartItems: const [],
        type: 'mesa',
        employeeId: 1,
        subtotal: 60,
        total: 60,
        paymentMethod: 'transferencia',
        amountTendered: 60,
      );

      final result = await shiftService.closeShift(
          shiftId: shift.id, employeeId: 1, countedCash: 90);

      expect(result.paymentsByMethod['efectivo'], 90);
      expect(result.paymentsByMethod['transferencia'], 60);
      expect(result.discountsTotal, 10);
      expect(result.shift.totalSales, 150);
      expect(result.cancelledCount, 0);

      final refreshed = await db.shiftsDao.getShiftById(shift.id);
      expect(refreshed!.endingCash, 90);
      expect(refreshed.totalSales, 150);
      expect(refreshed.zNumber, 1);
    });
  });
}
