import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audit_service.dart';
import 'database_provider.dart';
import 'session_provider.dart';

class SettingsNotifier
    extends AsyncNotifier<Map<String, String>> {
  @override
  Future<Map<String, String>> build() async {
    final db = ref.watch(databaseProvider);
    return db.settingsDao.getAllSettings();
  }

  Future<void> setSetting(String key, String value) async {
    final db = ref.read(databaseProvider);
    await db.settingsDao.setValue(key, value);
    await ref.read(auditServiceProvider).log(
      employeeId: ref.read(sessionProvider)?.id,
      action: 'cambio_settings',
      entity: 'setting',
      detail: {'key': key, 'value': value},
    );
    ref.invalidateSelf();
  }

  Future<void> setSettings(Map<String, String> values) async {
    final db = ref.read(databaseProvider);
    for (final entry in values.entries) {
      await db.settingsDao.setValue(entry.key, entry.value);
    }
    await ref.read(auditServiceProvider).log(
      employeeId: ref.read(sessionProvider)?.id,
      action: 'cambio_settings',
      entity: 'setting',
      detail: {'keys': values.keys.toList()},
    );
    ref.invalidateSelf();
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, Map<String, String>>(
  SettingsNotifier.new,
);
