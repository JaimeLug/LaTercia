import 'package:drift/drift.dart';
import '../database.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Future<List<Category>> getAllCategories() =>
      (select(categories)
            ..where((c) => c.active.equals(true))
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .get();

  Stream<List<Category>> watchAllCategories() =>
      (select(categories)
            ..where((c) => c.active.equals(true))
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .watch();

  Future<int> insertCategory(CategoriesCompanion cat) =>
      into(categories).insert(cat);

  Future<bool> updateCategory(CategoriesCompanion cat) =>
      update(categories).replace(cat);

  Future<int> deleteCategory(int id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();
}
