import 'package:drift/drift.dart';
import '../database.dart';
import '../../models/order_with_items.dart';

part 'orders_dao.g.dart';

@DriftAccessor(tables: [Orders, OrderItems, Payments, TablesLayout])
class OrdersDao extends DatabaseAccessor<AppDatabase> with _$OrdersDaoMixin {
  OrdersDao(super.db);

  Future<List<Order>> getActiveOrders() => (select(orders)
        ..where((o) =>
            o.status.isNotIn(['entregado', 'cancelado']) & o.deletedAt.isNull())
        ..orderBy([(o) => OrderingTerm.asc(o.createdAt)]))
      .get();

  /// Como [getActiveOrders] pero con los items cargados en un solo JOIN (evita
  /// el N+1 del polling de 2 s de `OrdersNotifier.loadActiveOrders`).
  Future<List<OrderWithItems>> getActiveOrdersWithItems() async {
    final query = select(orders).join([
      leftOuterJoin(orderItems, orderItems.orderId.equalsExp(orders.id)),
    ])
      ..where(orders.status.isNotIn(['entregado', 'cancelado']) &
          orders.deletedAt.isNull())
      ..orderBy([OrderingTerm.asc(orders.createdAt)]);

    final rows = await query.get();

    final byOrderId = <int, Order>{};
    final itemsByOrderId = <int, List<OrderItem>>{};
    final order = <int>[]; // preserves the createdAt ordering from the query

    for (final row in rows) {
      final o = row.readTable(orders);
      final item = row.readTableOrNull(orderItems);
      if (!byOrderId.containsKey(o.id)) {
        byOrderId[o.id] = o;
        itemsByOrderId[o.id] = [];
        order.add(o.id);
      }
      if (item != null) {
        itemsByOrderId[o.id]!.add(item);
      }
    }

    return order
        .map((id) => OrderWithItems(
              order: byOrderId[id]!,
              items: itemsByOrderId[id]!,
            ))
        .toList();
  }

  Stream<List<Order>> watchActiveOrders() => (select(orders)
        ..where((o) =>
            o.status.isNotIn(['entregado', 'cancelado']) & o.deletedAt.isNull())
        ..orderBy([(o) => OrderingTerm.asc(o.createdAt)]))
      .watch();

  Future<int> insertOrder(OrdersCompanion order) => into(orders).insert(order);

  Future<void> updateOrderStatus(int orderId, String status) =>
      (update(orders)..where((o) => o.id.equals(orderId))).write(
        OrdersCompanion(
          status: Value(status),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> updateOrderPaymentStatus(int orderId, String paymentStatus) =>
      (update(orders)..where((o) => o.id.equals(orderId))).write(
        OrdersCompanion(
          paymentStatus: Value(paymentStatus),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Marca la orden como entregada (único lugar que sella [completedAt]).
  /// `docs/ordenes-y-cocina.md` §"Marcar listo".
  Future<void> markDelivered(int orderId) =>
      (update(orders)..where((o) => o.id.equals(orderId))).write(
        OrdersCompanion(
          status: const Value('entregado'),
          updatedAt: Value(DateTime.now()),
          completedAt: Value(DateTime.now()),
        ),
      );

  /// Regresa la orden a un [status] activo y limpia [completedAt] (recall del
  /// KDS). `docs/ordenes-y-cocina.md` §Recall.
  Future<void> recallOrder(int orderId, String status) =>
      (update(orders)..where((o) => o.id.equals(orderId))).write(
        OrdersCompanion(
          status: Value(status),
          completedAt: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> cancelOrder(int orderId, String reason) =>
      (update(orders)..where((o) => o.id.equals(orderId))).write(
        OrdersCompanion(
          status: const Value('cancelado'),
          paymentStatus: const Value('cancelado'),
          cancelReason: Value(reason),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Soft delete: oculta la orden de listas, reportes y cortes sin borrarla de
  /// la BD (queda para auditoría). Distinto de cancelar, que sí se muestra.
  /// docs/soft-delete.md.
  Future<void> softDeleteOrder(int orderId) =>
      (update(orders)..where((o) => o.id.equals(orderId))).write(
        OrdersCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Liga la orden a un turno. Usado al cobrar una orden diferida (creada con
  /// "Enviar a Cocina" sin turno) para que el corte Z cuente su venta (5.5).
  Future<void> updateOrderShift(int orderId, int? shiftId) =>
      (update(orders)..where((o) => o.id.equals(orderId))).write(
        OrdersCompanion(shiftId: Value(shiftId)),
      );

  /// Reescribe los montos de la orden — usado al anular una línea de una orden
  /// aún no pagada (4.3), que reduce lo que se cobrará.
  Future<void> updateOrderTotals(
    int orderId, {
    required double subtotal,
    required double discountAmount,
    required double taxAmount,
    required double total,
  }) =>
      (update(orders)..where((o) => o.id.equals(orderId))).write(
        OrdersCompanion(
          subtotal: Value(subtotal),
          discountAmount: Value(discountAmount),
          taxAmount: Value(taxAmount),
          total: Value(total),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<List<Order>> getOrdersByDateRange(DateTime from, DateTime to) =>
      (select(orders)
            ..where((o) =>
                o.createdAt.isBetweenValues(from, to) & o.deletedAt.isNull())
            ..orderBy([(o) => OrderingTerm.desc(o.createdAt)]))
          .get();

  Future<Order?> getOrderById(int id) =>
      (select(orders)..where((o) => o.id.equals(id))).getSingleOrNull();

  Future<List<Order>> getOrdersByShift(int shiftId) => (select(orders)
        ..where((o) => o.shiftId.equals(shiftId) & o.deletedAt.isNull()))
      .get();

  /// Fija el número legible de la orden (derivado del id tras insertar).
  /// `docs/ordenes-y-cocina.md` §"Número de orden".
  Future<void> updateOrderNumber(int orderId, String orderNumber) =>
      (update(orders)..where((o) => o.id.equals(orderId)))
          .write(OrdersCompanion(orderNumber: Value(orderNumber)));

  Future<List<Order>> getTodayOrders() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getOrdersByDateRange(startOfDay, endOfDay);
  }
}
