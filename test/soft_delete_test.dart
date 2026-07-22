import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';

/// Soft delete de órdenes y cortes: quedan en la BD pero se ocultan de listas,
/// reportes y cortes. Ver docs/soft-delete.md.
void main() {
  late AppDatabase db;
  late int empId;

  final desde = DateTime(2026, 7, 21);
  final hasta = DateTime(2026, 7, 22);
  final cuando = DateTime(2026, 7, 21, 12);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    empId = await db.employeesDao.insertEmployee(
        EmployeesCompanion.insert(name: 'Caja', pin: '1234', role: 'cashier'));
  });
  tearDown(() => db.close());

  Future<int> venta(String numero, double total, {int? shiftId}) async {
    final id = await db.ordersDao.insertOrder(OrdersCompanion.insert(
      orderNumber: numero,
      type: 'para_llevar',
      employeeId: empId,
      total: Value(total),
      paymentStatus: const Value('pagado'),
      shiftId: Value(shiftId),
      createdAt: Value(cuando),
    ));
    await db.into(db.payments).insert(PaymentsCompanion.insert(
          orderId: id,
          method: 'efectivo',
          amountTendered: total,
          createdAt: Value(cuando),
        ));
    return id;
  }

  test('softDeleteOrder oculta la orden de la lista y de los reportes',
      () async {
    final a = await venta('A', 100);
    await venta('B', 50);

    expect((await db.ordersDao.getOrdersByDateRange(desde, hasta)).length, 2);
    expect(await db.reportsDao.getTotalRevenueForRange(desde, hasta), 150);

    await db.ordersDao.softDeleteOrder(a);

    final list = await db.ordersDao.getOrdersByDateRange(desde, hasta);
    expect(list.map((o) => o.orderNumber), ['B']);
    expect(await db.reportsDao.getTotalRevenueForRange(desde, hasta), 50);
    expect(await db.reportsDao.getOrderCountForRange(desde, hasta), 1);
    // getOrderById SÍ la sigue devolviendo (para auditoría), marcada.
    expect((await db.ordersDao.getOrderById(a))?.deletedAt, isNotNull);
  });

  test('getActiveOrders y getOrdersByShift excluyen las eliminadas', () async {
    final sid = await db.shiftsDao.openShift(ShiftsCompanion.insert(
        employeeId: empId, startedAt: DateTime(2026, 7, 21, 8)));
    final a = await venta('A', 100, shiftId: sid);

    expect((await db.ordersDao.getActiveOrders()).length, 1);
    expect((await db.ordersDao.getOrdersByShift(sid)).length, 1);

    await db.ordersDao.softDeleteOrder(a);

    expect(await db.ordersDao.getActiveOrders(), isEmpty);
    expect(await db.ordersDao.getOrdersByShift(sid), isEmpty);
  });

  test('getSalesByPaymentMethod excluye pagos de órdenes eliminadas', () async {
    final a = await venta('A', 100);
    await venta('B', 50);

    var porMetodo = await db.reportsDao.getSalesByPaymentMethod(desde, hasta);
    expect(porMetodo['efectivo'], 150);

    await db.ordersDao.softDeleteOrder(a);

    porMetodo = await db.reportsDao.getSalesByPaymentMethod(desde, hasta);
    expect(porMetodo['efectivo'], 50);
  });

  test('softDeleteShift oculta el corte del historial', () async {
    final sid = await db.shiftsDao.openShift(ShiftsCompanion.insert(
        employeeId: empId, startedAt: DateTime(2026, 7, 21, 8)));
    await db.shiftsDao.closeShift(sid, 500, 1000, 1);

    expect((await db.shiftsDao.getClosedShifts()).length, 1);

    await db.shiftsDao.softDeleteShift(sid);

    expect(await db.shiftsDao.getClosedShifts(), isEmpty);
    // El número Z NO se reutiliza (getMaxZNumber cuenta también los borrados).
    expect(await db.shiftsDao.getMaxZNumber(), 1);
  });
}
