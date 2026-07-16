// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_items_dao.dart';

// ignore_for_file: type=lint
mixin _$OrderItemsDaoMixin on DatabaseAccessor<AppDatabase> {
  $TablesLayoutTable get tablesLayout => attachedDatabase.tablesLayout;
  $CustomersTable get customers => attachedDatabase.customers;
  $EmployeesTable get employees => attachedDatabase.employees;
  $ShiftsTable get shifts => attachedDatabase.shifts;
  $OrdersTable get orders => attachedDatabase.orders;
  $CategoriesTable get categories => attachedDatabase.categories;
  $ProductsTable get products => attachedDatabase.products;
  $OrderItemsTable get orderItems => attachedDatabase.orderItems;
  OrderItemsDaoManager get managers => OrderItemsDaoManager(this);
}

class OrderItemsDaoManager {
  final _$OrderItemsDaoMixin _db;
  OrderItemsDaoManager(this._db);
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
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$OrderItemsTableTableManager get orderItems =>
      $$OrderItemsTableTableManager(_db.attachedDatabase, _db.orderItems);
}
