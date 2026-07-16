// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_dao.dart';

// ignore_for_file: type=lint
mixin _$InventoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $ProductsTable get products => attachedDatabase.products;
  $TablesLayoutTable get tablesLayout => attachedDatabase.tablesLayout;
  $CustomersTable get customers => attachedDatabase.customers;
  $EmployeesTable get employees => attachedDatabase.employees;
  $ShiftsTable get shifts => attachedDatabase.shifts;
  $OrdersTable get orders => attachedDatabase.orders;
  $InventoryMovementsTable get inventoryMovements =>
      attachedDatabase.inventoryMovements;
  InventoryDaoManager get managers => InventoryDaoManager(this);
}

class InventoryDaoManager {
  final _$InventoryDaoMixin _db;
  InventoryDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$TablesLayoutTableTableManager get tablesLayout =>
      $$TablesLayoutTableTableManager(_db.attachedDatabase, _db.tablesLayout);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db.attachedDatabase, _db.employees);
  $$ShiftsTableTableManager get shifts =>
      $$ShiftsTableTableManager(_db.attachedDatabase, _db.shifts);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db.attachedDatabase, _db.orders);
  $$InventoryMovementsTableTableManager get inventoryMovements =>
      $$InventoryMovementsTableTableManager(
          _db.attachedDatabase, _db.inventoryMovements);
}
