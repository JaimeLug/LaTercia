// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shifts_dao.dart';

// ignore_for_file: type=lint
mixin _$ShiftsDaoMixin on DatabaseAccessor<AppDatabase> {
  $EmployeesTable get employees => attachedDatabase.employees;
  $ShiftsTable get shifts => attachedDatabase.shifts;
  ShiftsDaoManager get managers => ShiftsDaoManager(this);
}

class ShiftsDaoManager {
  final _$ShiftsDaoMixin _db;
  ShiftsDaoManager(this._db);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db.attachedDatabase, _db.employees);
  $$ShiftsTableTableManager get shifts =>
      $$ShiftsTableTableManager(_db.attachedDatabase, _db.shifts);
}
