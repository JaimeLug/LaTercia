import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';

/// Thin wrapper around [AuditLogDao] used by every audit hook in the app.
///
/// Centralizing the insert here (instead of calling `db.auditLogDao.insertLog`
/// everywhere) keeps the JSON-encoding of `detail` in one place and gives the
/// call sites a single, greppable API. Never pass `Employees.pin` (or any
/// raw PIN string) inside [detail] — nothing here scrubs it for you.
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
