import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import 'database_provider.dart';

final trackedProductsProvider = FutureProvider<List<Product>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.inventoryDao.getTrackedProducts();
});
