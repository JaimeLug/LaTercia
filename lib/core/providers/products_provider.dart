import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import 'database_provider.dart';

final productsProvider = StreamProvider<List<Product>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.productsDao.watchAvailableProducts();
});

final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.productsDao.getAllProducts();
});
