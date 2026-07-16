import 'dart:async';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

enum LogLevel { info, warn, error }

/// Simple file logger with one log file per day, written to
/// `%APPDATA%/latercia/logs/latercia-YYYY-MM-DD.log`.
///
/// Kept intentionally small: no external logging package, just append-only
/// text lines flushed to disk. Never pass employee PINs (the `Employees.pin`
/// column) into a logged message or error object.
class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  static const _retentionDays = 30;

  Directory? _logDir;
  IOSink? _sink;
  String? _currentFileDate;
  Future<void> _writeQueue = Future.value();

  Future<Directory> _getLogDir() async {
    if (_logDir != null) return _logDir!;
    final appDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(appDir.path, 'latercia', 'logs'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _logDir = dir;
    return dir;
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

  /// Initializes the logger and purges log files older than
  /// [_retentionDays] days. Call once at app startup.
  Future<void> init() async {
    try {
      await purgeOldLogs();
    } catch (_) {
      // Purging is best-effort; never block startup on it.
    }
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

  Future<void> purgeOldLogs() async {
    final dir = await _getLogDir();
    final cutoff = DateTime.now().subtract(const Duration(days: _retentionDays));
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = p.basenameWithoutExtension(entity.path);
      final match = RegExp(r'^latercia-(\d{4}-\d{2}-\d{2})$').firstMatch(name);
      if (match == null) continue;
      final fileDate = DateTime.tryParse(match.group(1)!);
      if (fileDate != null && fileDate.isBefore(cutoff)) {
        try {
          await entity.delete();
        } catch (_) {
          // Ignore: a locked/missing file just stays until the next purge.
        }
      }
    }
  }

  void _write(LogLevel level, String message, [Object? error, StackTrace? stackTrace]) {
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

/// Global convenience accessor, e.g. `appLogger.warn('...')`.
final appLogger = AppLogger.instance;
