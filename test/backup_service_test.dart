import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/services/backup_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempBase;
  late AppDatabase db;
  late BackupService backup;

  setUp(() async {
    tempBase = await Directory.systemTemp.createTemp('latercia_backup_test');
    // Base de datos respaldada por archivo real (no en memoria), en la ruta que
    // BackupService espera: <base>/latercia/latercia.db.
    final dbDir = Directory(p.join(tempBase.path, 'latercia'));
    await dbDir.create(recursive: true);
    db = AppDatabase.forTesting(
        NativeDatabase(File(p.join(dbDir.path, 'latercia.db'))));
    // Fuerza la creación del archivo ejecutando una consulta.
    await db.settingsDao.getAllSettings();
    backup = BackupService(db, baseDir: () async => tempBase);
  });

  tearDown(() async {
    await db.close();
    try {
      await tempBase.delete(recursive: true);
    } catch (_) {}
  });

  test('backupNow crea una copia y sella last_backup_at', () async {
    final file = await backup.backupNow(reason: 'test');
    expect(file, isNotNull);
    expect(await file!.exists(), isTrue);
    expect(p.basename(file.path), startsWith('latercia-'));

    final stamp = await db.settingsDao.getValue('last_backup_at');
    expect(stamp, isNotNull);

    final info = await backup.lastBackupInfo();
    expect(info, isNotNull);
    expect(info!.sizeBytes, greaterThan(0));
  });

  test('autoBackupIfDue no hace nada si backup_auto está OFF', () async {
    await db.settingsDao.setValue('backup_auto', 'false');
    await backup.autoBackupIfDue();
    expect(await backup.lastBackupInfo(), isNull);
  });

  test('autoBackupIfDue respalda una vez y no repite el mismo día', () async {
    await db.settingsDao.setValue('backup_auto', 'true');
    await backup.autoBackupIfDue();
    final first = await backup.lastBackupInfo();
    expect(first, isNotNull);

    // Segunda llamada el mismo día: no debe crear otro (ya se hizo hoy).
    await backup.autoBackupIfDue();
    final dir = await backup.backupsDir();
    final count =
        await dir.list().where((e) => e.path.endsWith('.db')).length;
    expect(count, 1);
  });

  test('la retención borra respaldos más antiguos que N días', () async {
    await db.settingsDao.setValue('backup_retention_days', '7');
    final dir = await backup.backupsDir();
    // Un respaldo "viejo" de hace 30 días.
    final old = File(p.join(dir.path, 'latercia-viejo.db'));
    await old.writeAsString('x');
    await old.setLastModified(
        DateTime.now().subtract(const Duration(days: 30)));

    await backup.backupNow(reason: 'test'); // dispara la poda

    expect(await old.exists(), isFalse, reason: 'el viejo se poda');
  });
}
