// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expenses_dao.dart';

// ignore_for_file: type=lint
mixin _$ExpensesDaoMixin on DatabaseAccessor<AppDatabase> {
  $EmployeesTable get employees => attachedDatabase.employees;
  $ExpensesTable get expenses => attachedDatabase.expenses;
  ExpensesDaoManager get managers => ExpensesDaoManager(this);
}

class ExpensesDaoManager {
  final _$ExpensesDaoMixin _db;
  ExpensesDaoManager(this._db);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db.attachedDatabase, _db.employees);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db.attachedDatabase, _db.expenses);
}
