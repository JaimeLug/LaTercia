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
    // Base de datos respaldada por archivo real (no en memoria), en la ruta
    // que BackupService espera de [dbDir]: <dbDirTemp>/latercia.sqlite —
    // misma convención que la BD real (getApplicationDocumentsDirectory,
    // sin subcarpeta), en un temp aparte del de backups/logs ([baseDir]).
    final dbDirTemp = Directory(p.join(tempBase.path, 'docs'));
    await dbDirTemp.create(recursive: true);
    db = AppDatabase.forTesting(
        NativeDatabase(File(p.join(dbDirTemp.path, 'latercia.sqlite'))));
    // Fuerza la creación del archivo ejecutando una consulta.
    await db.settingsDao.getAllSettings();
    backup = BackupService(
      db,
      baseDir: () async => tempBase,
      dbDir: () async => dbDirTemp,
    );
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

  // FASE de auditoría 2026-07-17 — el backup ahora copia a .tmp y renombra
  // (rename atómico) en vez de copiar directo al nombre final.
  test('backupNow nunca deja el archivo final con sufijo .tmp', () async {
    final file = await backup.backupNow(reason: 'test');
    expect(file, isNotNull);
    expect(file!.path.endsWith('.tmp'), isFalse);
    expect(await File('${file.path}.tmp').exists(), isFalse,
        reason: 'no debe quedar un .tmp huérfano tras un backup exitoso');
  });

  test('un .tmp huérfano de un intento anterior interrumpido se limpia solo',
      () async {
    final dir = await backup.backupsDir();
    final orphan = File(p.join(dir.path, 'latercia-viejo.db.tmp'));
    await orphan.writeAsString('incompleto');

    await backup.backupNow(reason: 'test');

    expect(await orphan.exists(), isFalse,
        reason: 'el .tmp huérfano debe borrarse en el siguiente backup');
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
