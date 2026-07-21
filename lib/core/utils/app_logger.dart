import 'dart:async';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

enum LogLevel { info, warn, error }

/// Logger a archivo, un archivo por día, append-only. Nunca loguear PINs.
/// `docs/logs.md`.
class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  static const _retentionDays = 30;
  // Tope duro de tamaño total como red de seguridad (docs/logs.md).
  static const _maxTotalBytes = 50 * 1024 * 1024; // 50 MB

  Directory? _logDir;
  IOSink? _sink;
  String? _currentFileDate;
  Future<void> _writeQueue = Future.value();
  Timer? _purgeTimer;

  /// Solo para tests — apunta el logger a un directorio temporal en vez de la
  /// carpeta real de AppData, para poder probar `purgeOldLogs()` sin tocar
  /// datos reales del usuario. Asignar `null` vuelve al comportamiento normal.
  Future<Directory> Function()? logDirOverrideForTesting;

  Future<Directory> _getLogDir() async {
    if (_logDir != null) return _logDir!;
    // A3: logs a Documentos (para copiarlos a mano), no a la carpeta de soporte
    // donde vive la base. docs/logs.md.
    final appDir = logDirOverrideForTesting != null
        ? await logDirOverrideForTesting!()
        : await getApplicationDocumentsDirectory();
    final dir = logDirOverrideForTesting != null
        ? appDir
        : Directory(p.join(appDir.path, 'latercia', 'logs'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _logDir = dir;
    return dir;
  }

  /// Solo para tests — limpia el directorio cacheado para que el próximo
  /// `_getLogDir()` vuelva a resolver desde [logDirOverrideForTesting].
  void resetForTesting() {
    _logDir = null;
    _purgeTimer?.cancel();
    _purgeTimer = null;
  }

  String _dateStamp(DateTime t) => DateFormat('yyyy-MM-dd').format(t);

  Future<IOSink> _sinkForNow() async {
    final today = _dateStamp(DateTime.now());
    if (_sink != null && _currentFileDate == today) return _sink!;

    await _sink?.flush();
    await _sink?.close();

    final dir = await _getLogDir();
    final file = File(p.join(dir.path, 'latercia-$today.log'));
    _sink = file.openWrite(mode: FileMode.append);
    _currentFileDate = today;
    return _sink!;
  }

  /// Inicializa el logger y purga logs viejos; corre la purga al arrancar y
  /// cada 24h. Llamar una vez al inicio. `docs/logs.md`.
  Future<void> init() async {
    try {
      await purgeOldLogs();
    } catch (_) {
      // Purging is best-effort; never block startup on it.
    }
    _purgeTimer?.cancel();
    _purgeTimer = Timer.periodic(const Duration(hours: 24), (_) {
      purgeOldLogs().catchError((_) {
        // Best-effort — un fallo aquí no debe tumbar el timer futuro.
      });
    });
  }

  /// Tamaño total (bytes) de los archivos de log, para el panel de salud (5.4).
  Future<int> logsSizeBytes() async {
    try {
      final dir = await _getLogDir();
      var total = 0;
      await for (final e in dir.list()) {
        if (e is File && e.path.endsWith('.log')) {
          total += (await e.stat()).size;
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Purga por antigüedad ([_retentionDays]) y, si aún se pasa de
  /// [_maxTotalBytes], sigue borrando los más antiguos. `docs/logs.md`.
  Future<void> purgeOldLogs() async {
    final dir = await _getLogDir();
    final cutoff =
        DateTime.now().subtract(const Duration(days: _retentionDays));
    final remaining = <File, DateTime>{};

    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = p.basenameWithoutExtension(entity.path);
      final match = RegExp(r'^latercia-(\d{4}-\d{2}-\d{2})$').firstMatch(name);
      if (match == null) continue;
      final fileDate = DateTime.tryParse(match.group(1)!);
      if (fileDate == null) continue;

      if (fileDate.isBefore(cutoff)) {
        try {
          await entity.delete();
        } catch (_) {
          // Ignore: a locked/missing file just stays until the next purge.
        }
      } else {
        remaining[entity] = fileDate;
      }
    }

    // No borra el archivo del día de hoy (el sink activo sigue escribiendo
    // ahí) aunque el tope de tamaño ya se haya rebasado — ese caso queda
    // para la siguiente purga.
    final today = _dateStamp(DateTime.now());
    var total = 0;
    for (final file in remaining.keys) {
      try {
        total += (await file.stat()).size;
      } catch (_) {/* archivo pudo desaparecer entre el list() y aquí */}
    }
    if (total <= _maxTotalBytes) return;

    final oldestFirst = remaining.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    for (final entry in oldestFirst) {
      if (total <= _maxTotalBytes) break;
      if (p.basenameWithoutExtension(entry.key.path) == 'latercia-$today') {
        continue;
      }
      try {
        final size = (await entry.key.stat()).size;
        await entry.key.delete();
        total -= size;
      } catch (_) {
        // Best-effort — sigue con el siguiente archivo.
      }
    }
  }

  void _write(LogLevel level, String message,
      [Object? error, StackTrace? stackTrace]) {
    final line = StringBuffer()
      ..write(DateTime.now().toIso8601String())
      ..write(' [')
      ..write(level.name.toUpperCase())
      ..write('] ')
      ..write(message);
    if (error != null) {
      line
        ..write(' | error: ')
        ..write(error);
    }
    if (stackTrace != null) {
      line
        ..write('\n')
        ..write(stackTrace);
    }
    line.write('\n');

    // Serialize writes so concurrent log calls don't interleave partial
    // lines or race on rotating the sink at midnight.
    _writeQueue = _writeQueue.then((_) async {
      try {
        final sink = await _sinkForNow();
        sink.write(line.toString());
        await sink.flush();
      } catch (_) {
        // Logging must never throw into the caller's error path.
      }
    });
  }

  void info(String message) => _write(LogLevel.info, message);

  void warn(String message, [Object? error, StackTrace? stackTrace]) =>
      _write(LogLevel.warn, message, error, stackTrace);

  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _write(LogLevel.error, message, error, stackTrace);
}

/// Acceso global de conveniencia, p. ej. `appLogger.warn('...')`.
final appLogger = AppLogger.instance;
