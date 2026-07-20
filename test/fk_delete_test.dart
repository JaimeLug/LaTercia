import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';

/// Auditoría 2026-07-17 — con `foreign_keys=ON` (desde v6), borrar una
/// categoría con productos o un producto con ventas/receta lanza
/// `SqliteException` (violación de FK) en vez de dejar filas huérfanas. Las
/// pantallas de Admin ahora capturan exactamente este tipo — este test
/// confirma que es el tipo real que la BD lanza, no una suposición.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  test('borrar una categoría con productos lanza SqliteException (FK)',
      () async {
    final cats = await db.categoriesDao.getAllCategories();
    final catId = cats.first.id;
    await db.productsDao.insertProduct(
      ProductsCompanion.insert(name: 'Latte', price: 45, categoryId: catId),
    );

    expect(
      () => db.categoriesDao.deleteCategory(catId),
      throwsA(isA<SqliteException>()),
    );
  });

  test('borrar una categoría sin productos funciona normal', () async {
    final catId = await db.categoriesDao.insertCategory(
      CategoriesCompanion.insert(
          name: 'Vacía', color: '#000000', icon: 'restaurant'),
    );

    await db.categoriesDao.deleteCategory(catId);

    final remaining = await db.categoriesDao.getAllCategories();
    expect(remaining.any((c) => c.id == catId), isFalse);
  });

  test('borrar un producto con órdenes asociadas lanza SqliteException (FK)',
      () async {
    final cats = await db.categoriesDao.getAllCategories();
    final productId = await db.productsDao.insertProduct(
      ProductsCompanion.insert(
          name: 'Latte', price: 45, categoryId: cats.first.id),
    );
    final orderId = await db.ordersDao.insertOrder(
      OrdersCompanion.insert(orderNumber: '#0001', type: 'mesa', employeeId: 1),
    );
    await db.orderItemsDao.insertOrderItems([
      OrderItemsCompanion.insert(
        orderId: orderId,
        productId: productId,
        productName: 'Latte',
        quantity: 1,
        unitPrice: 45,
      ),
    ]);

    expect(
      () => db.productsDao.deleteProduct(productId),
      throwsA(isA<SqliteException>()),
    );
  });

  test(
      'borrar un producto con receta (sin órdenes) también lanza '
      'SqliteException (FK)', () async {
    final cats = await db.categoriesDao.getAllCategories();
    final productId = await db.productsDao.insertProduct(
      ProductsCompanion.insert(
          name: 'Latte', price: 45, categoryId: cats.first.id),
    );
    final ingredientId = await db.ingredientsDao.insertIngredient(
      IngredientsCompanion.insert(name: 'Café', unit: 'g'),
    );
    await db.customStatement(
        'INSERT INTO recipe_items (product_id, ingredient_id, quantity) '
        'VALUES (?, ?, ?)',
        [productId, ingredientId, 18]);

    expect(
      () => db.productsDao.deleteProduct(productId),
      throwsA(isA<SqliteException>()),
    );
  });

  test('borrar un producto sin referencias funciona normal', () async {
    final cats = await db.categoriesDao.getAllCategories();
    final productId = await db.productsDao.insertProduct(
      ProductsCompanion.insert(
          name: 'Producto suelto', price: 20, categoryId: cats.first.id),
    );

    await db.productsDao.deleteProduct(productId);

    final remaining = await db.productsDao.getAllProducts();
    expect(remaining.any((p) => p.id == productId), isFalse);
  });
}
