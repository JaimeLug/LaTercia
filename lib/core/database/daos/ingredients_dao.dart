import 'package:drift/drift.dart';
import '../database.dart';

part 'ingredients_dao.g.dart';

@DriftAccessor(tables: [Ingredients, IngredientMovements])
class IngredientsDao extends DatabaseAccessor<AppDatabase>
    with _$IngredientsDaoMixin {
  IngredientsDao(super.db);

  Future<List<Ingredient>> getAllIngredients() =>
      (select(ingredients)..orderBy([(i) => OrderingTerm(expression: i.name)]))
          .get();

  Future<List<Ingredient>> getActiveIngredients() => (select(ingredients)
        ..where((i) => i.active.equals(true))
        ..orderBy([(i) => OrderingTerm(expression: i.name)]))
      .get();

  Future<int> insertIngredient(IngredientsCompanion entry) =>
      into(ingredients).insert(entry);

  Future<void> updateIngredient(IngredientsCompanion entry) =>
      (update(ingredients)..where((i) => i.id.equals(entry.id.value)))
          .write(entry);

  /// Soft delete — nunca se borra la fila: evitaría romper las referencias de
  /// [RecipeItems]/[IngredientMovements] a este insumo.
  Future<void> setActive(int id, bool active) =>
      (update(ingredients)..where((i) => i.id.equals(id)))
          .write(IngredientsCompanion(active: Value(active)));

  /// Fija el stock a un valor absoluto (diálogo "Ajustar stock" manual).
  Future<void> adjustStock(
      int ingredientId, double newQuantity, String reason, String? note) async {
    final ingredient = await (select(ingredients)
          ..where((i) => i.id.equals(ingredientId)))
        .getSingleOrNull();
    if (ingredient == null) return;

    final delta = newQuantity - ingredient.stockQuantity;
    await into(ingredientMovements).insert(
      IngredientMovementsCompanion.insert(
        ingredientId: ingredientId,
        delta: delta,
        reason: reason,
        note: Value(note),
      ),
    );
    await (update(ingredients)..where((i) => i.id.equals(ingredientId))).write(
      IngredientsCompanion(stockQuantity: Value(newQuantity)),
    );
  }

  Future<List<IngredientMovement>> getMovementsForIngredient(
          int ingredientId) =>
      (select(ingredientMovements)
            ..where((m) => m.ingredientId.equals(ingredientId))
            ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
          .get();

  Future<List<Ingredient>> getLowStock() => (select(ingredients)
        ..where((i) =>
            i.active.equals(true) &
            i.stockQuantity.isSmallerOrEqual(i.minStock)))
      .get();
}
