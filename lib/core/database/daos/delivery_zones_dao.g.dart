// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_zones_dao.dart';

// ignore_for_file: type=lint
mixin _$DeliveryZonesDaoMixin on DatabaseAccessor<AppDatabase> {
  $DeliveryZonesTable get deliveryZones => attachedDatabase.deliveryZones;
  DeliveryZonesDaoManager get managers => DeliveryZonesDaoManager(this);
}

class DeliveryZonesDaoManager {
  final _$DeliveryZonesDaoMixin _db;
  DeliveryZonesDaoManager(this._db);
  $$DeliveryZonesTableTableManager get deliveryZones =>
      $$DeliveryZonesTableTableManager(_db.attachedDatabase, _db.deliveryZones);
}
