import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import 'database_provider.dart';

final tablesProvider = StreamProvider<List<TablesLayoutData>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.tablesDao.watchAllTables();
});
