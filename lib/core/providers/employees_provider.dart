import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import 'database_provider.dart';

final employeesProvider = StreamProvider<List<Employee>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.employeesDao.watchAllEmployees();
});
