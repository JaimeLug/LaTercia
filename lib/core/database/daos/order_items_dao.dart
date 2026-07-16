import 'package:drift/drift.dart';
import '../database.dart';

part 'order_items_dao.g.dart';

@DriftAccessor(tables: [OrderItems])
class OrderItemsDao extends DatabaseAccessor<AppDatabase>
    with _$OrderItemsDaoMixin {
  OrderItemsDao(super.db);

  Future<List<OrderItem>> getItemsForOrder(int orderId) =>
      (select(orderItems)..where((i) => i.orderId.equals(orderId))).get();

  Future<void> insertOrderItems(List<OrderItemsCompanion> items) =>
      batch((b) => b.insertAll(orderItems, items));

  Future<void> updateItemStatus(int itemId, String status) =>
      (update(orderItems)..where((i) => i.id.equals(itemId)))
          .write(OrderItemsCompanion(itemStatus: Value(status)));

  Future<void> deleteItemsByOrder(int orderId) =>
      (delete(orderItems)..where((i) => i.orderId.equals(orderId))).go();
}
