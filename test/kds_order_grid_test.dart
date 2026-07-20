import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/models/order_with_items.dart';
import 'package:latercia/core/providers/database_provider.dart';
import 'package:latercia/features/kds/kds_screen.dart';
import 'package:latercia/features/kds/widgets/order_card_kds.dart';

/// 2026-07-20 — reporte en sitio (café abierto): con 6-7 pedidos activos, el
/// KDS los repartía en páginas fijas de tamaño 4; avanzar con "Siguiente"
/// saltaba de golpe a un lienzo completamente distinto, y las órdenes 5+
/// quedaban invisibles hasta hacer clic. `KdsOrderGrid` reemplaza eso por
/// scroll continuo: esta prueba confirma que TODAS las órdenes activas
/// conviven en el mismo árbol de widgets, sin importar cuántas haya.
void main() {
  setUpAll(() async {
    // formatTime (usado por OrderCardKds) usa el locale 'es_MX'.
    await initializeDateFormatting('es_MX', null);
  });

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  /// Crea una orden real (con [itemCount] productos) y la devuelve como
  /// [OrderWithItems], igual que las vería el KDS.
  Future<OrderWithItems> makeOrder(String number, {int itemCount = 1}) async {
    final products = await db.productsDao.getAllProducts();
    final orderId = await db.ordersDao.insertOrder(
      OrdersCompanion.insert(
        orderNumber: number,
        type: 'mesa',
        employeeId: 1,
        status: const Value('pendiente'),
      ),
    );
    for (var i = 0; i < itemCount; i++) {
      await db.orderItemsDao.insertOrderItems([
        OrderItemsCompanion.insert(
          orderId: orderId,
          productId: products[i % products.length].id,
          productName: products[i % products.length].name,
          quantity: 1,
          unitPrice: products[i % products.length].price,
        ),
      ]);
    }
    final order = await db.ordersDao.getOrderById(orderId);
    final items = await db.orderItemsDao.getItemsForOrder(orderId);
    return OrderWithItems(order: order!, items: items);
  }

  Future<void> pumpGrid(
    WidgetTester tester, {
    required List<OrderWithItems> orders,
    int? highlightId,
  }) async {
    final controller = ScrollController();
    final keys = <int, GlobalKey>{};
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: KdsOrderGrid(
              orders: orders,
              highlightId: highlightId,
              controller: controller,
              cardKeyFor: (id) => keys.putIfAbsent(id, () => GlobalKey()),
            ),
          ),
        ),
      ),
    );
    // NO pumpAndSettle(): ElapsedTimer (dentro de OrderCardKds) anima un
    // parpadeo infinito (`..repeat(reverse: true)`) para el aviso de
    // "atrasado" — nunca se asienta, así que pumpAndSettle() colgaría para
    // siempre. Un par de frames alcanza para inspeccionar el árbol.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets(
      'con muchas órdenes activas, TODAS quedan en el árbol (sin paginar)',
      (tester) async {
    final orders = <OrderWithItems>[];
    for (var i = 1; i <= 8; i++) {
      orders.add(await makeOrder('000$i'));
    }

    await pumpGrid(tester, orders: orders);

    // El bug original: solo las primeras 4 quedaban montadas, el resto vivía
    // en "otra página" invisible. Con scroll continuo, las 8 deben existir
    // en el árbol de widgets simultáneamente.
    expect(find.byType(OrderCardKds), findsNWidgets(8));
  });

  testWidgets('es scroll continuo: no queda ningún indicador de "Página X/Y"',
      (tester) async {
    final orders = <OrderWithItems>[];
    for (var i = 1; i <= 6; i++) {
      orders.add(await makeOrder('000$i'));
    }

    await pumpGrid(tester, orders: orders);

    // El Scrollbar de la cuadrícula tiene su propia Key: cada OrderCardKds
    // trae además su propio Scrollbar interno para su lista de items
    // (2026-07-20), así que find.byType(Scrollbar) por sí solo ya no basta.
    expect(find.byKey(const Key('kds-grid-scrollbar')), findsOneWidget);
    expect(find.textContaining(RegExp(r'Página \d+ */ *\d+')), findsNothing);
  });

  testWidgets('resalta la tarjeta seleccionada con el badge SELECCIONADA',
      (tester) async {
    final o1 = await makeOrder('0001');
    final o2 = await makeOrder('0002');

    await pumpGrid(tester, orders: [o1, o2], highlightId: o2.order.id);

    expect(find.text('SELECCIONADA'), findsOneWidget);
  });
}
