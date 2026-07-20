import 'package:drift/drift.dart';
import '../database.dart';

part 'recipes_dao.g.dart';

class RecipeLineDraft {
  final int ingredientId;
  final double quantity;
  const RecipeLineDraft({required this.ingredientId, required this.quantity});
}

/// Línea de receta + nombre/unidad del insumo, para pintar el editor sin una
/// segunda consulta por fila.
typedef RecipeLineWithIngredient = ({
  RecipeItem item,
  String ingredientName,
  String unit,
});

@DriftAccessor(tables: [RecipeItems, Ingredients])
class RecipesDao extends DatabaseAccessor<AppDatabase> with _$RecipesDaoMixin {
  RecipesDao(super.db);

  Future<List<RecipeLineWithIngredient>> getRecipeForProduct(
      int productId) async {
    final query = select(recipeItems).join([
      innerJoin(
          ingredients, ingredients.id.equalsExp(recipeItems.ingredientId)),
    ])
      ..where(recipeItems.productId.equals(productId));
    final rows = await query.get();
    return rows
        .map((row) => (
              item: row.readTable(recipeItems),
              ingredientName: row.readTable(ingredients).name,
              unit: row.readTable(ingredients).unit,
            ))
        .toList();
  }

  /// Reemplaza la receta completa de un producto: borra las líneas existentes
  /// e inserta las nuevas — más simple que calcular un diff, y la UI siempre
  /// manda la lista completa.
  Future<void> setRecipe(int productId, List<RecipeLineDraft> lines) {
    return transaction(() async {
      await (delete(recipeItems)..where((r) => r.productId.equals(productId)))
          .go();
      for (final line in lines) {
        await into(recipeItems).insert(
          RecipeItemsCompanion.insert(
            productId: productId,
            ingredientId: line.ingredientId,
            quantity: line.quantity,
          ),
        );
      }
    });
  }
}
