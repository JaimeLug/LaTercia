import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../utils/app_logger.dart';

/// Metadatos del último backup, para el panel de salud (5.4).
typedef BackupInfo = ({DateTime modified, int sizeBytes, String path});

/// FASE 5.2 — Backups automáticos.
///
/// Copia la base con checkpoint del WAL a `%APPDATA%/latercia/backups/`
/// (en Linux: `~/.local/share/latercia/backups/`), con retención de N días.
/// Corre a diario (una vez por día calendario) y al cerrar turno. Todo
/// best-effort: nunca lanza hacia el caller ni bloquea el flujo de venta.
class BackupService {
  /// [baseDir] resuelve la carpeta de datos de la app (por defecto
  /// `getApplicationSupportDirectory`); los tests la inyectan a un temp.
  BackupService(this._db, {Future<Directory> Function()? baseDir})
      : _baseDir = baseDir;

  final AppDatabase _db;
  final Future<Directory> Function()? _baseDir;

  static const _defaultRetentionDays = 14;

  Future<Directory> _appDir() async {
    final override = _baseDir;
    if (override != null) return override();
    return getApplicationSupportDirectory();
  }

  Future<String> _dbPath() async {
    final appDir = await _appDir();
    return p.join(appDir.path, 'latercia', 'latercia.db');
  }

  Future<Directory> backupsDir() async {
    final appDir = await _appDir();
    final dir = Directory(p.join(appDir.path, 'latercia', 'backups'));
    await dir.create(recursive: true);
    return dir;
  }

  Future<int> _retentionDays() async {
    final v = await _db.settingsDao.getValue('backup_retention_days');
    return int.tryParse(v ?? '') ?? _defaultRetentionDays;
  }

  /// Hace un checkpoint del WAL y copia la base a la carpeta de backups con un
  /// nombre con fecha/hora; luego poda los antiguos y sella `last_backup_at`.
  /// Devuelve el archivo creado, o null si falló (best-effort).
  Future<File?> backupNow({required String reason}) async {
    try {
      // Vuelca el WAL al .db para que la copia incluya lo recién escrito.
      await _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
      final src = File(await _dbPath());
      if (!await src.exists()) return null;

      final dir = await backupsDir();
      final stamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
      final dest = p.join(dir.path, 'latercia-$stamp.db');
      await src.copy(dest);

      await _db.settingsDao
          .setValue('last_backup_at', DateTime.now().toIso8601String());
      await _pruneOld();
      appLogger.info('Backup creado ($reason): $dest');
      return File(dest);
    } catch (e, st) {
      appLogger.warn('No se pudo crear el backup ($reason).', e, st);
      return null;
    }
  }

  /// Corre un backup diario si `backup_auto` está ON y aún no se hizo hoy.
  Future<void> autoBackupIfDue() async {
    final enabled =
        (await _db.settingsDao.getValue('backup_auto')) != 'false';
    if (!enabled) return;
    final lastStr = await _db.settingsDao.getValue('last_backup_at');
    final last = lastStr == null ? null : DateTime.tryParse(lastStr);
    final now = DateTime.now();
    final alreadyToday = last != null &&
        last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
    if (!alreadyToday) {
      await backupNow(reason: 'diario');
    }
  }

  /// Backup al cerrar turno (si el flag está ON). Independiente del diario.
  Future<void> backupOnShiftClose() async {
    final enabled =
        (await _db.settingsDao.getValue('backup_auto')) != 'false';
    if (!enabled) return;
    await backupNow(reason: 'cierre_turno');
  }

  Future<void> _pruneOld() async {
    final days = await _retentionDays();
    if (days <= 0) return; // 0 = sin poda
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final dir = await backupsDir();
    await for (final e in dir.list()) {
      if (e is File && e.path.endsWith('.db')) {
        final stat = await e.stat();
        if (stat.modified.isBefore(cutoff)) {
          try {
            await e.delete();
          } catch (_) {/* best-effort */}
        }
      }
    }
  }

  /// El backup más reciente (fecha, tamaño, ruta), o null si no hay ninguno.
  Future<BackupInfo?> lastBackupInfo() async {
    final dir = await backupsDir();
    File? newest;
    DateTime? newestTime;
    await for (final e in dir.list()) {
      if (e is File && e.path.endsWith('.db')) {
        final stat = await e.stat();
        if (newestTime == null || stat.modified.isAfter(newestTime)) {
          newest = e;
          newestTime = stat.modified;
        }
      }
    }
    if (newest == null) return null;
    final s = await newest.stat();
    return (modified: s.modified, sizeBytes: s.size, path: newest.path);
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(databaseProvider));
});
