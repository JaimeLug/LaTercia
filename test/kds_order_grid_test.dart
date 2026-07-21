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

  /// Devuelve las GlobalKeys por orden (para poder medir el tamaño
  /// renderizado de cada tarjeta con `tester.getSize`).
  Future<Map<int, GlobalKey>> pumpGrid(
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
            // Alto fijo y conocido, para que el tope de altura de las
            // tarjetas (calculado por KdsOrderGrid vía LayoutBuilder) sea
            // determinista en la prueba.
            body: SizedBox(
              height: 700,
              child: KdsOrderGrid(
                orders: orders,
                highlightId: highlightId,
                controller: controller,
                cardKeyFor: (id) => keys.putIfAbsent(id, () => GlobalKey()),
              ),
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
    return keys;
  }

  testWidgets(
      'una tarjeta corta se renderiza MÁS BAJA que una larga (crece con '
      'el contenido, 3ª pasada — antes todas eran siempre 480px fijos)',
      (tester) async {
    final short = await makeOrder('0001', itemCount: 1);
    final long = await makeOrder('0002', itemCount: 15);

    final keys = await pumpGrid(tester, orders: [short, long]);

    final shortHeight =
        tester.getSize(find.byKey(keys[short.order.id]!)).height;
    final longHeight = tester.getSize(find.byKey(keys[long.order.id]!)).height;

    expect(shortHeight, lessThan(longHeight),
        reason: 'un pedido de 1 producto debe rendir una tarjeta más baja '
            'que uno de 15 — ya no todas son siempre el mismo alto fijo');
    // El tope viene de KdsOrderGrid: alto del contenedor (700) - padding
    // vertical (pad*2 = 40) = 660. Ninguna tarjeta debe pasarse de eso.
    expect(shortHeight, lessThanOrEqualTo(660));
    expect(longHeight, lessThanOrEqualTo(660));
  });

  testWidgets(
      'un solo pedido queda pegado a la esquina izquierda, no centrado '
      '(feedback en sitio 2026-07-21)', (tester) async {
    final o = await makeOrder('0001');
    final keys = await pumpGrid(tester, orders: [o]);

    // La tarjeta debe arrancar cerca del borde izquierdo (~padding), no
    // flotando al centro de la pantalla.
    final left = tester.getTopLeft(find.byKey(keys[o.order.id]!)).dx;
    expect(left, lessThan(40),
        reason: 'con un solo pedido la tarjeta debe quedar en la esquina '
            'izquierda, no centrada');
  });

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

  testWidgets(
      'el scroll ENTRE pedidos es horizontal (2ª pasada, feedback en VM: '
      'antes era vertical y se veía confuso con el de la tarjeta)',
      (tester) async {
    final orders = <OrderWithItems>[];
    for (var i = 1; i <= 6; i++) {
      orders.add(await makeOrder('000$i'));
    }

    await pumpGrid(tester, orders: orders);

    final scrollView = tester.widget<SingleChildScrollView>(
      find.byKey(const Key('kds-grid-scroll-view')),
    );
    expect(scrollView.scrollDirection, Axis.horizontal);
  });

  testWidgets('resalta la tarjeta seleccionada con el badge SELECCIONADA',
      (tester) async {
    final o1 = await makeOrder('0001');
    final o2 = await makeOrder('0002');

    await pumpGrid(tester, orders: [o1, o2], highlightId: o2.order.id);

    expect(find.text('SELECCIONADA'), findsOneWidget);
  });
}
