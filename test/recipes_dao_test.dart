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

  Future<int> newIngredient(String name) => db.ingredientsDao
      .insertIngredient(IngredientsCompanion.insert(name: name, unit: 'g'));

  Future<int> newProduct() async {
    final cats = await db.categoriesDao.getAllCategories();
    return db.productsDao.insertProduct(
      ProductsCompanion.insert(
          name: 'Latte', price: 45, categoryId: cats.first.id),
    );
  }

  test('setRecipe reemplaza por completo la receta anterior', () async {
    final cafe = await newIngredient('Café');
    final leche = await newIngredient('Leche');
    final productId = await newProduct();

    await db.recipesDao.setRecipe(productId, [
      RecipeLineDraft(ingredientId: cafe, quantity: 18),
      RecipeLineDraft(ingredientId: leche, quantity: 200),
    ]);
    var recipe = await db.recipesDao.getRecipeForProduct(productId);
    expect(recipe, hasLength(2));

    // Guardar de nuevo con una sola línea debe borrar la otra, no acumular.
    await db.recipesDao.setRecipe(
        productId, [RecipeLineDraft(ingredientId: cafe, quantity: 20)]);
    recipe = await db.recipesDao.getRecipeForProduct(productId);
    expect(recipe, hasLength(1));
    expect(recipe.first.ingredientName, 'Café');
    expect(recipe.first.item.quantity, 20);
  });

  test('setRecipe con lista vacía borra toda la receta', () async {
    final cafe = await newIngredient('Café');
    final productId = await newProduct();
    await db.recipesDao.setRecipe(
        productId, [RecipeLineDraft(ingredientId: cafe, quantity: 18)]);

    await db.recipesDao.setRecipe(productId, []);
    expect(await db.recipesDao.getRecipeForProduct(productId), isEmpty);
  });

  test('getRecipeForProduct no mezcla recetas de otros productos', () async {
    final cafe = await newIngredient('Café');
    final p1 = await newProduct();
    final p2 = await newProduct();
    await db.recipesDao
        .setRecipe(p1, [RecipeLineDraft(ingredientId: cafe, quantity: 18)]);

    expect(await db.recipesDao.getRecipeForProduct(p2), isEmpty);
    expect(await db.recipesDao.getRecipeForProduct(p1), hasLength(1));
  });
}
