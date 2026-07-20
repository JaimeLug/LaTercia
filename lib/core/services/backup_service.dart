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
/// (en Linux, desde A3 2026-07-20: `~/Documentos/latercia/backups/`), con
/// retención de N días. Corre a diario (una vez por día calendario) y al
/// cerrar turno. Todo best-effort: nunca lanza hacia el caller ni bloquea el
/// flujo de venta.
class BackupService {
  /// [baseDir] resuelve la carpeta de datos de la app, donde viven backups y
  /// logs — por defecto `getApplicationDocumentsDirectory` (A3: pensada para
  /// que un técnico la encuentre y copie a mano, por eso Documentos y no la
  /// carpeta de soporte de la app). [dbDir] resuelve la carpeta donde vive
  /// el archivo **real** de la BD — por defecto `getApplicationSupportDirectory`
  /// (así es como `driftDatabase(name: 'latercia', databaseDirectory: ...)`
  /// la resuelve ahora, ver `_openConnection` en `database.dart`).
  /// Son dos carpetas DISTINTAS a propósito — antes ambas asumían la misma
  /// (soporte de la app), y los backups automáticos fallaban en silencio
  /// (best-effort) sin respaldar nada real porque la BD nunca estuvo ahí.
  /// Los tests inyectan ambas a temps aislados.
  BackupService(
    this._db, {
    Future<Directory> Function()? baseDir,
    Future<Directory> Function()? dbDir,
  })  : _baseDir = baseDir,
        _dbDir = dbDir;

  final AppDatabase _db;
  final Future<Directory> Function()? _baseDir;
  final Future<Directory> Function()? _dbDir;

  static const _defaultRetentionDays = 14;

  Future<Directory> _appDir() async {
    final override = _baseDir;
    if (override != null) return override();
    return getApplicationDocumentsDirectory();
  }

  Future<String> _dbPath() async {
    final override = _dbDir;
    final dir = await (override ?? getApplicationSupportDirectory)();
    return p.join(dir.path, 'latercia.sqlite');
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
      // `PRAGMA wal_checkpoint(TRUNCATE)` devuelve (busy, log, checkpointed) —
      // si hay un lector concurrente (ej. el KDS a media consulta del poll de
      // 2s), el checkpoint puede quedar parcial sin lanzar error, y el backup
      // copiaría el .db sin las transacciones más recientes del WAL. Lo
      // logueamos (no bloqueante — best-effort) para poder diagnosticarlo.
      final checkpoint =
          await _db.customSelect('PRAGMA wal_checkpoint(TRUNCATE);').get();
      if (checkpoint.isNotEmpty) {
        final row = checkpoint.first.data;
        final busy = row['busy'] as int?;
        final log = row['log'] as int?;
        final checkpointed = row['checkpointed'] as int?;
        if (busy == 1 ||
            (log != null && checkpointed != null && checkpointed < log)) {
          appLogger.warn(
              'Checkpoint del WAL incompleto antes del backup ($reason): '
              'busy=$busy log=$log checkpointed=$checkpointed — el respaldo '
              'podría no incluir las escrituras más recientes.');
        }
      }
      final src = File(await _dbPath());
      if (!await src.exists()) return null;

      final dir = await backupsDir();
      // Limpia .tmp huérfanos de un intento anterior interrumpido (ej. el
      // proceso murió entre el copy() y el rename()) — no deben acumularse.
      await for (final e in dir.list()) {
        if (e is File && e.path.endsWith('.tmp')) {
          try {
            await e.delete();
          } catch (_) {/* best-effort */}
        }
      }
      final stamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
      final dest = p.join(dir.path, 'latercia-$stamp.db');
      // Copia a un archivo temporal y luego renombra — el rename es atómico
      // en el mismo volumen (Windows/Linux), así que ante un corte de luz a
      // medio `copy()` el respaldo nunca queda truncado con el nombre final:
      // o existe completo, o no existe.
      final tmp = File('$dest.tmp');
      await src.copy(tmp.path);
      await tmp.rename(dest);

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
    final enabled = (await _db.settingsDao.getValue('backup_auto')) != 'false';
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
    final enabled = (await _db.settingsDao.getValue('backup_auto')) != 'false';
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
