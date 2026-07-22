// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'combos_dao.dart';

// ignore_for_file: type=lint
mixin _$CombosDaoMixin on DatabaseAccessor<AppDatabase> {
  $CombosTable get combos => attachedDatabase.combos;
  $CategoriesTable get categories => attachedDatabase.categories;
  $ProductsTable get products => attachedDatabase.products;
  $ComboItemsTable get comboItems => attachedDatabase.comboItems;
  CombosDaoManager get managers => CombosDaoManager(this);
}

class CombosDaoManager {
  final _$CombosDaoMixin _db;
  CombosDaoManager(this._db);
  $$CombosTableTableManager get combos =>
      $$CombosTableTableManager(_db.attachedDatabase, _db.combos);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$ComboItemsTableTableManager get comboItems =>
      $$ComboItemsTableTableManager(_db.attachedDatabase, _db.comboItems);
}
