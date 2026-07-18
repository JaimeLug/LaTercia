import 'package:drift/drift.dart';
import '../database.dart';

part 'delivery_zones_dao.g.dart';

@DriftAccessor(tables: [DeliveryZones])
class DeliveryZonesDao extends DatabaseAccessor<AppDatabase>
    with _$DeliveryZonesDaoMixin {
  DeliveryZonesDao(super.db);

  Future<List<DeliveryZone>> getAllZones() =>
      (select(deliveryZones)..orderBy([(z) => OrderingTerm(expression: z.name)]))
          .get();

  Future<List<DeliveryZone>> getActiveZones() =>
      (select(deliveryZones)
            ..where((z) => z.active.equals(true))
            ..orderBy([(z) => OrderingTerm(expression: z.name)]))
          .get();

  Stream<List<DeliveryZone>> watchActiveZones() => (select(deliveryZones)
        ..where((z) => z.active.equals(true))
        ..orderBy([(z) => OrderingTerm(expression: z.name)]))
      .watch();

  Future<int> insertZone(DeliveryZonesCompanion entry) =>
      into(deliveryZones).insert(entry);

  Future<void> updateZone(DeliveryZonesCompanion entry) =>
      (update(deliveryZones)..where((z) => z.id.equals(entry.id.value)))
          .write(entry);

  Future<void> setActive(int id, bool active) =>
      (update(deliveryZones)..where((z) => z.id.equals(id)))
          .write(DeliveryZonesCompanion(active: Value(active)));
}
