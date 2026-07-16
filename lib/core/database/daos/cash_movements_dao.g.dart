// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_movements_dao.dart';

// ignore_for_file: type=lint
mixin _$CashMovementsDaoMixin on DatabaseAccessor<AppDatabase> {
  $EmployeesTable get employees => attachedDatabase.employees;
  $ShiftsTable get shifts => attachedDatabase.shifts;
  $CashMovementsTable get cashMovements => attachedDatabase.cashMovements;
  CashMovementsDaoManager get managers => CashMovementsDaoManager(this);
}

class CashMovementsDaoManager {
  final _$CashMovementsDaoMixin _db;
  CashMovementsDaoManager(this._db);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db.attachedDatabase, _db.employees);
  $$ShiftsTableTableManager get shifts =>
      $$ShiftsTableTableManager(_db.attachedDatabase, _db.shifts);
  $$CashMovementsTableTableManager get cashMovements =>
      $$CashMovementsTableTableManager(_db.attachedDatabase, _db.cashMovements);
}
