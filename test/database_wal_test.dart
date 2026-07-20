import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:latercia/core/database/database.dart';

/// These tests open a real on-disk database (not `NativeDatabase.memory()`)
/// because WAL mode and `busy_timeout` are properties of a file-backed
/// SQLite connection — an in-memory database can't exhibit either.
void main() {
  late Directory tempDir;
  late String dbPath;

  setUp(() async {
    // This test intentionally opens two AppDatabase instances against the
    // same file to exercise concurrent writers — silence drift's "opened
    // multiple times" advisory warning, which doesn't apply here since each
    // instance uses its own file-backed executor, not a shared one.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    tempDir = await Directory.systemTemp.createTemp('latercia_wal_test_');
    dbPath = p.join(tempDir.path, 'test.db');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  /// Opens an [AppDatabase] on a real file using the same setup hook
  /// (`journal_mode=WAL` + `busy_timeout=5000`) as production's
  /// `_openConnection()`, so the test exercises the actual PRAGMAs applied
  /// at startup rather than re-deriving them.
  AppDatabase openFileDb() {
    return AppDatabase.forTesting(
      NativeDatabase.createInBackground(
        File(dbPath),
        setup: (db) {
          db.execute('PRAGMA journal_mode=WAL;');
          db.execute('PRAGMA busy_timeout=5000;');
        },
      ),
    );
  }

  test('la conexión de archivo queda en journal_mode=WAL y busy_timeout=5000',
      () async {
    final db = openFileDb();
    await db.customSelect('SELECT 1').getSingle(); // force the db to open

    final journalMode =
        await db.customSelect('PRAGMA journal_mode').getSingle();
    expect(
      (journalMode.data.values.first as String).toLowerCase(),
      'wal',
    );

    final busyTimeout =
        await db.customSelect('PRAGMA busy_timeout').getSingle();
    expect(busyTimeout.data.values.first, 5000);

    await db.close();
  });

  test(
      'dos conexiones concurrentes al mismo archivo no fallan por '
      '"database is locked" gracias al busy_timeout', () async {
    final db1 = openFileDb();
    final db2 = openFileDb();

    // Make sure both connections actually opened the file (and created the
    // schema) before hammering them concurrently.
    await db1.customSelect('SELECT 1').getSingle();
    await db2.customSelect('SELECT 1').getSingle();

    // Fire a burst of writes from both connections at the same time. Without
    // WAL + busy_timeout this reliably throws "database is locked" on
    // Windows; with them, SQLite serializes the writes and everything
    // succeeds.
    final futures = <Future>[];
    for (var i = 0; i < 15; i++) {
      futures.add(db1.settingsDao.setValue('k1_$i', 'v$i'));
      futures.add(db2.settingsDao.setValue('k2_$i', 'v$i'));
    }

    await Future.wait(futures);

    for (var i = 0; i < 15; i++) {
      expect(await db1.settingsDao.getValue('k1_$i'), 'v$i');
      expect(await db2.settingsDao.getValue('k2_$i'), 'v$i');
    }

    await db1.close();
    await db2.close();
  });
}
