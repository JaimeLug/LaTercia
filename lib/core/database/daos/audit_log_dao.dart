import 'package:drift/drift.dart';
import '../database.dart';

part 'audit_log_dao.g.dart';

/// Append-only access to [AuditLog]. Kept intentionally generic (recent /
/// by-action / by-employee / by-date-range) since Fase 2 parte B will build
/// reporting screens (antifraude, cortes X/Z, etc) on top of these queries.
@DriftAccessor(tables: [AuditLog])
class AuditLogDao extends DatabaseAccessor<AppDatabase>
    with _$AuditLogDaoMixin {
  AuditLogDao(super.db);

  Future<int> insertLog(AuditLogCompanion entry) =>
      into(auditLog).insert(entry);

  Future<List<AuditLogData>> getRecent({int limit = 100}) => (select(auditLog)
        ..orderBy([(a) => OrderingTerm.desc(a.ts)])
        ..limit(limit))
      .get();

  Future<List<AuditLogData>> getByAction(String action, {int limit = 200}) =>
      (select(auditLog)
            ..where((a) => a.action.equals(action))
            ..orderBy([(a) => OrderingTerm.desc(a.ts)])
            ..limit(limit))
          .get();

  Future<List<AuditLogData>> getByEmployee(int employeeId, {int limit = 200}) =>
      (select(auditLog)
            ..where((a) => a.employeeId.equals(employeeId))
            ..orderBy([(a) => OrderingTerm.desc(a.ts)])
            ..limit(limit))
          .get();

  Future<List<AuditLogData>> getByDateRange(DateTime start, DateTime end) =>
      (select(auditLog)
            ..where((a) => a.ts.isBetweenValues(start, end))
            ..orderBy([(a) => OrderingTerm.desc(a.ts)]))
          .get();
}
