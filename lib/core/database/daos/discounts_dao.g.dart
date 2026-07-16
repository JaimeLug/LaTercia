// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discounts_dao.dart';

// ignore_for_file: type=lint
mixin _$DiscountsDaoMixin on DatabaseAccessor<AppDatabase> {
  $DiscountsTable get discounts => attachedDatabase.discounts;
  DiscountsDaoManager get managers => DiscountsDaoManager(this);
}

class DiscountsDaoManager {
  final _$DiscountsDaoMixin _db;
  DiscountsDaoManager(this._db);
  $$DiscountsTableTableManager get discounts =>
      $$DiscountsTableTableManager(_db.attachedDatabase, _db.discounts);
}
