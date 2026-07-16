import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import 'database_provider.dart';

final discountsProvider = StreamProvider<List<Discount>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.discountsDao.watchAllDiscounts();
});
