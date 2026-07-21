import 'package:drift/drift.dart';
import '../database.dart';

part 'products_dao.g.dart';

@DriftAccessor(tables: [Products])
class ProductsDao extends DatabaseAccessor<AppDatabase>
    with _$ProductsDaoMixin {
  ProductsDao(super.db);

  Future<List<Product>> getAllProducts() => select(products).get();

  Future<Product?> getProductById(int id) =>
      (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<List<Product>> getAvailableProducts() =>
      (select(products)..where((p) => p.available.equals(true))).get();

  Stream<List<Product>> watchAvailableProducts() =>
      (select(products)..where((p) => p.available.equals(true))).watch();

  Future<List<Product>> getProductsByCategory(int categoryId) =>
      (select(products)
            ..where((p) =>
                p.categoryId.equals(categoryId) & p.available.equals(true)))
          .get();

  Future<List<Product>> searchProducts(String query) => (select(products)
        ..where((p) =>
            p.name.lower().contains(query.toLowerCase()) &
            p.available.equals(true)))
      .get();

  Future<int> insertProduct(ProductsCompanion product) =>
      into(products).insert(product);

  Future<bool> updateProduct(ProductsCompanion product) =>
      update(products).replace(product);

  Future<void> toggleAvailability(int id, bool available) =>
      (update(products)..where((p) => p.id.equals(id)))
          .write(ProductsCompanion(available: Value(available)));

  /// Toggle rápido de "Rastrear inventario" (el caller garantiza que el
  /// producto no use receta — ver `usesRecipe`). docs/inventario.md.
  Future<void> toggleTrackInventory(int id, bool trackInventory) =>
      (update(products)..where((p) => p.id.equals(id)))
          .write(ProductsCompanion(trackInventory: Value(trackInventory)));

  Future<void> updateStock(int id, int quantity) =>
      (update(products)..where((p) => p.id.equals(id)))
          .write(ProductsCompanion(stockQuantity: Value(quantity)));

  Future<int> deleteProduct(int id) =>
      (delete(products)..where((p) => p.id.equals(id))).go();

  Future<List<Product>> getLowStockProducts(int minStock) => (select(products)
        ..where((p) =>
            p.trackInventory.equals(true) &
            p.stockQuantity.isSmallerOrEqualValue(minStock)))
      .get();
}
