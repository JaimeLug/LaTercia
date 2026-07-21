import 'package:drift/native.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/providers/database_provider.dart';
import 'package:latercia/features/admin/screens/settings_screen.dart';

/// Auditoría 2026-07-20 (reporte en sitio): al presionar "Guardar cambios" en
/// cualquier categoría de Configuración, la pantalla parecía "revertirse" —
/// los switches recién activados se veían apagados de nuevo. Causa real
/// (ver comentarios en settings_screen.dart):
///   1) El ColorPicker ponía `_loaded = false` en cada cambio de color,
///      forzando una recarga inmediata desde la base ANTES de guardar nada
///      — el color elegido se revertía al instante.
///   2) `_save()` también ponía `_loaded = false`; combinado con el
///      `AsyncLoading` que dispara `invalidateSelf()`, la pantalla completa
///      se reemplazaba por un spinner un instante — se sentía como que
///      "Guardar" borraba todo, aunque los datos sí quedaban persistidos.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'activar un switch y guardar lo deja activo (no revierte ni parpadea)',
      (tester) async {
    await pumpSettings(tester);

    // Landing de categorías → entra a "Impresión y gaveta".
    await tester.tap(find.text('Impresión y gaveta'));
    await tester.pumpAndSettle();

    // El switch de impresión arranca OFF (default de fábrica).
    var tile = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Activar impresión de tickets'),
    );
    expect(tile.value, isFalse);

    // Lo activa.
    await tester.tap(
        find.widgetWithText(SwitchListTile, 'Activar impresión de tickets'));
    await tester.pumpAndSettle();

    tile = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Activar impresión de tickets'),
    );
    expect(tile.value, isTrue,
        reason: 'el switch debe quedar activado antes de guardar');

    // Guarda (el botón puede quedar fuera del viewport del test; hay que
    // desplazarlo a la vista antes de tocarlo).
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    // No debe haber quedado ningún spinner de pantalla completa tapando todo.
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // El switch DEBE seguir activo en pantalla — el bug lo apagaba.
    tile = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Activar impresión de tickets'),
    );
    expect(tile.value, isTrue,
        reason: 'tras Guardar, el switch no debe revertirse');

    // Y debe haber quedado persistido de verdad en la base.
    final saved = await db.settingsDao.getValue('impresion_activa');
    expect(saved, 'true');
  });

  testWidgets('elegir un color no lo revierte antes de guardar',
      (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Apariencia'));
    await tester.pumpAndSettle();

    // Dispara onColorChanged directamente en el primer ColorPicker (color
    // primario) — arrastrar en el canvas real del picker no es practicable
    // en un widget test; esto ejercita el mismo callback que usaría el
    // usuario al elegir un color.
    final primaryPicker =
        tester.widget<ColorPicker>(find.byType(ColorPicker).first);
    primaryPicker.onColorChanged(const Color(0xFF123456));
    await tester.pumpAndSettle();

    final after = tester.widget<ColorPicker>(find.byType(ColorPicker).first);
    expect(after.color, const Color(0xFF123456),
        reason: 'el color elegido no debe revertirse antes de guardar');
  });

  // Feedback en vivo 2026-07-20: "Buscar impresoras" respondía tan rápido
  // (EnumPrinters es síncrono) que un resultado vacío se sentía como que el
  // mensaje "No se detectó ninguna impresora" ya estaba ahí de antes, no
  // como el resultado de la búsqueda recién pedida.
  testWidgets('buscar impresoras muestra "Buscando…" mientras resuelve',
      (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Impresión y gaveta'));
    await tester.pumpAndSettle();

    // El picker de Windows solo aparece con transporte USB (con Red, se ve
    // un campo de IP en su lugar).
    await tester.tap(find.text('Red (socket 9100)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USB / impresora local').last);
    await tester.pumpAndSettle();

    expect(find.text('Buscando impresoras…'), findsNothing);

    await tester.tap(find.byTooltip('Buscar impresoras'));
    await tester.pump(); // primer frame tras el tap: ya debe mostrarse.

    expect(find.text('Buscando impresoras…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Buscando impresoras…'), findsNothing);
  });
}
