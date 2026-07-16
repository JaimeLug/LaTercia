import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/models/order_with_items.dart';
import 'package:latercia/core/providers/orders_provider.dart';
import 'package:latercia/core/utils/formatters.dart';

void main() {
  late AppDatabase db;
  late OrdersNotifier notifier;

  setUp(() async {
    // Fresh in-memory DB per test. onCreate runs the seeder, so the default
    // admin employee (id 1), tables (ids 1..6) and products already exist.
    db = AppDatabase.forTesting(NativeDatabase.memory());
    notifier = OrdersNotifier(db);
  });

  tearDown(() async {
    notifier.dispose();
    await db.close();
  });

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Future<Product> anyProduct() async =>
      (await db.productsDao.getAllProducts()).first;

  Future<Product> trackedProduct({int stock = 10}) async {
    final cats = await db.categoriesDao.getAllCategories();
    final id = await db.productsDao.insertProduct(
      ProductsCompanion.insert(
        name: 'Producto rastreado',
        price: 50,
        categoryId: cats.first.id,
        trackInventory: const Value(true),
        stockQuantity: Value(stock),
      ),
    );
    return (await db.productsDao.getAllProducts())
        .firstWhere((p) => p.id == id);
  }

  Future<int> send(Product p, {int qty = 1, int? tableId}) {
    return notifier.sendToKitchen(
      cartItems: [CartItem(product: p, quantity: qty)],
      type: tableId != null ? 'mesa' : 'para_llevar',
      employeeId: 1,
      tableId: tableId,
      total: p.price * qty,
    );
  }

  Future<String> tableStatus(int id) async =>
      (await db.tablesDao.getAllTables()).firstWhere((t) => t.id == id).status;

  Future<int> stockOf(int productId) async =>
      (await db.productsDao.getAllProducts())
          .firstWhere((p) => p.id == productId)
          .stockQuantity;

  // ─── C3 — order numbering ────────────────────────────────────────────────

  test('orderNumber se deriva del id real y es único (C3)', () async {
    final p = await anyProduct();
    final id1 = await send(p);
    final id2 = await send(p);

    final o1 = await db.ordersDao.getOrderById(id1);
    final o2 = await db.ordersDao.getOrderById(id2);

    expect(o1!.orderNumber, formatOrderNumber(id1));
    expect(o2!.orderNumber, formatOrderNumber(id2));
    expect(o1.orderNumber, isNot(o2.orderNumber));
    // The temporary placeholder must never survive the insert.
    expect(o1.orderNumber.startsWith('tmp-'), isFalse);
  });

  // ─── C2 — atomic create ──────────────────────────────────────────────────

  test('sendToKitchen persiste la orden con sus items (C2)', () async {
    final p = await anyProduct();
    final id = await send(p, qty: 2);

    final items = await db.orderItemsDao.getItemsForOrder(id);
    expect(items, hasLength(1));
    expect(items.first.quantity, 2);
    expect(items.first.productId, p.id);
  });

  // ─── C1 — paid is not delivered ──────────────────────────────────────────

  test('cobrar no marca entregado si la cocina no terminó (C1)', () async {
    final p = await anyProduct();
    final id = await send(p, tableId: 1);

    await notifier.markPaid(id, 1);

    final o = await db.ordersDao.getOrderById(id);
    expect(o!.paymentStatus, 'pagado');
    expect(o.status, isNot('entregado'),
        reason: 'pagar no debe sacar el pedido de la cocina');

    final active = await db.ordersDao.getActiveOrders();
    expect(active.any((x) => x.id == id), isTrue,
        reason: 'el ticket sigue visible en el KDS');
    expect(await tableStatus(1), 'occupied');
  });

  test('cocina termina una orden ya pagada → entregada y libera mesa (C1)',
      () async {
    final p = await anyProduct();
    final id = await send(p, tableId: 2);

    await notifier.markPaid(id, 2); // pagada pero no lista
    await notifier.markReady(id); // la cocina la termina

    final o = await db.ordersDao.getOrderById(id);
    expect(o!.status, 'entregado');
    expect(o.completedAt, isNotNull);

    final active = await db.ordersDao.getActiveOrders();
    expect(active.any((x) => x.id == id), isFalse);
    expect(await tableStatus(2), 'available');
  });

  test('flujo mesa: lista sin pagar queda en "listo"; al cobrar se entrega (C1)',
      () async {
    final p = await anyProduct();
    final id = await send(p, tableId: 3);

    await notifier.markReady(id); // aún sin pagar
    var o = await db.ordersDao.getOrderById(id);
    expect(o!.status, 'listo');
    expect(o.paymentStatus, 'pendiente');
    expect(await tableStatus(3), 'occupied');

    await notifier.markPaid(id, 3); // el cajero cobra al final
    o = await db.ordersDao.getOrderById(id);
    expect(o!.status, 'entregado');
    expect(await tableStatus(3), 'available');
  });

  // ─── C4 — cancellation restores inventory ────────────────────────────────

  test('cancelar una orden devuelve el inventario (C4)', () async {
    final p = await trackedProduct(stock: 10);
    final id = await send(p, qty: 3);
    expect(await stockOf(p.id), 7, reason: 'descontado al enviar a cocina');

    await notifier.cancelOrder(id, 'prueba', null);

    expect(await stockOf(p.id), 10, reason: 'restaurado al cancelar');
    final o = await db.ordersDao.getOrderById(id);
    expect(o!.status, 'cancelado');

    final moves = await db.inventoryDao.getMovementsForProduct(p.id);
    expect(moves.any((m) => m.reason == 'cancelacion' && m.delta == 3), isTrue);
  });

  test('cancelar dos veces no duplica la devolución de stock (C4)', () async {
    final p = await trackedProduct(stock: 5);
    final id = await send(p, qty: 2);

    await notifier.cancelOrder(id, 'r1', null); // 3 → 5
    await notifier.cancelOrder(id, 'r2', null); // guarda: no-op

    expect(await stockOf(p.id), 5);
  });

  // ─── 1.4 — anti N+1 ────────────────────────────────────────────────────

  test('getActiveOrdersWithItems (JOIN) devuelve lo mismo que el patrón N+1 '
      'anterior (misma orden, mismos items)', () async {
    final p = await anyProduct();
    await send(p, qty: 2, tableId: 1);
    await send(p, qty: 1, tableId: 4);

    // Old N+1 shape, reconstructed manually for comparison.
    final oldStyleOrders = await db.ordersDao.getActiveOrders();
    final expected = <OrderWithItems>[];
    for (final order in oldStyleOrders) {
      final items = await db.orderItemsDao.getItemsForOrder(order.id);
      expected.add(OrderWithItems(order: order, items: items));
    }

    final joined = await db.ordersDao.getActiveOrdersWithItems();

    expect(joined.length, expected.length);
    for (var i = 0; i < expected.length; i++) {
      expect(joined[i].order.id, expected[i].order.id);
      expect(joined[i].items.map((it) => it.id).toSet(),
          expected[i].items.map((it) => it.id).toSet());
      expect(joined[i].items.length, expected[i].items.length);
    }
  });

  // ─── 3.4 — Recall en KDS ─────────────────────────────────────────────────

  test('recall deshace la última orden marcada lista (no pagada) (3.4)',
      () async {
    final p = await anyProduct();
    final id = await send(p, tableId: 1);
    await notifier.updateStatus(id, 'en_preparacion');

    await notifier.markReady(id); // sin pagar → 'listo'
    expect((await db.ordersDao.getOrderById(id))!.status, 'listo');
    expect(notifier.canRecall, isTrue);

    final done = await notifier.recallLastReady();
    expect(done, isTrue);
    // Vuelve al estado que tenía antes de marcarse lista.
    expect((await db.ordersDao.getOrderById(id))!.status, 'en_preparacion');
    // Ya no hay nada que recuperar.
    expect(notifier.canRecall, isFalse);
    expect(await notifier.recallLastReady(), isFalse);
  });

  test('recall de una orden pagada la saca de entregado y reocupa la mesa (3.4)',
      () async {
    final p = await anyProduct();
    final id = await send(p, tableId: 2);
    await notifier.markPaid(id, 2); // pagada, sigue en cocina

    await notifier.markReady(id); // pagada + lista → entregada, libera mesa
    var o = await db.ordersDao.getOrderById(id);
    expect(o!.status, 'entregado');
    expect(o.completedAt, isNotNull);
    expect(await tableStatus(2), 'available');

    final done = await notifier.recallLastReady();
    expect(done, isTrue);
    o = await db.ordersDao.getOrderById(id);
    expect(o!.status, 'pendiente', reason: 'vuelve al estado previo');
    expect(o.completedAt, isNull, reason: 'ya no está completada');
    expect(await tableStatus(2), 'occupied', reason: 'la mesa se reocupa');
    // El pago se conserva.
    expect(o.paymentStatus, 'pagado');
  });
}
