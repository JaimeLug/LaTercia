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

/// Lista de órdenes activas y su ciclo de vida (enviar/listo/recall/cobrar/
/// cancelar), con sync POS↔KDS. `docs/ordenes-y-cocina.md`.
class OrdersNotifier extends StateNotifier<List<OrderWithItems>> {
  /// [kdsClient] solo en la ventana KDS separada: mientras esté conectado, el
  /// estado lo dicta el servidor y los comandos van por WS. `docs/kds-conexion.md`.
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
        // Al desconectar, retomamos el polling de BD de inmediato.
        if (!connected) loadActiveOrders();
      };
      client.start();
    }
    loadActiveOrders();
    // Poll cada 2s para sincronizar POS y KDS (procesos separados; los streams
    // de drift solo disparan para el mismo proceso). docs/ordenes-y-cocina.md.
    _pollTimer =
        Timer.periodic(const Duration(seconds: 2), (_) => loadActiveOrders());
  }

  final AppDatabase _db;
  final KdsClient? _kdsClient;
  late final AuditService _auditService = AuditService(_db);
  Timer? _pollTimer;

  /// canRecall reportado por el servidor cuando estamos en modo cliente WS.
  bool _remoteCanRecall = false;

  bool get _wsConnected => _kdsClient?.isConnected == true;

  /// Ventana para deshacer un "listo". `docs/ordenes-y-cocina.md` §Recall.
  static const recallWindow = Duration(seconds: 60);

  /// Último "listo" de este proceso, en memoria para poder deshacerlo dentro de
  /// [recallWindow]. Local al proceso que lo marcó. `docs/ordenes-y-cocina.md`.
  _RecallInfo? _lastReady;

  /// Si hay un "listo" aún deshacible (dentro de la ventana).
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
    // En modo cliente WS conectado, el estado lo empuja el servidor (no leemos
    // la BD). docs/ordenes-y-cocina.md.
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
    String? customerPhone,
    String? customerAddress,
    String? note,
    double subtotal = 0,
    double discountAmount = 0,
    double taxAmount = 0,
    String? deliveryZone,
    double deliveryFee = 0,
    double total = 0,
    String? deliveryPaymentMethod,
    double? deliveryCashAmount,
  }) async {
    // Orden + items + inventario, all-or-nothing en una transacción.
    // docs/ordenes-y-cocina.md §"Enviar a cocina".
    final orderId = await _db.transaction(() async {
      // Placeholder temporal → número legible derivado del id (evita la carrera
      // max(id)+1). docs/ordenes-y-cocina.md §"Número de orden".
      final tempNumber = 'tmp-${const Uuid().v4()}';
      final id = await _db.ordersDao.insertOrder(
        OrdersCompanion.insert(
          orderNumber: tempNumber,
          type: type,
          employeeId: employeeId,
          tableId: Value(tableId),
          customerName: Value(customerName),
          customerId: Value(customerId),
          customerPhone: Value(customerPhone),
          customerAddress: Value(customerAddress),
          note: Value(note),
          subtotal: Value(subtotal),
          discountAmount: Value(discountAmount),
          taxAmount: Value(taxAmount),
          deliveryZone: Value(deliveryZone),
          deliveryFee: Value(deliveryFee),
          deliveryPaymentMethod: Value(deliveryPaymentMethod),
          deliveryCashAmount: Value(deliveryCashAmount),
          total: Value(total),
          status: const Value('pendiente'),
          paymentStatus: const Value('pendiente'),
        ),
      );
      await _db.ordersDao.updateOrderNumber(id, formatOrderNumber(id));

      // Marca la mesa como ocupada.
      if (tableId != null) {
        await _db.tablesDao.updateTableStatus(tableId, 'occupied');
      }

      // Inserta los items de la orden.
      final itemCompanions = cartItems.map((ci) {
        final modJson = jsonEncode(
          ci.modifiers
              .map((m) => {
                    'name': m.name,
                    'priceDelta': m.priceDelta,
                    'included': ci.includedModifierIds.contains(m.id),
                  })
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
          comboInstanceId: Value(ci.comboInstanceId),
          comboName: Value(ci.comboName),
        );
      }).toList();

      await _db.orderItemsDao.insertOrderItems(itemCompanions);

      // Descuenta inventario.
      for (final ci in cartItems) {
        await _db.inventoryDao
            .decrementForSale(ci.product.id, ci.quantity, orderId: id);
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

  /// La cocina termina una orden. Entregada solo si está lista Y pagada; si no,
  /// se queda en 'listo' para cobrarla. `docs/ordenes-y-cocina.md` §"Marcar listo".
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

    // Guarda el estado previo para poder deshacer dentro de [recallWindow].
    _lastReady = _RecallInfo(
      orderId: orderId,
      previousStatus: order.status,
      wasDelivered: wasDelivered,
      tableId: order.tableId,
      at: DateTime.now(),
    );

    await loadActiveOrders();
  }

  /// Deshace el [markReady] más reciente si fue dentro de [recallWindow].
  /// `docs/ordenes-y-cocina.md` §Recall.
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

  /// Marca una orden como pagada. Pagar no la entrega por sí solo (solo si ya
  /// está 'listo'). `docs/ordenes-y-cocina.md` §Cobrar.
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

    // Devuelve a inventario el stock reservado de cada item (se descontó al
    // enviar a cocina). docs/ordenes-y-cocina.md §"Cancelar orden".
    final items = await _db.orderItemsDao.getItemsForOrder(orderId);
    for (final item in items) {
      await _db.inventoryDao.incrementForSale(
          item.productId, item.quantity, 'cancelacion',
          orderId: orderId);
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

  /// Anula UNA línea de una orden NO pagada: cancela el item, devuelve su stock
  /// y reescala los montos. `docs/ordenes-y-cocina.md` §"Anular una línea".
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
      await _db.inventoryDao.incrementForSale(
          item.productId, item.quantity, 'cancelacion',
          orderId: orderId);
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

/// Snapshot en memoria del último "listo", suficiente para deshacerlo.
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
