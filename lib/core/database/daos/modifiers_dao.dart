import 'package:drift/drift.dart';
import '../database.dart';

part 'modifiers_dao.g.dart';

@DriftAccessor(tables: [Modifiers])
class ModifiersDao extends DatabaseAccessor<AppDatabase>
    with _$ModifiersDaoMixin {
  ModifiersDao(super.db);

  Future<List<Modifier>> getAllModifiers() => select(modifiers).get();

  /// Returns the modifiers that apply to a product in the given category.
  /// A modifier with an empty [categoryScope] applies to everything; otherwise
  /// it only applies when its scope matches the product's category name
  /// (case-insensitive). Avoids showing e.g. "Extra shot" on a cheesecake.
  Future<List<Modifier>> getModifiersForCategoryName(
      String? categoryName) async {
    final all = await select(modifiers).get();
    final cat = categoryName?.trim().toLowerCase();
    return all.where((m) {
      final scope = m.categoryScope?.trim();
      if (scope == null || scope.isEmpty) return true;
      return cat != null && scope.toLowerCase() == cat;
    }).toList();
  }

  Stream<List<Modifier>> watchAllModifiers() => select(modifiers).watch();

  Future<int> insertModifier(ModifiersCompanion mod) =>
      into(modifiers).insert(mod);

  Future<bool> updateModifier(ModifiersCompanion mod) =>
      update(modifiers).replace(mod);

  Future<int> deleteModifier(int id) =>
      (delete(modifiers)..where((m) => m.id.equals(id))).go();
}
