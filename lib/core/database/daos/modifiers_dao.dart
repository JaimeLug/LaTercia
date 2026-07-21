import 'package:drift/drift.dart';
import '../database.dart';

part 'modifiers_dao.g.dart';

@DriftAccessor(tables: [Modifiers])
class ModifiersDao extends DatabaseAccessor<AppDatabase>
    with _$ModifiersDaoMixin {
  ModifiersDao(super.db);

  Future<List<Modifier>> getAllModifiers() => select(modifiers).get();

  /// Modificadores que aplican a una categoría. [categoryScope] vacío aplica a
  /// todo; si no, es una lista separada por comas de nombres de categoría y
  /// aplica si cualquiera coincide (evita ver "Extra shot" en un cheesecake).
  Future<List<Modifier>> getModifiersForCategoryName(
      String? categoryName) async {
    final all = await select(modifiers).get();
    final cat = categoryName?.trim().toLowerCase();
    return all.where((m) {
      final scope = m.categoryScope?.trim();
      if (scope == null || scope.isEmpty) return true;
      if (cat == null) return false;
      return scope.split(',').map((s) => s.trim().toLowerCase()).contains(cat);
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
