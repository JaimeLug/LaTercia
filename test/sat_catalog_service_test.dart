import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/services/sat_catalog_service.dart';

/// Búsqueda de claves SAT sobre el asset real del catálogo. Ver
/// docs/facturacion.md §"Catálogos SAT".
///
/// Se apunta el servicio directo al `.sqlite` del repo (dbPathOverride), sin
/// pasar por rootBundle — así se prueba la lógica de búsqueda con datos reales.
void main() {
  const assetPath = 'assets/sat/catalogos_sat.sqlite';

  setUpAll(() {
    // El asset debe existir (se genera con tool/build_sat_catalog.dart).
    expect(File(assetPath).existsSync(), isTrue,
        reason: 'falta $assetPath — corre tool/build_sat_catalog.dart');
  });

  late SatCatalogService svc;
  setUp(() => svc = SatCatalogService(dbPathOverride: assetPath));
  tearDown(() => svc.dispose());

  test('busca ClaveProdServ por descripción', () async {
    final r = await svc.searchClaveProdServ('café');
    expect(r, isNotEmpty);
    // Alguna de las claves conocidas de café debe aparecer.
    expect(r.any((e) => e.id == '50201706'), isTrue);
  });

  test('busca ClaveProdServ por clave (prefijo)', () async {
    final r = await svc.searchClaveProdServ('502017');
    expect(r, isNotEmpty);
    expect(r.every((e) => e.id.startsWith('502017')), isTrue);
  });

  test('respeta el límite de resultados', () async {
    final r = await svc.searchClaveProdServ('a', limit: 5);
    expect(r.length, lessThanOrEqualTo(5));
  });

  test('query vacío no devuelve nada', () async {
    expect(await svc.searchClaveProdServ('   '), isEmpty);
  });

  test('sugeridas de cafetería trae el curado', () async {
    final r = await svc.sugeridasCafeteria();
    expect(r.length, greaterThan(10));
    expect(r.any((e) => e.texto.toLowerCase().contains('cafetería')), isTrue);
  });

  test('catálogos chicos: uso CFDI incluye G03', () async {
    final usos = await svc.usosCfdi();
    final g03 = usos.firstWhere((e) => e.id == 'G03');
    expect(g03.texto.toLowerCase(), contains('gastos'));
  });

  test('régimen fiscal incluye 601', () async {
    final reg = await svc.regimenesFiscales();
    expect(reg.any((e) => e.id == '601'), isTrue);
  });

  test('descripcionDe resuelve una clave exacta', () async {
    final d = await svc.descripcionDe('clave_unidad', 'H87');
    expect(d, isNotNull); // H87 = Pieza
  });
}
