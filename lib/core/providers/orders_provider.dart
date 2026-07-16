import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../models/order_with_items.dart';
import '../services/audit_service.dart';
import '../services/kds_client.dart';
import '../utils/formatters.dart';
import 'database_provider.dart';

class OrdersNotifier extends StateNotifier<List<OrderWithItems>> {
  /// [kdsClient] solo se pasa en el proceso de la ventana KDS separada (5.1):
  /// mientras esté conectado, el estado lo dictan los snapshots del servidor y
  /// los comandos (listo/recall/estado) viajan por WS al POS —dueño de la BD—
  /// en vez de escribir la BD aquí. Si cae la conexión, se vuelve al polling.
  OrdersNotifier(this._db, {KdsClient? kdsClient})
      : _kdsClient = kdsClient,
        super([]) {
    final client = _kdsClient;
    if (client != null) {
      client.onSnapshot = (orders, canRecall) {
        _remoteCanRecall = canRecall;
        if (mounted) state = orders;
      };
      client.onConnectionChanged = (connected) {
        // Al reconectar, el servidor manda snapshot; al desconectar, retomamos
        // la lectura de BD (fallback) de inmediato.
        if (!connected) loadActiveOrders();
      };
      client.start();
    }
    loadActiveOrders();
    // Poll the database so the POS and KDS (separate processes sharing the
    // same SQLite file) stay in sync — Drift streams only fire for writes
    // made by the same process. En modo cliente WS conectado, loadActiveOrders
    // hace no-op (el estado lo empuja el servidor).
    _pollTimer = Timer.periodic(
        const Duration(seconds: 2), (_) => loadActiveOrders());
  }

  final AppDatabase _db;
  final KdsClient? _kdsClient;
  late final AuditService _auditService = AuditService(_db);
  Timer? _pollTimer;

  /// canRecall reportado por el servidor cuando estamos en modo cliente WS.
  bool _remoteCanRecall = false;

  bool get _wsConnected => _kdsClient?.isConnected == true;

  /// How long after marking an order "listo" the kitchen can still undo it.
  static const recallWindow = Duration(seconds: 60);

  /// The last order marked ready from this process's KDS, kept in memory so it
  /// can be recalled (undone) within [recallWindow]. Local to the process that
  /// did the marking — only that KDS can recall its own action.
  _RecallInfo? _lastReady;

  /// Whether there is a still-recallable "listo" action (within the window).
  bool get canRecall {
    if (_wsConnected) return _remoteCanRecall;
    final r = _lastReady;
    return r != null && DateTime.now().difference(r.at) <= recallWindow;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _kdsClient?.stop();
    super.dispose();
  }

  Future<void> loadActiveOrders() async {
    // En modo cliente WS conectado, el estado lo empuja el servidor: no leemos
    // la BD (evita polling y clobber del snapshot remoto).
    if (_wsConnected) return;
    final result = await _db.ordersDao.getActiveOrdersWithItems();
    if (!mounted) return;
    state = result;
  }

  Future<int> sendToKitchen({
    required List<CartItem> cartItems,
    required String type,
    required int employeeId,
    int? tableId,
    String? customerName,
    int? customerId,
    String? note,
    double subtotal = 0,
    double discountAmount = 0,
    double taxAmount = 0,
    double total = 0,
  }) async {
    // The whole operation (order + items + inventory) must be all-or-nothing:
    // a failure halfway through used to leave orders without items, or stock
    // decremented for an order that was never created.
    final orderId = await _db.transaction(() async {
      // Insert with a temporary unique placeholder, then derive the real,
      // human-readable order number from the autoincrement id. SQLite
      // guarantees that id is unique, which avoids the previous max(id)+1
      // race that could produce duplicate order numbers under concurrency
      // (POS + KDS share the same database file).
      final tempNumber = 'tmp-${const Uuid().v4()}';
      final id = await _db.ordersDao.insertOrder(
        OrdersCompanion.insert(
          orderNumber: tempNumber,
          type: type,
          employeeId: employeeId,
          tableId: Value(tableId),
          customerName: Value(customerName),
          customerId: Value(customerId),
          note: Value(note),
          subtotal: Value(subtotal),
          discountAmount: Value(discountAmount),
          taxAmount: Value(taxAmount),
          total: Value(total),
          status: const Value('pendiente'),
          paymentStatus: const Value('pendiente'),
        ),
      );
      await _db.ordersDao.updateOrderNumber(id, formatOrderNumber(id));

      // Mark table as occupied
      if (tableId != null) {
        await _db.tablesDao.updateTableStatus(tableId, 'occupied');
      }

      // Insert order items
      final itemCompanions = cartItems.map((ci) {
        final modJson = jsonEncode(
          ci.modifiers
              .map((m) => {'name': m.name, 'priceDelta': m.priceDelta})
              .toList(),
        );
        return OrderItemsCompanion.insert(
          orderId: id,
          productId: ci.product.id,
          productName: ci.product.name,
          quantity: ci.quantity,
          unitPrice: ci.unitPrice,
          modifiersJson: Value(ci.modifiers.isEmpty ? null : modJson),
          itemNote: Value(ci.note),
        );
      }).toList();

      await _db.orderItemsDao.insertOrderItems(itemCompanions);

      // Decrement inventory
      for (final ci in cartItems) {
        await _db.inventoryDao.decrementStock(ci.product.id, ci.quantity);
      }

      return id;
    });

    await loadActiveOrders();
    return orderId;
  }

  Future<void> updateStatus(int orderId, String status) async {
    if (_wsConnected) {
      _kdsClient!.send('updateStatus', orderId: orderId, status: status);
      return;
    }
    await _db.ordersDao.updateOrderStatus(orderId, status);
    await loadActiveOrders();
  }

  /// Called from the KDS when the kitchen finishes an order.
  ///
  /// An order is fully done (delivered) only when it is both ready AND paid.
  /// If the order is already paid, finishing it in the kitchen completes it
  /// and frees its table; otherwise it stays at 'listo' so the cashier can
  /// still charge it (pay-at-the-end / mesa flow).
  Future<void> markReady(int orderId) async {
    if (_wsConnected) {
      _kdsClient!.send('markReady', orderId: orderId);
      return;
    }
    final order = await _db.ordersDao.getOrderById(orderId);
    if (order == null) return;

    final wasDelivered = order.paymentStatus == 'pagado';
    if (wasDelivered) {
      await _db.ordersDao.markDelivered(orderId);
      if (order.tableId != null) {
        await _db.tablesDao.updateTableStatus(order.tableId!, 'available');
      }
    } else {
      await _db.ordersDao.updateOrderStatus(orderId, 'listo');
    }

    // Remember this so the kitchen can undo it within [recallWindow]. Store the
    // status it had *before* being marked ready so recall restores it exactly.
    _lastReady = _RecallInfo(
      orderId: orderId,
      previousStatus: order.status,
      wasDelivered: wasDelivered,
      tableId: order.tableId,
      at: DateTime.now(),
    );

    await loadActiveOrders();
  }

  /// Undoes the most recent [markReady] if it happened within [recallWindow].
  ///
  /// Reverts the order to the active status it had before, clearing the
  /// completion timestamp, and — if marking it ready had delivered it and
  /// freed a table — re-occupies that table. Returns true if something was
  /// actually recalled.
  Future<bool> recallLastReady() async {
    if (_wsConnected) {
      _kdsClient!.send('recall');
      return true;
    }
    final r = _lastReady;
    if (r == null || DateTime.now().difference(r.at) > recallWindow) {
      return false;
    }

    await _db.ordersDao.recallOrder(r.orderId, r.previousStatus);
    if (r.wasDelivered && r.tableId != null) {
      await _db.tablesDao.updateTableStatus(r.tableId!, 'occupied');
    }
    _lastReady = null;
    await loadActiveOrders();
    return true;
  }

  /// Records that an order has been paid.
  ///
  /// Paying no longer forces the order to 'entregado' — that would hide it
  /// from the kitchen (KDS) when the cashier charges before the food is made.
  /// The order is only delivered here if the kitchen has already finished it
  /// (status == 'listo'); otherwise it stays visible on the KDS until the
  /// kitchen marks it ready (see [markReady]).
  Future<void> markPaid(int orderId, int? tableId) async {
    await _db.ordersDao.updateOrderPaymentStatus(orderId, 'pagado');

    final order = await _db.ordersDao.getOrderById(orderId);
    if (order != null && order.status == 'listo') {
      await _db.ordersDao.markDelivered(orderId);
      if (tableId != null) {
        await _db.tablesDao.updateTableStatus(tableId, 'available');
      }
    }
    await loadActiveOrders();
  }

  Future<void> cancelOrder(int orderId, String reason, int? tableId,
      {int? employeeId}) async {
    final order = await _db.ordersDao.getOrderById(orderId);
    if (order == null || order.status == 'cancelado') return;

    // Return the reserved stock for every tracked item back to inventory.
    // Stock was decremented when the order was sent to the kitchen, so a
    // cancellation must put it back or inventory drifts permanently.
    final items = await _db.orderItemsDao.getItemsForOrder(orderId);
    for (final item in items) {
      await _db.inventoryDao
          .incrementStock(item.productId, item.quantity, 'cancelacion');
    }

    await _db.ordersDao.cancelOrder(orderId, reason);
    if (tableId != null) {
      await _db.tablesDao.updateTableStatus(tableId, 'available');
    }
    await _auditService.log(
      employeeId: employeeId,
      action: 'anular',
      entity: 'order',
      entityId: orderId,
      detail: {'reason': reason},
    );
    await loadActiveOrders();
  }

  /// Anula UNA línea de una orden aún NO pagada (4.3): marca el item como
  /// cancelado, devuelve su stock y reduce los montos de la orden. El cobro
  /// posterior será por lo restante. (Anular una línea ya pagada es un
  /// reembolso — ver 4.4 — no esto.)
  ///
  /// Los montos se reescalan proporcionalmente al subtotal restante: exacto
  /// para descuentos porcentuales e impuestos (ambos lineales en el subtotal);
  /// aproximado si hubo un descuento fijo, caso poco común en una cafetería.
  Future<void> voidOrderItem({
    required int orderId,
    required OrderItem item,
    required String reason,
    int? employeeId,
  }) async {
    await _db.transaction(() async {
      final order = await _db.ordersDao.getOrderById(orderId);
      if (order == null || order.status == 'cancelado') return;
      if (order.paymentStatus == 'pagado') {
        throw StateError(
            'La orden ya está pagada; una línea pagada se devuelve con un reembolso.');
      }
      if (item.itemStatus == 'cancelado') return;

      // Devuelve el stock reservado de esta línea.
      await _db.inventoryDao
          .incrementStock(item.productId, item.quantity, 'cancelacion');
      await _db.orderItemsDao.updateItemStatus(item.id, 'cancelado');

      // Recalcula el subtotal desde las líneas que siguen activas y reescala el
      // resto de montos proporcionalmente.
      final items = await _db.orderItemsDao.getItemsForOrder(orderId);
      final newSubtotal = items
          .where((i) => i.id != item.id && i.itemStatus != 'cancelado')
          .fold(0.0, (a, i) => a + i.unitPrice * i.quantity);
      final scale = order.subtotal > 0 ? newSubtotal / order.subtotal : 0.0;
      await _db.ordersDao.updateOrderTotals(
        orderId,
        subtotal: newSubtotal,
        discountAmount: order.discountAmount * scale,
        taxAmount: order.taxAmount * scale,
        total: order.total * scale,
      );

      await _auditService.log(
        employeeId: employeeId,
        action: 'anular_linea',
        entity: 'order_item',
        entityId: item.id,
        detail: {
          'orderId': orderId,
          'product': item.productName,
          'qty': item.quantity,
          'reason': reason,
        },
      );
    });
    await loadActiveOrders();
  }

}

/// In-memory snapshot of the last "listo" action, enough to undo it.
class _RecallInfo {
  final int orderId;
  final String previousStatus;
  final bool wasDelivered;
  final int? tableId;
  final DateTime at;

  const _RecallInfo({
    required this.orderId,
    required this.previousStatus,
    required this.wasDelivered,
    required this.tableId,
    required this.at,
  });
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, List<OrderWithItems>>((ref) {
  final db = ref.watch(databaseProvider);
  return OrdersNotifier(db);
});
