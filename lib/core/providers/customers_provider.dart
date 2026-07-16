import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import 'database_provider.dart';

final customersProvider = StreamProvider<List<Customer>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.customersDao.watchAllCustomers();
});
