// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchases_dao.dart';

// ignore_for_file: type=lint
mixin _$PurchasesDaoMixin on DatabaseAccessor<AppDatabase> {
  $SuppliersTable get suppliers => attachedDatabase.suppliers;
  $EmployeesTable get employees => attachedDatabase.employees;
  $IngredientPurchasesTable get ingredientPurchases =>
      attachedDatabase.ingredientPurchases;
  $IngredientsTable get ingredients => attachedDatabase.ingredients;
  $IngredientPurchaseItemsTable get ingredientPurchaseItems =>
      attachedDatabase.ingredientPurchaseItems;
  $TablesLayoutTable get tablesLayout => attachedDatabase.tablesLayout;
  $CustomersTable get customers => attachedDatabase.customers;
  $ShiftsTable get shifts => attachedDatabase.shifts;
  $OrdersTable get orders => attachedDatabase.orders;
  $IngredientMovementsTable get ingredientMovements =>
      attachedDatabase.ingredientMovements;
  PurchasesDaoManager get managers => PurchasesDaoManager(this);
}

class PurchasesDaoManager {
  final _$PurchasesDaoMixin _db;
  PurchasesDaoManager(this._db);
  $$SuppliersTableTableManager get suppliers =>
      $$SuppliersTableTableManager(_db.attachedDatabase, _db.suppliers);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db.attachedDatabase, _db.employees);
  $$IngredientPurchasesTableTableManager get ingredientPurchases =>
      $$IngredientPurchasesTableTableManager(
          _db.attachedDatabase, _db.ingredientPurchases);
  $$IngredientsTableTableManager get ingredients =>
      $$IngredientsTableTableManager(_db.attachedDatabase, _db.ingredients);
  $$IngredientPurchaseItemsTableTableManager get ingredientPurchaseItems =>
      $$IngredientPurchaseItemsTableTableManager(
          _db.attachedDatabase, _db.ingredientPurchaseItems);
  $$TablesLayoutTableTableManager get tablesLayout =>
      $$TablesLayoutTableTableManager(_db.attachedDatabase, _db.tablesLayout);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
  $$ShiftsTableTableManager get shifts =>
      $$ShiftsTableTableManager(_db.attachedDatabase, _db.shifts);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db.attachedDatabase, _db.orders);
  $$IngredientMovementsTableTableManager get ingredientMovements =>
      $$IngredientMovementsTableTableManager(
          _db.attachedDatabase, _db.ingredientMovements);
}
