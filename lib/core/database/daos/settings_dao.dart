import 'package:drift/drift.dart';
import '../database.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<String?> getValue(String key) async {
    final row = await (select(settings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setValue(String key, String? value) async {
    await into(settings).insertOnConflictUpdate(
      SettingsCompanion.insert(key: key, value: Value(value)),
    );
  }

  Future<Map<String, String>> getAllSettings() async {
    final rows = await select(settings).get();
    return {for (final r in rows) r.key: r.value ?? ''};
  }
}
