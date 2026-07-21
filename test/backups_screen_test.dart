import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/providers/database_provider.dart';
import 'package:latercia/core/services/backup_service.dart';
import 'package:latercia/features/admin/screens/backups_screen.dart';
import 'package:path/path.dart' as p;

/// No se ejercen los botones "Exportar .sql"/".xlsx" ni "Descargar"/
/// "Restaurar backup" aquí: todos disparan `FilePicker.platform`, que no
/// tiene canal de plataforma en widget tests (ver `backup_service_test.dart`
/// para la lógica pura de exportación, ya cubierta ahí). Esta pantalla se
/// cubre hasta donde el flujo no toca ese plugin: selección de tablas,
/// habilitar/deshabilitar botones, "Respaldar ahora" y guardar el toggle de
/// backup automático.
void main() {
  late Directory tempBase;
  late AppDatabase db;
  late BackupService backup;

  setUp(() async {
    tempBase =
        await Directory.systemTemp.createTemp('latercia_backups_screen_test');
    final dbDirTemp = Directory(p.join(tempBase.path, 'docs'));
    await dbDirTemp.create(recursive: true);
    db = AppDatabase.forTesting(
        NativeDatabase(File(p.join(dbDirTemp.path, 'latercia.sqlite'))));
    await db.settingsDao.getAllSettings(); // fuerza la creación del archivo
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

  // El historial (y "Respaldar ahora"/el switch de auto-backup) hacen I/O
  // real de archivos. `runAsync` solo deja avanzar en tiempo real el código
  // QUE CORRE dentro de su propio callback — un delay real después de que la
  // pantalla ya se construyó no basta, porque el I/O real que arrancó en
  // `initState()` (o dentro de un `tap()` normal) queda pendiente en el zone
  // "fake async" de `testWidgets` y ahí nunca se completa: el
  // CircularProgressIndicator del historial (indeterminado, repeat()
  // infinito) se queda pegado y cualquier pumpAndSettle() posterior cuelga
  // para siempre (confirmado con un test de diagnóstico). Por eso el propio
  // `pumpWidget`/`tap` que dispara el I/O va DENTRO de `runAsync`.
  Future<void> pumpBackups(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            backupServiceProvider.overrideWithValue(backup),
          ],
          child: const MaterialApp(home: BackupsScreen()),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
  }

  /// Invoca [callback] (el `onPressed`/`onChanged` ya resuelto del widget, NO
  /// `tester.tap()`) y deja avanzar el I/O real que dispare antes de que el
  /// test siga revisando el árbol. `tester.tap()` DENTRO de `runAsync` cuelga
  /// de verdad (probado: revienta el test completo con `TimeoutException` a
  /// los 10 minutos) — `tap()` espera el ciclo normal de frames de
  /// `testWidgets`, que `runAsync` no provee. Llamar el callback directo
  /// evita esa maquinaria y sigue arrancando el I/O real dentro del zone real.
  Future<void> invokeAndSettle(
      WidgetTester tester, VoidCallback callback) async {
    await tester.runAsync(() async {
      callback();
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pump();
  }

  /// `OutlinedButton.icon(...)` devuelve una subclase privada
  /// (`_OutlinedButtonWithIcon`) — `find.byType(OutlinedButton)` NO la
  /// encuentra porque compara tipo exacto, no `is`. Se necesita un predicado.
  Finder outlinedButtonWith(Finder label) => find.ancestor(
        of: label,
        matching: find.byWidgetPredicate((w) => w is OutlinedButton),
      );

  testWidgets('arranca con todas las tablas seleccionadas', (tester) async {
    await pumpBackups(tester);

    expect(
      find.text('${BackupService.exportableTables.length} de '
          '${BackupService.exportableTables.length} tablas seleccionadas'),
      findsOneWidget,
    );
  });

  testWidgets('el panel de restauración parcial ofrece los grupos seguros',
      (tester) async {
    await pumpBackups(tester);

    expect(find.text('Restaurar solo una parte'), findsOneWidget);

    // Se inspeccionan los items del desplegable directamente (abrir el menú
    // con tap es frágil cuando el panel queda parcialmente fuera del viewport
    // de 800x600 del test). Los valores deben ser exactamente los grupos
    // seguros de restoreGroups — nunca "Operación" ni "Sistema".
    // DropdownButtonFormField no expone `items`; internamente construye un
    // DropdownButton<String> que sí.
    final dropdown = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>),
    );
    final values = dropdown.items!.map((i) => i.value).toSet();
    expect(values, BackupService.restoreGroups.keys.toSet());
    expect(values, contains('Clientes'));
    expect(values, isNot(contains('Operación')));
    expect(values, isNot(contains('Sistema')));
  });

  testWidgets('desmarcar una tabla actualiza el contador', (tester) async {
    await pumpBackups(tester);

    final chip = find.widgetWithText(FilterChip, 'Productos');
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();

    final total = BackupService.exportableTables.length;
    expect(find.text('${total - 1} de $total tablas seleccionadas'),
        findsOneWidget);
  });

  testWidgets('"Ninguno" deshabilita los botones de exportar', (tester) async {
    await pumpBackups(tester);

    final ninguno = find.text('Ninguno');
    await tester.ensureVisible(ninguno);
    await tester.pumpAndSettle();
    await tester.tap(ninguno);
    await tester.pumpAndSettle();

    expect(
        find.text(
            '0 de ${BackupService.exportableTables.length} tablas seleccionadas'),
        findsOneWidget);

    final exportSql = find.text('Exportar .sql');
    await tester.ensureVisible(exportSql);
    await tester.pumpAndSettle();
    final sqlButton =
        tester.widget<OutlinedButton>(outlinedButtonWith(exportSql));
    expect(sqlButton.onPressed, isNull);
  });

  testWidgets('"Seleccionar todo" vuelve a marcar todas', (tester) async {
    await pumpBackups(tester);

    final ninguno = find.text('Ninguno');
    await tester.ensureVisible(ninguno);
    await tester.pumpAndSettle();
    await tester.tap(ninguno);
    await tester.pumpAndSettle();

    final todo = find.text('Seleccionar todo');
    await tester.ensureVisible(todo);
    await tester.pumpAndSettle();
    await tester.tap(todo);
    await tester.pumpAndSettle();

    final total = BackupService.exportableTables.length;
    expect(find.text('$total de $total tablas seleccionadas'), findsOneWidget);
  });

  // No se invoca el botón de verdad aquí: `_backupNow` mezcla un
  // `PRAGMA wal_checkpoint` con un `setState`/`ScaffoldMessenger.showSnackBar`
  // sobre el MISMO `db` que Riverpod usa para reconstruir `settingsProvider`
  // — invocado dentro de `runAsync` (necesario para que el checkpoint real
  // avance, ver comentario de [invokeAndSettle]) produce un interbloqueo real
  // de 10 minutos: el checkpoint espera un lector que quedó pendiente en el
  // zone "fake async" de fuera de `runAsync`, que a su vez nunca se libera
  // porque ese zone no avanza mientras `runAsync` tiene el control.
  // `backupNow()`/`listBackups()` en sí ya están cubiertos a fondo en
  // `backup_service_test.dart`; aquí solo se confirma que el botón esté
  // conectado a un callback real.
  testWidgets('"Respaldar ahora" está conectado y habilitado', (tester) async {
    await pumpBackups(tester);

    expect(find.text('Aún no hay respaldos locales.'), findsOneWidget);

    final backupNow = find.text('Respaldar ahora');
    await tester.ensureVisible(backupNow);
    await tester.pumpAndSettle();
    final button = tester.widget<OutlinedButton>(outlinedButtonWith(backupNow));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('activar backup automático y guardar lo persiste',
      (tester) async {
    await pumpBackups(tester);

    // Arranca ON por default (backup_auto no está seteado aún).
    var tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(tile.value, isTrue);

    await invokeAndSettle(tester, () => tile.onChanged!(false));

    tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(tile.value, isFalse);

    final saved = await db.settingsDao.getValue('backup_auto');
    expect(saved, 'false');
  });
}
