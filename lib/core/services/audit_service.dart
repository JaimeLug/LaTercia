import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';

/// API única para escribir en `audit_log`. Nunca pasar PINs en [detail].
/// `docs/permisos-y-auditoria.md`.
class AuditService {
  AuditService(this._db);

  final AppDatabase _db;

  Future<void> log({
    int? employeeId,
    required String action,
    String? entity,
    int? entityId,
    Map<String, dynamic>? detail,
  }) {
    return _db.auditLogDao.insertLog(
      AuditLogCompanion.insert(
        employeeId: Value(employeeId),
        action: action,
        entity: Value(entity),
        entityId: Value(entityId),
        detailJson: Value(detail == null ? null : jsonEncode(detail)),
      ),
    );
  }
}

final auditServiceProvider = Provider<AuditService>((ref) {
  return AuditService(ref.watch(databaseProvider));
});
