// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payments_dao.dart';

// ignore_for_file: type=lint
mixin _$PaymentsDaoMixin on DatabaseAccessor<AppDatabase> {
  $TablesLayoutTable get tablesLayout => attachedDatabase.tablesLayout;
  $CustomersTable get customers => attachedDatabase.customers;
  $EmployeesTable get employees => attachedDatabase.employees;
  $ShiftsTable get shifts => attachedDatabase.shifts;
  $OrdersTable get orders => attachedDatabase.orders;
  $PaymentsTable get payments => attachedDatabase.payments;
  PaymentsDaoManager get managers => PaymentsDaoManager(this);
}

class PaymentsDaoManager {
  final _$PaymentsDaoMixin _db;
  PaymentsDaoManager(this._db);
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
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db.attachedDatabase, _db.payments);
}
