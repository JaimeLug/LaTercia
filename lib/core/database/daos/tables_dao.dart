import 'package:drift/drift.dart';
import '../database.dart';

part 'tables_dao.g.dart';

@DriftAccessor(tables: [TablesLayout])
class TablesDao extends DatabaseAccessor<AppDatabase> with _$TablesDaoMixin {
  TablesDao(super.db);

  Future<List<TablesLayoutData>> getAllTables() =>
      (select(tablesLayout)
            ..where((t) => t.active.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  Stream<List<TablesLayoutData>> watchAllTables() =>
      (select(tablesLayout)
            ..where((t) => t.active.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .watch();

  Future<List<TablesLayoutData>> getAvailableTables() =>
      (select(tablesLayout)
            ..where((t) =>
                t.active.equals(true) & t.status.equals('available'))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  Future<void> updateTableStatus(int id, String status) =>
      (update(tablesLayout)..where((t) => t.id.equals(id)))
          .write(TablesLayoutCompanion(status: Value(status)));

  Future<int> insertTable(TablesLayoutCompanion table) =>
      into(tablesLayout).insert(table);

  Future<bool> updateTable(TablesLayoutCompanion table) =>
      update(tablesLayout).replace(table);

  Future<int> deleteTable(int id) =>
      (delete(tablesLayout)..where((t) => t.id.equals(id))).go();
}
