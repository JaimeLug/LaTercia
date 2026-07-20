import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/providers/database_provider.dart';
import 'package:latercia/core/services/kds_button_service.dart';
import 'package:latercia/features/kds/kds_screen.dart';

/// 2026-07-20 — la cocina solo tiene 6 botones físicos (dos flechas, recall,
/// prep, listo, tiempo), sin mouse ni pantalla táctil. Antes, Anterior/
/// Siguiente solo cambiaban de ORDEN (movimiento horizontal); no había forma
/// de bajar dentro de un pedido largo ni en la vista All-day (movimiento
/// vertical). Estas pruebas alimentan la botonera directo por el provider
/// (sin sockets reales) y confirman el comportamiento contextual nuevo.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_MX', null);
  });

  late AppDatabase db;
  late StreamController<KdsButton> buttonController;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    buttonController = StreamController<KdsButton>.broadcast();
  });

  tearDown(() async {
    await buttonController.close();
    await db.close();
  });

  /// Crea una orden real con [itemCount] productos y una hora de creación
  /// explícita (para controlar el orden de la cola, en vez de depender de
  /// que dos inserciones consecutivas caigan en marcas de tiempo distintas).
  Future<void> makeOrder(String number,
      {required int itemCount, required DateTime createdAt}) async {
    final products = await db.productsDao.getAllProducts();
    final orderId = await db.ordersDao.insertOrder(
      OrdersCompanion.insert(
        orderNumber: number,
        type: 'mesa',
        employeeId: 1,
        status: const Value('pendiente'),
        createdAt: Value(createdAt),
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
  }

  Future<void> pumpKds(WidgetTester tester) async {
    await db.settingsDao.setValue('botonera_activa', 'true');
    // El viewport por default del test (800px lógicos) es más angosto que
    // el monitor real de cocina (DisplayPort-1, 1360×768 en el sitio — ver
    // BITACORA_INSTALACION_2026-07-18) y el header del KDS desborda ahí.
    // Se restaura solo al terminar el test (addTearDown).
    tester.view.physicalSize = const Size(1360, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          kdsButtonStreamProvider.overrideWithValue(buttonController.stream),
        ],
        child: const MaterialApp(home: KdsScreen()),
      ),
    );
    // NO pumpAndSettle(): ElapsedTimer anima un parpadeo infinito (ver
    // kds_order_grid_test.dart). Un par de frames alcanza.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> press(WidgetTester tester, KdsButton btn) async {
    buttonController.add(btn);
    await tester.pump();
    // 350ms: deja que el animateTo() del scroll (300ms, easeInOut) TERMINE
    // antes de la siguiente presión — si se corta a medio camino, la curva
    // easeInOut arranca lenta cada vez y casi no avanza (así se descubrió
    // este ajuste: con 50ms, 20 presiones no alcanzaban a agotar el scroll).
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets(
      'con un pedido largo seleccionado, Siguiente lo desplaza ANTES de '
      'cambiar de orden', (tester) async {
    final now = DateTime.now();
    // A: pedido largo (desborda la tarjeta) y es el más viejo → seleccionado
    // primero por defecto. B: pedido corto, más nuevo.
    await makeOrder('0001', itemCount: 15, createdAt: now);
    await makeOrder('0002',
        itemCount: 1, createdAt: now.add(const Duration(minutes: 1)));

    await pumpKds(tester);

    // Selección inicial: la orden 0001 (la más vieja).
    expect(find.textContaining('Seleccionada: 0001'), findsOneWidget);

    await press(tester, KdsButton.siguiente);

    // Con contenido oculto en 0001, el primer "Siguiente" debe desplazar la
    // tarjeta, NO cambiar de orden — la selección sigue siendo 0001.
    expect(find.textContaining('Seleccionada: 0001'), findsOneWidget,
        reason: 'el primer Siguiente debe desplazar el pedido largo, no '
            'saltar a la otra orden');

    // Presionar varias veces más debe eventualmente agotar el scroll de esa
    // tarjeta y SÍ pasar a la orden 0002 (el fallback no debe quedar roto).
    for (var i = 0; i < 20; i++) {
      await press(tester, KdsButton.siguiente);
      if (find.textContaining('Seleccionada: 0002').evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.textContaining('Seleccionada: 0002'), findsOneWidget,
        reason: 'tras agotar el scroll del pedido largo, Siguiente debe '
            'terminar cambiando de orden');
  });

  testWidgets(
      'con pedidos cortos (caben completos), Siguiente cambia de orden '
      'directo, sin pausa', (tester) async {
    final now = DateTime.now();
    await makeOrder('0001', itemCount: 1, createdAt: now);
    await makeOrder('0002',
        itemCount: 1, createdAt: now.add(const Duration(minutes: 1)));

    await pumpKds(tester);

    expect(find.textContaining('Seleccionada: 0001'), findsOneWidget);

    await press(tester, KdsButton.siguiente);

    // Sin contenido oculto, el primer Siguiente ya debe cambiar de orden —
    // comportamiento previo, sin regresión para el caso común.
    expect(find.textContaining('Seleccionada: 0002'), findsOneWidget);
  });

  testWidgets('en vista All-day, Siguiente desplaza la lista verticalmente',
      (tester) async {
    final now = DateTime.now();
    // Muchas órdenes con muchos productos DISTINTOS para que la lista
    // consolidada de All-day tenga contenido de sobra para desbordar.
    for (var i = 0; i < 10; i++) {
      await makeOrder('000$i',
          itemCount: 8, createdAt: now.add(Duration(minutes: i)));
    }

    await pumpKds(tester);

    // TIEMPO alterna a la vista All-day.
    await press(tester, KdsButton.tiempo);

    final listView = tester.widget<ListView>(find.byType(ListView));
    final controller = listView.controller!;
    expect(controller.hasClients, isTrue);
    expect(controller.position.pixels, 0,
        reason: 'arranca al inicio de la lista');

    await press(tester, KdsButton.siguiente);

    expect(controller.position.pixels, greaterThan(0),
        reason: 'Siguiente en All-day debe desplazar la lista hacia abajo');
  });

  group('All-day agrupa por producto + modificadores (2026-07-20)', () {
    /// Inserta una orden con UN item de [productName], opcionalmente con
    /// [modifiersJson] — para probar que All-day agrupa por la combinación
    /// exacta, no solo por nombre de producto.
    Future<void> makeOrderWithItem(
      String number, {
      required String productName,
      String? modifiersJson,
      required DateTime createdAt,
    }) async {
      final products = await db.productsDao.getAllProducts();
      final product = products.firstWhere((p) => p.name == productName);
      final orderId = await db.ordersDao.insertOrder(
        OrdersCompanion.insert(
          orderNumber: number,
          type: 'mesa',
          employeeId: 1,
          status: const Value('pendiente'),
          createdAt: Value(createdAt),
        ),
      );
      await db.orderItemsDao.insertOrderItems([
        OrderItemsCompanion.insert(
          orderId: orderId,
          productId: product.id,
          productName: product.name,
          quantity: 1,
          unitPrice: product.price,
          modifiersJson: modifiersJson == null
              ? const Value.absent()
              : Value(modifiersJson),
        ),
      ]);
    }

    testWidgets(
        'un pedido CON modificador no se mezcla con uno SIN modificador',
        (tester) async {
      final now = DateTime.now();
      final products = await db.productsDao.getAllProducts();
      final productName = products.first.name;

      await makeOrderWithItem('0001',
          productName: productName, createdAt: now);
      await makeOrderWithItem('0002',
          productName: productName,
          modifiersJson: '[{"name":"Sin azúcar","included":false}]',
          createdAt: now.add(const Duration(minutes: 1)));

      await pumpKds(tester);
      await press(tester, KdsButton.tiempo); // → vista All-day

      // Dos líneas separadas de "1×" (una por cada combinación), NO una
      // sola de "2×" — antes se sumaban juntas perdiendo el modificador.
      expect(find.text('1×'), findsNWidgets(2));
      expect(find.text('2×'), findsNothing);
      expect(find.text('↳ Sin azúcar'), findsOneWidget);
    });

    testWidgets('dos pedidos con el MISMO modificador sí se suman',
        (tester) async {
      final now = DateTime.now();
      final products = await db.productsDao.getAllProducts();
      final productName = products.first.name;
      const mods = '[{"name":"Extra shot","included":false}]';

      await makeOrderWithItem('0001',
          productName: productName, modifiersJson: mods, createdAt: now);
      await makeOrderWithItem('0002',
          productName: productName,
          modifiersJson: mods,
          createdAt: now.add(const Duration(minutes: 1)));

      await pumpKds(tester);
      await press(tester, KdsButton.tiempo);

      expect(find.text('2×'), findsOneWidget);
      expect(find.text('↳ Extra shot'), findsOneWidget);
    });

    testWidgets(
        'las variantes del MISMO producto quedan SEGUIDAS, sin que otro '
        'producto se meta en medio (feedback en VM sobre el orden)',
        (tester) async {
      final now = DateTime.now();
      final products = await db.productsDao.getAllProducts();
      final productA = products[0].name;
      final productB = products[1].name;

      // A-plano × 3, B × 2, A-"sin azúcar" × 1. Con el orden VIEJO (solo por
      // cantidad) quedaría: A-plano(3), B(2), A-sin-azúcar(1) — B metido en
      // medio de las dos variantes de A. Con el nuevo orden (agrupado por
      // producto, el de mayor total primero) A (total 4) va completo antes
      // que B (total 2).
      for (var i = 0; i < 3; i++) {
        await makeOrderWithItem('A-plano-$i',
            productName: productA,
            createdAt: now.add(Duration(minutes: i)));
      }
      for (var i = 0; i < 2; i++) {
        await makeOrderWithItem('B-$i',
            productName: productB,
            createdAt: now.add(Duration(minutes: 10 + i)));
      }
      await makeOrderWithItem('A-sinaz',
          productName: productA,
          modifiersJson: '[{"name":"Sin azúcar","included":false}]',
          createdAt: now.add(const Duration(minutes: 20)));

      await pumpKds(tester);
      await press(tester, KdsButton.tiempo);

      final ySinAzucar = tester.getTopLeft(find.text('↳ Sin azúcar')).dy;
      final yProductoB = tester.getTopLeft(find.text(productB)).dy;

      expect(ySinAzucar, lessThan(yProductoB),
          reason: 'las dos variantes de "$productA" deben quedar juntas — '
              '"$productB" no debe aparecer entre ellas');
    });
  });
}
