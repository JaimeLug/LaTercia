import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/database/daos/recipes_dao.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<int> newIngredient({String name = 'Café molido', String unit = 'g'}) =>
      db.ingredientsDao.insertIngredient(
        IngredientsCompanion.insert(name: name, unit: unit),
      );

  Future<Product> newProduct({bool usesRecipe = false, bool trackInventory = false}) async {
    final cats = await db.categoriesDao.getAllCategories();
    final id = await db.productsDao.insertProduct(
      ProductsCompanion.insert(
        name: 'Latte',
        price: 45,
        categoryId: cats.first.id,
        usesRecipe: Value(usesRecipe),
        trackInventory: Value(trackInventory),
        stockQuantity: const Value(10),
      ),
    );
    return (await db.productsDao.getAllProducts()).firstWhere((p) => p.id == id);
  }

  group('IngredientsDao — CRUD', () {
    test('insertar, listar, actualizar y desactivar', () async {
      final id = await newIngredient(name: 'Leche', unit: 'ml');

      var all = await db.ingredientsDao.getAllIngredients();
      expect(all, hasLength(1));
      expect(all.first.name, 'Leche');
      expect(all.first.active, isTrue);

      await db.ingredientsDao.updateIngredient(
        IngredientsCompanion(id: Value(id), name: const Value('Leche entera')),
      );
      all = await db.ingredientsDao.getAllIngredients();
      expect(all.first.name, 'Leche entera');

      await db.ingredientsDao.setActive(id, false);
      expect(await db.ingredientsDao.getActiveIngredients(), isEmpty);
      expect(await db.ingredientsDao.getAllIngredients(), hasLength(1),
          reason: 'soft delete — la fila sigue existiendo');
    });

    test('adjustStock fija el valor absoluto y registra el movimiento',
        () async {
      final id = await newIngredient();
      await db.ingredientsDao.adjustStock(id, 500, 'ajuste', 'conteo inicial');

      final ingredient =
          (await db.ingredientsDao.getAllIngredients()).firstWhere((i) => i.id == id);
      expect(ingredient.stockQuantity, 500);

      final movements = await db.ingredientsDao.getMovementsForIngredient(id);
      expect(movements, hasLength(1));
      expect(movements.first.delta, 500);
      expect(movements.first.reason, 'ajuste');
    });

    test('getLowStock solo devuelve insumos activos bajo el mínimo', () async {
      final lowId = await newIngredient(name: 'Vasos', unit: 'pza');
      await db.ingredientsDao.adjustStock(lowId, 2, 'ajuste', null);
      await db.ingredientsDao.updateIngredient(
        IngredientsCompanion(id: Value(lowId), minStock: const Value(5)),
      );
      final okId = await newIngredient(name: 'Servilletas', unit: 'pza');
      await db.ingredientsDao.adjustStock(okId, 200, 'ajuste', null);

      final low = await db.ingredientsDao.getLowStock();
      expect(low.map((i) => i.id), [lowId]);
    });
  });

  group('InventoryDao.decrementForSale / incrementForSale (7 — insumos)', () {
    test('producto sin receta cae al stock simple de siempre', () async {
      final product = await newProduct(trackInventory: true);
      await db.settingsDao.setValue('insumos_activo', 'true');

      await db.inventoryDao.decrementForSale(product.id, 2);

      final updated =
          (await db.productsDao.getAllProducts()).firstWhere((p) => p.id == product.id);
      expect(updated.stockQuantity, 8);
    });

    test('con el flag apagado, un producto con receta NO toca insumos',
        () async {
      final ingredientId = await newIngredient();
      final product = await newProduct(usesRecipe: true);
      await db.recipesDao.setRecipe(
        product.id, [RecipeLineDraft(ingredientId: ingredientId, quantity: 18)]);
      await db.settingsDao.setValue('insumos_activo', 'false');

      await db.inventoryDao.decrementForSale(product.id, 2);

      final ingredient =
          (await db.ingredientsDao.getAllIngredients()).firstWhere((i) => i.id == ingredientId);
      expect(ingredient.stockQuantity, 0, reason: 'insumos apagado — no se toca nada');
    });

    test('con el flag activo, un producto con receta descuenta insumos por '
        'cantidad vendida', () async {
      final ingredientId = await newIngredient(name: 'Café molido', unit: 'g');
      await db.ingredientsDao.adjustStock(ingredientId, 1000, 'ajuste', null);
      final product = await newProduct(usesRecipe: true);
      await db.recipesDao.setRecipe(
        product.id, [RecipeLineDraft(ingredientId: ingredientId, quantity: 18)]);
      await db.settingsDao.setValue('insumos_activo', 'true');
      final orderId = await db.ordersDao.insertOrder(
        OrdersCompanion.insert(orderNumber: '#0001', type: 'mesa', employeeId: 1),
      );

      await db.inventoryDao.decrementForSale(product.id, 2, orderId: orderId);

      final ingredient =
          (await db.ingredientsDao.getAllIngredients()).firstWhere((i) => i.id == ingredientId);
      expect(ingredient.stockQuantity, 1000 - 18 * 2);

      final movements = await db.ingredientsDao.getMovementsForIngredient(ingredientId);
      final sale = movements.firstWhere((m) => m.reason == 'venta');
      expect(sale.delta, -36);
      expect(sale.orderId, orderId);
    });

    test('incrementForSale devuelve insumos (cancelación/reembolso)', () async {
      final ingredientId = await newIngredient(name: 'Leche', unit: 'ml');
      await db.ingredientsDao.adjustStock(ingredientId, 1000, 'ajuste', null);
      final product = await newProduct(usesRecipe: true);
      await db.recipesDao.setRecipe(
        product.id, [RecipeLineDraft(ingredientId: ingredientId, quantity: 200)]);
      await db.settingsDao.setValue('insumos_activo', 'true');

      await db.inventoryDao.decrementForSale(product.id, 1);
      await db.inventoryDao.incrementForSale(product.id, 1, 'cancelacion');

      final ingredient =
          (await db.ingredientsDao.getAllIngredients()).firstWhere((i) => i.id == ingredientId);
      expect(ingredient.stockQuantity, 1000, reason: 'venta + cancelación se cancelan');
    });
  });
}
