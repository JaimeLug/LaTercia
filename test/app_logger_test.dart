import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/utils/app_logger.dart';
import 'package:path/path.dart' as p;

/// Auditoría 2026-07-17 — antes la purga de logs corría solo una vez al
/// arrancar y no tenía tope de tamaño total. Estos tests cubren
/// `purgeOldLogs()` directamente (vía [AppLogger.logDirOverrideForTesting],
/// para no tocar la carpeta real de AppData del usuario).
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('latercia_logger_test');
    appLogger.logDirOverrideForTesting = () async => tempDir;
    appLogger.resetForTesting();
  });

  tearDown(() async {
    appLogger.logDirOverrideForTesting = null;
    appLogger.resetForTesting();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  Future<File> writeLog(String dateStamp, {int bytes = 100}) async {
    final file = File(p.join(tempDir.path, 'latercia-$dateStamp.log'));
    await file.writeAsBytes(List.filled(bytes, 0x41));
    return file;
  }

  String stamp(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  test('borra logs más viejos que 30 días y conserva los recientes',
      () async {
    final now = DateTime.now();
    final old = await writeLog(stamp(now.subtract(const Duration(days: 45))));
    final recent =
        await writeLog(stamp(now.subtract(const Duration(days: 5))));

    await appLogger.purgeOldLogs();

    expect(await old.exists(), isFalse);
    expect(await recent.exists(), isTrue);
  });

  test('ignora archivos que no siguen el patrón latercia-YYYY-MM-DD.log',
      () async {
    final other = File(p.join(tempDir.path, 'otro-archivo.txt'));
    await other.writeAsString('no tocar');

    await appLogger.purgeOldLogs();

    expect(await other.exists(), isTrue);
  });

  test('si el total supera el tope de 50MB, borra los más antiguos primero '
      'hasta quedar debajo', () async {
    final now = DateTime.now();
    const chunk = 20 * 1024 * 1024; // 20MB por archivo, 3 archivos = 60MB
    final day1 = await writeLog(stamp(now.subtract(const Duration(days: 3))),
        bytes: chunk);
    final day2 = await writeLog(stamp(now.subtract(const Duration(days: 2))),
        bytes: chunk);
    final day3 = await writeLog(stamp(now.subtract(const Duration(days: 1))),
        bytes: chunk);

    await appLogger.purgeOldLogs();

    // El más viejo (day1) debe haberse borrado para bajar del tope de 50MB;
    // los dos más recientes (40MB) caben.
    expect(await day1.exists(), isFalse,
        reason: 'el más antiguo se poda primero por tamaño');
    expect(await day2.exists(), isTrue);
    expect(await day3.exists(), isTrue);
  });

  test('el archivo de hoy nunca se borra por el tope de tamaño, aunque '
      'sea el único y ya lo rebase', () async {
    final today = stamp(DateTime.now());
    final file = await writeLog(today, bytes: 60 * 1024 * 1024); // 60MB

    await appLogger.purgeOldLogs();

    expect(await file.exists(), isTrue,
        reason: 'el sink activo sigue escribiendo en el archivo de hoy');
  });

  test('logsSizeBytes suma solo los .log del directorio', () async {
    await writeLog(stamp(DateTime.now()), bytes: 1000);
    await File(p.join(tempDir.path, 'no-es-log.txt')).writeAsBytes(
        List.filled(5000, 0));

    final total = await appLogger.logsSizeBytes();

    expect(total, 1000);
  });
}
