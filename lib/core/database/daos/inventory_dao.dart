import 'package:drift/drift.dart';
import '../database.dart';

part 'inventory_dao.g.dart';

@DriftAccessor(tables: [InventoryMovements, Products])
class InventoryDao extends DatabaseAccessor<AppDatabase>
    with _$InventoryDaoMixin {
  InventoryDao(super.db);

  Future<List<Product>> getTrackedProducts() =>
      (select(products)..where((p) => p.trackInventory.equals(true))).get();

  Future<void> adjustStock(
      int productId, int newQuantity, String reason, String? note) async {
    final product = await (select(products)
          ..where((p) => p.id.equals(productId)))
        .getSingleOrNull();
    if (product == null) return;

    final delta = newQuantity - product.stockQuantity;
    await into(inventoryMovements).insert(
      InventoryMovementsCompanion.insert(
        productId: productId,
        delta: delta,
        reason: reason,
        note: Value(note),
      ),
    );
    await (update(products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(stockQuantity: Value(newQuantity)),
    );
  }

  Future<void> decrementStock(int productId, int qty) async {
    final product = await (select(products)
          ..where((p) => p.id.equals(productId)))
        .getSingleOrNull();
    if (product == null || !product.trackInventory) return;
    final newQty = (product.stockQuantity - qty).clamp(0, 999999);
    await into(inventoryMovements).insert(
      InventoryMovementsCompanion.insert(
        productId: productId,
        delta: -qty,
        reason: 'venta',
      ),
    );
    await (update(products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(stockQuantity: Value(newQty)),
    );
  }

  /// Adds [qty] units back to stock — e.g. when an order is cancelled and the
  /// reserved stock must be returned. Only affects products that track
  /// inventory, mirroring [decrementStock]. Logged as an inventory movement.
  Future<void> incrementStock(int productId, int qty, String reason) async {
    final product = await (select(products)
          ..where((p) => p.id.equals(productId)))
        .getSingleOrNull();
    if (product == null || !product.trackInventory) return;
    final newQty = product.stockQuantity + qty;
    await into(inventoryMovements).insert(
      InventoryMovementsCompanion.insert(
        productId: productId,
        delta: qty,
        reason: reason,
      ),
    );
    await (update(products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(stockQuantity: Value(newQty)),
    );
  }

  Future<List<InventoryMovement>> getMovementsForProduct(int productId) =>
      (select(inventoryMovements)
            ..where((m) => m.productId.equals(productId))
            ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
          .get();
}
