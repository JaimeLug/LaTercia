import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import 'database_provider.dart';

final modifiersProvider = StreamProvider<List<Modifier>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.modifiersDao.watchAllModifiers();
});

/// Whether any modifier applies to [categoryName], mirroring
/// [ModifiersDao.getModifiersForCategoryName]'s scoping rule: an empty scope
/// applies to every category, otherwise it must match by name.
bool categoryHasModifiers(List<Modifier> all, String? categoryName) {
  final cat = categoryName?.trim().toLowerCase();
  return all.any((m) {
    final scope = m.categoryScope?.trim();
    if (scope == null || scope.isEmpty) return true;
    return cat != null && scope.toLowerCase() == cat;
  });
}
