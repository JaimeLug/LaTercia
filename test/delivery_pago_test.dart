import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/services/checkout_service.dart';
import 'package:latercia/core/services/print_service.dart';

/// Pago esperado del delivery: método + con cuánto paga → cambio del
/// repartidor; transferencia marca la orden pagada. Ver docs/impresion.md.
void main() {
  group('deliveryChange (cambio del repartidor)', () {
    test('paga con más que el total → cambio', () {
      expect(deliveryChange(174, 200), closeTo(26, 0.001));
    });
    test('sin monto capturado → 0', () {
      expect(deliveryChange(174, null), 0);
    });
    test('paga con menos que el total → 0 (nunca negativo)', () {
      expect(deliveryChange(174, 100), 0);
    });
  });

  group('orden de delivery (contra la BD)', () {
    late AppDatabase db;
    late int empId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      empId = await db.employeesDao.insertEmployee(
          EmployeesCompanion.insert(name: 'e', pin: '1', role: 'cashier'));
    });
    tearDown(() => db.close());

    test('efectivo: queda por cobrar y guarda con cuánto paga', () async {
      final id = await db.ordersDao.insertOrder(OrdersCompanion.insert(
        orderNumber: 'D-1',
        type: 'delivery',
        employeeId: empId,
        total: const Value(174),
        deliveryPaymentMethod: const Value('efectivo'),
        deliveryCashAmount: const Value(200),
      ));
      final o = (await db.ordersDao.getOrderById(id))!;
      expect(o.paymentStatus, 'pendiente'); // NO aparece pagada
      expect(o.deliveryPaymentMethod, 'efectivo');
      expect(deliveryChange(o.total, o.deliveryCashAmount), closeTo(26, 0.001));
    });

    test('transferencia: chargeExistingOrder marca la orden pagada', () async {
      final id = await db.ordersDao.insertOrder(OrdersCompanion.insert(
        orderNumber: 'D-2',
        type: 'delivery',
        employeeId: empId,
        total: const Value(100),
        deliveryPaymentMethod: const Value('transferencia'),
      ));

      await CheckoutService(db).chargeExistingOrder(
        orderId: id,
        employeeId: empId,
        paymentMethod: 'transferencia',
        amountTendered: 100,
      );

      final o = (await db.ordersDao.getOrderById(id))!;
      expect(o.paymentStatus, 'pagado');
      final pagos = await db.paymentsDao.getPaymentsForOrder(id);
      expect(pagos.single.method, 'transferencia');
    });
  });
}
