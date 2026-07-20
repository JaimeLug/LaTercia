import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/models/order_with_items.dart';
import 'package:latercia/core/providers/database_provider.dart';
import 'package:latercia/features/kds/widgets/order_card_kds.dart';

/// 2026-07-20 — reporte del dueño en sitio: en pedidos con muchos productos,
/// la tarjeta del KDS "se cortaba" — la lista de items YA tenía scroll
/// interno, pero sin ninguna señal visual de que hacía falta desplazar, así
/// que se leía como si eso fuera todo el pedido. Estas pruebas confirman que
/// ahora aparece un degradado con flecha ↓ SOLO cuando de verdad falta
/// contenido por ver, y no aparece cuando el pedido cabe completo.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_MX', null);
  });

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<OrderWithItems> makeOrder(String number,
      {required int itemCount}) async {
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

  Future<void> pumpCard(WidgetTester tester, OrderWithItems o) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              // Mismo tamaño de tarjeta que usa KdsOrderGrid en producción.
              width: 340,
              height: 480,
              child: OrderCardKds(orderWithItems: o),
            ),
          ),
        ),
      ),
    );
    // NO pumpAndSettle(): ElapsedTimer anima un parpadeo infinito para el
    // aviso de "atrasado" — colgaría para siempre (ver kds_order_grid_test).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('con muchos productos, aparece la flecha de "hay más abajo"',
      (tester) async {
    final order = await makeOrder('0001', itemCount: 15);

    await pumpCard(tester, order);

    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
  });

  testWidgets('con pocos productos (cabe completo), NO aparece la flecha',
      (tester) async {
    final order = await makeOrder('0002', itemCount: 1);

    await pumpCard(tester, order);

    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
  });
}
