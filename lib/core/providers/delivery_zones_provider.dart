import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import 'database_provider.dart';

final deliveryZonesProvider = StreamProvider<List<DeliveryZone>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.deliveryZonesDao.watchActiveZones();
});
