// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log_dao.dart';

// ignore_for_file: type=lint
mixin _$AuditLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $EmployeesTable get employees => attachedDatabase.employees;
  $AuditLogTable get auditLog => attachedDatabase.auditLog;
  AuditLogDaoManager get managers => AuditLogDaoManager(this);
}

class AuditLogDaoManager {
  final _$AuditLogDaoMixin _db;
  AuditLogDaoManager(this._db);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db.attachedDatabase, _db.employees);
  $$AuditLogTableTableManager get auditLog =>
      $$AuditLogTableTableManager(_db.attachedDatabase, _db.auditLog);
}
