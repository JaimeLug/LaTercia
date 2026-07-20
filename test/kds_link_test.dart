import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/services/kds_button_service.dart';
import 'package:latercia/core/services/kds_link.dart';
import 'package:latercia/core/services/kds_server.dart';

void main() {
  group('serialización del enlace KDS (5.1)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });
    tearDown(() => db.close());

    test('round-trip de pedidos: encode → decode preserva orden e items',
        () async {
      final cats = await db.categoriesDao.getAllCategories();
      final pid = await db.productsDao.insertProduct(
        ProductsCompanion.insert(
            name: 'Latte', price: 45, categoryId: cats.first.id),
      );
      final oid = await db.ordersDao.insertOrder(
        OrdersCompanion.insert(
            orderNumber: 'A-1',
            type: 'mesa',
            employeeId: 1,
            total: const Value(90)),
      );
      await db.orderItemsDao.insertOrderItems([
        OrderItemsCompanion.insert(
            orderId: oid,
            productId: pid,
            productName: 'Latte',
            quantity: 2,
            unitPrice: 45),
      ]);
      final order = (await db.ordersDao.getActiveOrdersWithItems())
          .firstWhere((o) => o.order.id == oid);

      final encoded = encodeOrdersMessage([order], true);
      final decoded = decodeOrders(jsonDecode(encoded) as Map<String, dynamic>);

      expect(decoded, hasLength(1));
      expect(decoded.first.order.orderNumber, 'A-1');
      expect(decoded.first.order.total, 90);
      expect(decoded.first.items, hasLength(1));
      expect(decoded.first.items.first.productName, 'Latte');
      expect(decoded.first.items.first.quantity, 2);
    });

    test('encodeCommand incluye cmd/orderId/status', () {
      final m = jsonDecode(
          encodeCommand('updateStatus', orderId: 7, status: 'en_preparacion'));
      expect(m['type'], 'cmd');
      expect(m['cmd'], 'updateStatus');
      expect(m['orderId'], 7);
      expect(m['status'], 'en_preparacion');
    });
  });

  group('servidor KDS WS (5.1)', () {
    late KdsServer server;

    setUp(() async {
      server = KdsServer();
      await server.start(); // el endpoint file falla sin path_provider (ok)
    });
    tearDown(() => server.stop());

    Future<WebSocket> connect() => WebSocket.connect(
        'ws://127.0.0.1:${server.port}$kdsWsPath?token=${server.token}');

    test('rechaza conexiones sin el token correcto', () async {
      await expectLater(
        WebSocket.connect('ws://127.0.0.1:${server.port}$kdsWsPath?token=malo'),
        throwsA(isA<WebSocketException>()),
      );
    });

    test('un cliente recibe el snapshot empujado con broadcast', () async {
      final ws = await connect();
      final firstMsg = ws.first; // primer mensaje que llegue
      // Da un instante a que el server registre el cliente antes de emitir.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      server.broadcast(const [], true);

      final raw = await firstMsg.timeout(const Duration(seconds: 2));
      final m = jsonDecode(raw as String) as Map<String, dynamic>;
      expect(m['type'], 'orders');
      expect(m['canRecall'], true);
      await ws.close();
    });

    test('un comando del cliente dispara el callback del servidor', () async {
      int? readied;
      server.onMarkReady = (id) async => readied = id;

      final ws = await connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      ws.add(encodeCommand('markReady', orderId: 42));

      // Espera a que el server procese el mensaje.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(readied, 42);
      await ws.close();
    });

    test(
        'broadcastBoton reenvía el botón a las ventanas KDS separadas '
        '(3.5 — el ESP32 solo puede hablarle al proceso POS)', () async {
      final ws = await connect();
      final firstMsg = ws.first;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      server.broadcastBoton(KdsButton.listo);

      final raw = await firstMsg.timeout(const Duration(seconds: 2));
      final m = jsonDecode(raw as String) as Map<String, dynamic>;
      expect(m['type'], 'boton');
      expect(m['boton'], 'LISTO');
      await ws.close();
    });
  });
}
