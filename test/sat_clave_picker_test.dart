import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/services/sat_catalog_service.dart';
import 'package:latercia/features/admin/widgets/sat_clave_picker.dart';

/// Buscador de claves SAT (widget). Ver docs/facturacion.md.
void main() {
  // Servicio apuntado al asset real del repo (sin rootBundle).
  final cat =
      SatCatalogService(dbPathOverride: 'assets/sat/catalogos_sat.sqlite');
  tearDownAll(() => cat.dispose());

  testWidgets(
      'muestra sugeridas al abrir, busca al teclear y devuelve la clave',
      (tester) async {
    SatEntry? elegida;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              elegida = await showSatClavePicker(
                context,
                titulo: 'Clave producto/servicio',
                search: cat.searchClaveProdServ,
                sugeridas: cat.sugeridasCafeteria,
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    // Al abrir con sugeridas, aparece el encabezado y algún curado.
    expect(find.text('Sugeridas para cafetería'), findsOneWidget);

    // Teclear dispara la búsqueda (tras el debounce de 300 ms).
    await tester.enterText(find.byType(TextField), 'café');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Aparece la clave conocida de café; tocarla la devuelve y cierra.
    final tile = find.text('50201706');
    expect(tile, findsWidgets);
    await tester.tap(tile.first);
    await tester.pumpAndSettle();

    expect(elegida, isNotNull);
    expect(elegida!.id, '50201706');
  });

  testWidgets('cancelar devuelve null', (tester) async {
    SatEntry? elegida = (id: 'x', texto: 'x');

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              elegida = await showSatClavePicker(
                context,
                titulo: 'Clave unidad',
                search: cat.searchClaveUnidad,
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(elegida, isNull);
  });
}
