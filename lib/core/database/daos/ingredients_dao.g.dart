// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredients_dao.dart';

// ignore_for_file: type=lint
mixin _$IngredientsDaoMixin on DatabaseAccessor<AppDatabase> {
  $IngredientsTable get ingredients => attachedDatabase.ingredients;
  $TablesLayoutTable get tablesLayout => attachedDatabase.tablesLayout;
  $CustomersTable get customers => attachedDatabase.customers;
  $EmployeesTable get employees => attachedDatabase.employees;
  $ShiftsTable get shifts => attachedDatabase.shifts;
  $OrdersTable get orders => attachedDatabase.orders;
  $SuppliersTable get suppliers => attachedDatabase.suppliers;
  $IngredientPurchasesTable get ingredientPurchases =>
      attachedDatabase.ingredientPurchases;
  $IngredientMovementsTable get ingredientMovements =>
      attachedDatabase.ingredientMovements;
  IngredientsDaoManager get managers => IngredientsDaoManager(this);
}

class IngredientsDaoManager {
  final _$IngredientsDaoMixin _db;
  IngredientsDaoManager(this._db);
  $$IngredientsTableTableManager get ingredients =>
      $$IngredientsTableTableManager(_db.attachedDatabase, _db.ingredients);
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
  $$SuppliersTableTableManager get suppliers =>
      $$SuppliersTableTableManager(_db.attachedDatabase, _db.suppliers);
  $$IngredientPurchasesTableTableManager get ingredientPurchases =>
      $$IngredientPurchasesTableTableManager(
          _db.attachedDatabase, _db.ingredientPurchases);
  $$IngredientMovementsTableTableManager get ingredientMovements =>
      $$IngredientMovementsTableTableManager(
          _db.attachedDatabase, _db.ingredientMovements);
}
