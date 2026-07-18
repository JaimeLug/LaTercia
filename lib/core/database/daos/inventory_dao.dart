import 'package:drift/drift.dart';
import '../database.dart';

part 'inventory_dao.g.dart';

@DriftAccessor(
    tables: [InventoryMovements, Products, Ingredients, IngredientMovements, RecipeItems])
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

  /// FASE 7 — Punto único de descuento al vender: decide entre receta
  /// (insumos) y stock simple, para que los call sites de venta (checkout,
  /// enviar a cocina) no dupliquen esa decisión. Si el sistema de insumos
  /// está apagado o el producto no tiene receta, cae al [decrementStock] de
  /// siempre.
  Future<void> decrementForSale(int productId, int qty, {int? orderId}) async {
    if (await _shouldUseRecipe(productId)) {
      await _adjustRecipeStock(productId, -qty, 'venta', orderId: orderId);
      return;
    }
    await decrementStock(productId, qty);
  }

  /// Espejo de [decrementForSale] para cancelaciones/anulaciones/reembolsos.
  Future<void> incrementForSale(int productId, int qty, String reason,
      {int? orderId}) async {
    if (await _shouldUseRecipe(productId)) {
      await _adjustRecipeStock(productId, qty, reason, orderId: orderId);
      return;
    }
    await incrementStock(productId, qty, reason);
  }

  Future<bool> _shouldUseRecipe(int productId) async {
    final product =
        await (select(products)..where((p) => p.id.equals(productId)))
            .getSingleOrNull();
    if (product == null || !product.usesRecipe) return false;
    final flag = await attachedDatabase.settingsDao.getValue('insumos_activo');
    return flag == 'true';
  }

  /// [productQtyDelta] es la cantidad de PRODUCTO vendido/devuelto (positivo
  /// = devolver, negativo = vender) — cada línea de receta se multiplica por
  /// esto para saber cuánto insumo mover.
  Future<void> _adjustRecipeStock(
      int productId, int productQtyDelta, String reason,
      {int? orderId}) async {
    final recipe = await (select(recipeItems)
          ..where((r) => r.productId.equals(productId)))
        .get();
    for (final line in recipe) {
      final ingredient = await (select(ingredients)
            ..where((i) => i.id.equals(line.ingredientId)))
          .getSingleOrNull();
      if (ingredient == null) continue;
      final delta = line.quantity * productQtyDelta;
      final newQty =
          (ingredient.stockQuantity + delta).clamp(0, double.infinity).toDouble();
      await (update(ingredients)..where((i) => i.id.equals(line.ingredientId)))
          .write(IngredientsCompanion(stockQuantity: Value(newQty)));
      await into(ingredientMovements).insert(
        IngredientMovementsCompanion.insert(
          ingredientId: line.ingredientId,
          delta: delta,
          reason: reason,
          orderId: Value(orderId),
        ),
      );
    }
  }
}
