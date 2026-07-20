import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/models/order_with_items.dart';
import 'package:latercia/core/providers/orders_provider.dart';
import 'package:latercia/core/services/checkout_service.dart';
import 'package:latercia/core/services/refund_service.dart';
import 'package:latercia/core/services/shift_service.dart';

/// FASE 5.5 — Suite de integración: ejercita el ciclo completo
/// venta → cocina → cobro → corte Z sobre una BD en memoria, pasando por los
/// servicios reales (no mocks): turnos, órdenes, cobro, propina, reembolso.
void main() {
  late AppDatabase db;
  late OrdersNotifier orders;
  late CheckoutService checkout;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    orders = OrdersNotifier(db);
    checkout = CheckoutService(db);
  });

  tearDown(() async {
    orders.dispose();
    await db.close();
  });

  Future<Product> product({double price = 50, int stock = 20}) async {
    final cats = await db.categoriesDao.getAllCategories();
    final id = await db.productsDao.insertProduct(
      ProductsCompanion.insert(
        name: 'Frappé de Café',
        price: price,
        categoryId: cats.first.id,
        trackInventory: const Value(true),
        stockQuantity: Value(stock),
      ),
    );
    return (await db.productsDao.getAllProducts())
        .firstWhere((p) => p.id == id);
  }

  test(
      'ciclo completo: abrir turno → cocina → listo → cobro con propina → '
      'corte Z consolida ventas, propinas y consecutivo', () async {
    // 1) Abrir turno con fondo.
    final shift =
        await ShiftService(db).openShift(employeeId: 1, startingCash: 500);

    // 2) Enviar dos órdenes a cocina (sin cobrar) — flujo mesa pay-at-the-end.
    final p = await product(price: 50, stock: 20);
    final o1 = await orders.sendToKitchen(
      cartItems: [CartItem(product: p, quantity: 2)], // 100
      type: 'mesa',
      employeeId: 1,
      tableId: 1,
      subtotal: 100,
      total: 100,
    );
    final o2 = await orders.sendToKitchen(
      cartItems: [CartItem(product: p, quantity: 1)], // 50
      type: 'para_llevar',
      employeeId: 1,
      subtotal: 50,
      total: 50,
    );
    expect(await _stock(db, p.id), 17, reason: '3 unidades reservadas');

    // 3) Cocina marca ambas listas.
    await orders.markReady(o1);
    await orders.markReady(o2);
    final ready = await db.ordersDao.getOrderById(o1);
    expect(ready!.status, 'listo');

    // 4) Cobrar ambas (una con propina en efectivo, otra con tarjeta).
    await checkout.chargeExistingOrder(
      orderId: o1,
      employeeId: 1,
      paymentMethod: 'efectivo',
      amountTendered: 130, // 100 venta + 15 propina, cambio 15
      changeGiven: 15,
      tipAmount: 15,
    );
    await checkout.chargeExistingOrder(
      orderId: o2,
      employeeId: 1,
      paymentMethod: 'tarjeta',
      amountTendered: 50,
    );

    final paid1 = await db.ordersDao.getOrderById(o1);
    expect(paid1!.paymentStatus, 'pagado');
    expect(paid1.status, 'entregado', reason: 'pagar una lista la entrega');

    // 5) Corte X (turno abierto): ventas por método, propinas.
    final x = await ShiftService(db).computeSummary(shift.id);
    expect(x.paymentsByMethod['efectivo'], 115); // 130 - 15 cambio
    expect(x.paymentsByMethod['tarjeta'], 50);
    expect(x.tipsTotal, 15);
    expect(x.expectedCash, 615, reason: '500 fondo + 115 efectivo');

    // 6) Cerrar turno (Z): consecutivo, totalSales de lo pagado.
    final z = await ShiftService(db)
        .closeShift(shiftId: shift.id, employeeId: 1, countedCash: 615);
    expect(z.difference, 0, reason: 'arqueo cuadra');
    final closed = await db.shiftsDao.getShiftById(shift.id);
    expect(closed!.endedAt, isNotNull);
    expect(closed.zNumber, 1, reason: 'primer corte Z');
    expect(closed.totalSales, 150, reason: '100 + 50 vendidos (sin propina)');
  });

  test('ciclo con reembolso: el corte Z refleja la devolución', () async {
    final shift =
        await ShiftService(db).openShift(employeeId: 1, startingCash: 100);
    final p = await product(price: 50, stock: 10);

    final sale = await checkout.checkout(
      cartItems: [CartItem(product: p, quantity: 2)],
      type: 'para_llevar',
      employeeId: 1,
      subtotal: 100,
      total: 100,
      paymentMethod: 'efectivo',
      amountTendered: 100,
    );

    await RefundService(db).refund(
      orderId: sale.order.id,
      amount: 30,
      employeeId: 1,
      supervisorId: 1,
      restock: false,
    );

    final z = await ShiftService(db)
        .closeShift(shiftId: shift.id, employeeId: 1, countedCash: 170);
    expect(z.refundsTotal, 30);
    // 100 fondo + 100 venta − 30 reembolso = 170.
    expect(z.expectedCash, 170);
    expect(z.difference, 0);
  });
}

Future<int> _stock(AppDatabase db, int productId) async =>
    (await db.productsDao.getAllProducts())
        .firstWhere((p) => p.id == productId)
        .stockQuantity;
