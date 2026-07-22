import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import 'database_provider.dart';

final combosProvider = StreamProvider<List<Combo>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.combosDao.watchAllCombos();
});
