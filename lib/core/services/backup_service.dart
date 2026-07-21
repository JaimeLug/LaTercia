import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Variable;
import 'package:excel/excel.dart' as xlsx;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sq;

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../utils/app_logger.dart';

/// Metadatos del último backup, para el panel de salud (5.4).
typedef BackupInfo = ({DateTime modified, int sizeBytes, String path});

/// Estado de una fila del `.db` elegido al comparar contra la base actual,
/// para la restauración parcial por grupo (ver [BackupService.previewGroupRestore]).
enum RestoreRowStatus {
  /// El id no existe en la base actual — se agrega sin pedir nada.
  nueva,

  /// El id existe y todas las columnas son iguales — nada que decidir.
  igual,

  /// El id existe pero al menos una columna cambió — el usuario decide.
  diferente,
}

/// Qué hacer con una fila [RestoreRowStatus.diferente] al aplicar la
/// restauración parcial.
enum RestoreDecision {
  /// No tocar la fila actual (default si no se decide nada).
  mantenerActual,

  /// Sobrescribir la fila actual con los valores del `.db` elegido.
  usarRespaldo,
}

/// Una fila comparada entre el `.db` elegido y la base actual, para que la
/// pantalla de restauración parcial arme la lista de conflictos a decidir.
typedef RestoreRowDiff = ({
  String table,
  int id,
  RestoreRowStatus status,
  Map<String, Object?> currentValues, // vacío si status == nueva
  Map<String, Object?> backupValues,
});

/// Conteo de lo que hizo [BackupService.applyGroupRestore], para el resumen
/// final que ve el usuario.
typedef RestoreApplyResult = ({int added, int updated, int kept});

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

  /// Tablas exportables a `.sql`/`.xlsx` (pantalla de Backups) — llave =
  /// nombre real de la tabla en SQLite (ver `$name` en `database.g.dart`),
  /// valor = etiqueta en español para la UI. El `.db` completo no pasa por
  /// aquí: siempre es la base entera, sin selección.
  static const Map<String, String> exportableTables = {
    'products': 'Productos',
    'categories': 'Categorías',
    'modifiers': 'Modificadores',
    'discounts': 'Descuentos',
    'tables_layout': 'Mesas',
    'customers': 'Clientes',
    'employees': 'Empleados',
    'shifts': 'Turnos',
    'orders': 'Órdenes',
    'order_items': 'Items de orden',
    'payments': 'Pagos',
    'expenses': 'Gastos',
    'cash_movements': 'Movimientos de caja',
    'refunds': 'Reembolsos',
    'suppliers': 'Proveedores',
    'ingredients': 'Ingredientes',
    'inventory_movements': 'Movimientos de inventario',
    'ingredient_movements': 'Movimientos de ingrediente',
    'ingredient_purchases': 'Compras de insumos',
    'ingredient_purchase_items': 'Items de compra de insumos',
    'recipe_items': 'Recetas',
    'delivery_zones': 'Zonas de envío',
    'settings': 'Configuración',
    'audit_log': 'Bitácora de auditoría',
  };

  /// Grupos que SÍ se pueden restaurar por partes desde un `.db` (pantalla de
  /// Backups → restauración parcial). Son "datos maestros" (catálogo-like):
  /// autocontenidos o con referencias solo hacia otros datos maestros.
  ///
  /// A propósito NO están aquí:
  /// - **Operación** (turnos, órdenes, pagos, gastos, reembolsos, movimientos
  ///   de caja): historial real de negocio, ligado a casi todo — restaurarlo
  ///   a medias mientras el resto de la base sigue vivo es justo donde se
  ///   corrompen los datos. Se restaura solo con el `.db` completo.
  /// - **Movimientos de inventario/ingredientes y compras**: son historial
  ///   transaccional (referencian órdenes), mismo motivo que Operación.
  /// - **Sistema** (settings, audit_log): restaurar settings pisaría en
  ///   silencio la IP de la impresora / IVA actuales; el audit_log es un
  ///   registro append-only que no tiene sentido "restaurar".
  ///
  /// El orden de cada lista es orden de INSERCIÓN (padres antes que hijos, por
  /// las llaves foráneas). El borrado en modo "reemplazar" va en orden inverso.
  static const Map<String, List<String>> restoreGroups = {
    'Catálogo': [
      'categories',
      'products',
      'modifiers',
      'discounts',
      'tables_layout',
    ],
    'Clientes': ['customers'],
    'Empleados': ['employees'],
    'Inventario': ['suppliers', 'ingredients', 'recipe_items'],
    'Envío': ['delivery_zones'],
  };

  /// Mismo universo de [exportableTables], agrupado para los checkboxes de
  /// la pantalla de Backups (orden = orden de aparición en la UI).
  static const Map<String, List<String>> exportGroups = {
    'Catálogo': [
      'products',
      'categories',
      'modifiers',
      'discounts',
      'tables_layout',
    ],
    'Personas': ['customers', 'employees'],
    'Operación': [
      'shifts',
      'orders',
      'order_items',
      'payments',
      'expenses',
      'cash_movements',
      'refunds',
    ],
    'Inventario': [
      'suppliers',
      'ingredients',
      'inventory_movements',
      'ingredient_movements',
      'ingredient_purchases',
      'ingredient_purchase_items',
      'recipe_items',
    ],
    'Envío': ['delivery_zones'],
    'Sistema': ['settings', 'audit_log'],
  };

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

  /// Todos los respaldos `.db` locales, más reciente primero — para el
  /// historial de la pantalla de Backups ([lastBackupInfo] solo da el último).
  Future<List<BackupInfo>> listBackups() async {
    final dir = await backupsDir();
    final result = <BackupInfo>[];
    await for (final e in dir.list()) {
      if (e is File && e.path.endsWith('.db')) {
        final stat = await e.stat();
        result
            .add((modified: stat.modified, sizeBytes: stat.size, path: e.path));
      }
    }
    result.sort((a, b) => b.modified.compareTo(a.modified));
    return result;
  }

  /// Nombres de columna de [table] en su orden real (`PRAGMA table_info`),
  /// para que el `.sql`/`.xlsx` tengan las columnas en el mismo orden que la
  /// tabla real sin depender del orden de `Map` que devuelve `SELECT *`.
  Future<List<String>> _tableColumns(String table) async {
    final info = await _db.customSelect('PRAGMA table_info($table)').get();
    final rows = info.toList()
      ..sort((a, b) => (a.data['cid'] as int).compareTo(b.data['cid'] as int));
    return rows.map((r) => r.data['name'] as String).toList();
  }

  /// Filtra [tables] contra [exportableTables]; vacío o null = todas. Nunca
  /// confía ciegamente en lo que mande el caller (aunque hoy solo lo llama
  /// la pantalla de Backups con sus propios checkboxes).
  List<String> _resolveSelection(List<String>? tables) {
    if (tables == null || tables.isEmpty) return exportableTables.keys.toList();
    final allowed = exportableTables.keys.toSet();
    return tables.where(allowed.contains).toList();
  }

  /// Exporta [tables] (o todas si se omite) a un `.sql` legible: el
  /// `CREATE TABLE` real de cada tabla (tal cual vive en `sqlite_master`,
  /// con sus constraints) seguido de un `INSERT` por fila. Solo lectura de
  /// exportación — nada en la app vuelve a importar un `.sql` (ver decisión
  /// en `PLAN_ACTUALIZACION_GRANDE_2026-07.md`: reconstruir una BD relacional
  /// desde un dump editado a mano es donde se corrompen los datos; el único
  /// formato de restauración real sigue siendo `.db`).
  Future<String> exportSql({List<String>? tables}) async {
    final selected = _resolveSelection(tables);
    final buffer = StringBuffer()
      ..writeln('-- Exportado por LaTercia POS — '
          '${DateTime.now().toIso8601String()}');
    for (final table in selected) {
      final schema = await _db.customSelect(
        "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = ?",
        variables: [Variable.withString(table)],
      ).getSingleOrNull();
      final createSql = schema?.data['sql'] as String?;
      if (createSql == null) continue; // tabla inesperada, se ignora

      buffer
        ..writeln()
        ..writeln('-- Tabla: ${exportableTables[table] ?? table}')
        ..writeln('$createSql;');

      final columns = await _tableColumns(table);
      final rows = await _db.customSelect('SELECT * FROM $table').get();
      for (final row in rows) {
        final values = columns.map((c) => _sqlLiteral(row.data[c])).join(', ');
        buffer.writeln(
            'INSERT INTO $table (${columns.join(', ')}) VALUES ($values);');
      }
    }
    return buffer.toString();
  }

  String _sqlLiteral(Object? value) {
    if (value == null) return 'NULL';
    if (value is num) return value.toString();
    if (value is bool) return value ? '1' : '0';
    if (value is Uint8List) {
      final hex = value.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      return "x'$hex'";
    }
    return "'${value.toString().replaceAll("'", "''")}'";
  }

  /// Exporta [tables] (o todas si se omite) a un libro `.xlsx`, una hoja por
  /// tabla con encabezados = nombre de columna. Igual que [exportSql], es
  /// solo de exportación — no hay flujo de import de vuelta desde Excel.
  Future<List<int>> exportXlsxBytes({List<String>? tables}) async {
    final selected = _resolveSelection(tables);
    final workbook = xlsx.Excel.createExcel();
    final defaultSheet = workbook.getDefaultSheet();
    final usedLabels = <String>{};

    for (final table in selected) {
      final label = exportableTables[table] ?? table;
      usedLabels.add(label);
      final columns = await _tableColumns(table);
      workbook.appendRow(
          label, columns.map((c) => xlsx.TextCellValue(c)).toList());

      final rows = await _db.customSelect('SELECT * FROM $table').get();
      for (final row in rows) {
        workbook.appendRow(
            label, columns.map((c) => _xlsxCell(row.data[c])).toList());
      }
    }

    // La hoja por defecto que crea Excel.createExcel() no se usó — sobraría
    // vacía en el archivo final.
    if (defaultSheet != null && !usedLabels.contains(defaultSheet)) {
      workbook.delete(defaultSheet);
    }
    return workbook.encode() ?? const <int>[];
  }

  // ─── Restauración parcial por grupo (asistente de fusión) ─────────────────

  /// Abre el `.db` elegido como base secundaria de SOLO LECTURA y compara,
  /// fila por fila (por `id`), cada tabla del [group] contra la base actual.
  /// No escribe nada — solo devuelve el diagnóstico para que la pantalla arme
  /// la lista de conflictos que el usuario debe decidir. Lanza si el grupo no
  /// es restaurable o el archivo no abre como SQLite.
  Future<List<RestoreRowDiff>> previewGroupRestore({
    required String backupPath,
    required String group,
  }) async {
    final tables = restoreGroups[group];
    if (tables == null) {
      throw ArgumentError('Grupo no restaurable: $group');
    }
    final backup = sq.sqlite3.open(backupPath, mode: sq.OpenMode.readOnly);
    try {
      final diffs = <RestoreRowDiff>[];
      for (final table in tables) {
        final cols = await _tableColumns(table);
        for (final backupRow in _readBackupRows(backup, table, cols)) {
          final id = backupRow['id'] as int;
          final current = await _db.customSelect(
              'SELECT * FROM $table WHERE id = ?',
              variables: [Variable<int>(id)]).getSingleOrNull();
          if (current == null) {
            diffs.add((
              table: table,
              id: id,
              status: RestoreRowStatus.nueva,
              currentValues: const {},
              backupValues: backupRow,
            ));
          } else {
            final currentValues = {for (final c in cols) c: current.data[c]};
            final same =
                cols.every((c) => _valuesEqual(currentValues[c], backupRow[c]));
            diffs.add((
              table: table,
              id: id,
              status:
                  same ? RestoreRowStatus.igual : RestoreRowStatus.diferente,
              currentValues: currentValues,
              backupValues: backupRow,
            ));
          }
        }
      }
      return diffs;
    } finally {
      backup.dispose();
    }
  }

  /// Aplica la restauración parcial del [group] desde [backupPath].
  ///
  /// - [replace] = true (**Reemplazar**): borra las filas actuales del grupo y
  ///   mete las del respaldo. Todo dentro de una transacción: si alguna fila
  ///   que se borra sigue referenciada desde fuera del grupo (ej. una venta
  ///   que usa un producto), la BD lanza y la transacción revierte COMPLETA —
  ///   la base queda igual que antes. [decisions] se ignora en este modo.
  /// - [replace] = false (**Agregar / fusionar**): no borra nada. Cada fila
  ///   del respaldo que no exista (por `id`) se agrega; si existe idéntica, se
  ///   mantiene; si existe distinta, se aplica [decisions] (`'tabla:id'` →
  ///   [RestoreDecision]; sin entrada = mantener la actual).
  ///
  /// [resolvedRows] (solo en modo Agregar) resuelve los conflictos de filas
  /// "diferente": mapea `'tabla:id'` → la fila FINAL de valores a escribir,
  /// ya mezclada como la quiere el usuario (puede tomar unas columnas de la
  /// base actual y otras del respaldo — fusión a nivel columna). Cada mapa
  /// debe traer TODAS las columnas de la tabla, incluida `id`. Un conflicto
  /// que no aparezca aquí se mantiene tal cual está (no se toca).
  ///
  /// Devuelve el conteo de lo que pasó, para el resumen final.
  Future<RestoreApplyResult> applyGroupRestore({
    required String backupPath,
    required String group,
    required bool replace,
    Map<String, Map<String, Object?>> resolvedRows = const {},
  }) async {
    final tables = restoreGroups[group];
    if (tables == null) {
      throw ArgumentError('Grupo no restaurable: $group');
    }
    final backup = sq.sqlite3.open(backupPath, mode: sq.OpenMode.readOnly);
    var added = 0, updated = 0, kept = 0;
    try {
      // Se lee TODO el respaldo antes de abrir la transacción de escritura —
      // así la conexión secundaria no se cruza con la transacción de drift.
      final cols = <String, List<String>>{};
      final backupData = <String, List<Map<String, Object?>>>{};
      for (final table in tables) {
        cols[table] = await _tableColumns(table);
        backupData[table] = _readBackupRows(backup, table, cols[table]!);
      }

      await _db.transaction(() async {
        if (replace) {
          // Borrado en orden INVERSO (hijos antes que padres) para no violar
          // las FK internas del grupo.
          for (final table in tables.reversed) {
            await _db.customStatement('DELETE FROM $table');
          }
          for (final table in tables) {
            for (final row in backupData[table]!) {
              await _insertRow(table, cols[table]!, row);
              added++;
            }
          }
        } else {
          for (final table in tables) {
            for (final row in backupData[table]!) {
              final id = row['id'] as int;
              final existing = await _db.customSelect(
                  'SELECT * FROM $table WHERE id = ?',
                  variables: [Variable<int>(id)]).getSingleOrNull();
              if (existing == null) {
                await _insertRow(table, cols[table]!, row);
                added++;
              } else if (cols[table]!
                  .every((c) => _valuesEqual(existing.data[c], row[c]))) {
                kept++;
              } else {
                final resolved = resolvedRows['$table:$id'];
                if (resolved != null) {
                  await _updateRow(table, cols[table]!, resolved);
                  updated++;
                } else {
                  kept++;
                }
              }
            }
          }
        }
      });
      return (added: added, updated: updated, kept: kept);
    } finally {
      backup.dispose();
    }
  }

  /// Lee todas las filas de [table] del `.db` de respaldo como mapas alineados
  /// a las [currentCols] de la base actual — si el respaldo no trae alguna
  /// columna (versión más vieja), queda como null en vez de reventar.
  List<Map<String, Object?>> _readBackupRows(
      sq.Database backup, String table, List<String> currentCols) {
    final result = backup.select('SELECT * FROM $table');
    final present = result.columnNames.toSet();
    return result
        .map((row) => {
              for (final c in currentCols)
                c: present.contains(c) ? row[c] : null
            })
        .toList();
  }

  Future<void> _insertRow(
      String table, List<String> cols, Map<String, Object?> row) async {
    final placeholders = List.filled(cols.length, '?').join(', ');
    await _db.customStatement(
      'INSERT INTO $table (${cols.join(', ')}) VALUES ($placeholders)',
      cols.map((c) => row[c]).toList(),
    );
  }

  Future<void> _updateRow(
      String table, List<String> cols, Map<String, Object?> row) async {
    final editable = cols.where((c) => c != 'id').toList();
    final assignments = editable.map((c) => '$c = ?').join(', ');
    await _db.customStatement(
      'UPDATE $table SET $assignments WHERE id = ?',
      [...editable.map((c) => row[c]), row['id']],
    );
  }

  bool _valuesEqual(Object? a, Object? b) {
    if (a is Uint8List && b is Uint8List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    }
    return a == b;
  }

  xlsx.CellValue? _xlsxCell(Object? value) {
    if (value == null) return null;
    if (value is int) return xlsx.IntCellValue(value);
    if (value is double) return xlsx.DoubleCellValue(value);
    if (value is bool) return xlsx.BoolCellValue(value);
    return xlsx.TextCellValue(value.toString());
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(databaseProvider));
});
