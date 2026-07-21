import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import 'database_provider.dart';

final modifiersProvider = StreamProvider<List<Modifier>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.modifiersDao.watchAllModifiers();
});

/// Si algún modificador aplica a [categoryName]: scope vacío aplica a todas,
/// si no debe coincidir por nombre (igual que `getModifiersForCategoryName`).
bool categoryHasModifiers(List<Modifier> all, String? categoryName) {
  final cat = categoryName?.trim().toLowerCase();
  return all.any((m) {
    final scope = m.categoryScope?.trim();
    if (scope == null || scope.isEmpty) return true;
    return cat != null && scope.toLowerCase() == cat;
  });
}
