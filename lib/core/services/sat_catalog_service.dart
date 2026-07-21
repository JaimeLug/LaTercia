import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sq;

import '../utils/app_logger.dart';

/// Una entrada de catálogo SAT: la clave y su descripción.
typedef SatEntry = ({String id, String texto});

const _assetPath = 'assets/sat/catalogos_sat.sqlite';

/// Bump this cuando cambie el asset del catálogo (regenerado con
/// `tool/build_sat_catalog.dart`) para forzar la re-copia a la carpeta de la app.
const _catalogVersion = 1;

/// Búsqueda de claves SAT sobre el catálogo local (asset SQLite, solo lectura).
/// `docs/facturacion.md` §"Catálogos SAT".
class SatCatalogService {
  /// [dbPathOverride] apunta el servicio a un `.sqlite` ya en disco (tests),
  /// saltándose la copia desde el asset.
  SatCatalogService({String? dbPathOverride})
      : _dbPathOverride = dbPathOverride;

  final String? _dbPathOverride;
  sq.Database? _db;

  Future<sq.Database> _open() async {
    if (_db != null) return _db!;
    final path = _dbPathOverride ?? await _ensureCopied();
    return _db = sq.sqlite3.open(path, mode: sq.OpenMode.readOnly);
  }

  /// Los assets no tienen ruta de archivo; sqlite3 necesita una. Se copia el
  /// asset a la carpeta de soporte de la app una vez (o cuando cambia la
  /// versión). `docs/facturacion.md`.
  Future<String> _ensureCopied() async {
    final dir = await getApplicationSupportDirectory();
    final dest = File(p.join(dir.path, 'catalogos_sat.sqlite'));
    final marker = File(p.join(dir.path, 'catalogos_sat.version'));

    final upToDate = await dest.exists() &&
        await marker.exists() &&
        (await marker.readAsString()).trim() == '$_catalogVersion';
    if (!upToDate) {
      final bytes = await rootBundle.load(_assetPath);
      await dest.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      await marker.writeAsString('$_catalogVersion');
      appLogger.info('Catálogo SAT copiado (v$_catalogVersion).');
    }
    return dest.path;
  }

  Future<List<SatEntry>> _search(String table, String query,
      {int limit = 30}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final db = await _open();
    // Coincidencia por descripción (subcadena) o por clave (prefijo).
    final rows = db.select(
      'SELECT id, texto FROM $table WHERE texto LIKE ? OR id LIKE ? LIMIT ?',
      ['%$q%', '$q%', limit],
    );
    return [
      for (final r in rows) (id: r['id'] as String, texto: r['texto'] as String)
    ];
  }

  Future<List<SatEntry>> searchClaveProdServ(String query, {int limit = 30}) =>
      _search('clave_prod_serv', query, limit: limit);

  Future<List<SatEntry>> searchClaveUnidad(String query, {int limit = 30}) =>
      _search('clave_unidad', query, limit: limit);

  /// Claves de producto/servicio sugeridas para cafetería (acceso rápido).
  Future<List<SatEntry>> sugeridasCafeteria() async {
    final db = await _open();
    final rows =
        db.select('SELECT id, texto FROM cafeteria_sugeridas ORDER BY rowid');
    return [
      for (final r in rows) (id: r['id'] as String, texto: r['texto'] as String)
    ];
  }

  /// Catálogo chico completo (régimen fiscal, uso CFDI, etc.) para un selector.
  Future<List<SatEntry>> lista(String table) async {
    final db = await _open();
    final rows = db.select('SELECT id, texto FROM $table ORDER BY id');
    return [
      for (final r in rows) (id: r['id'] as String, texto: r['texto'] as String)
    ];
  }

  Future<List<SatEntry>> regimenesFiscales() => lista('regimen_fiscal');
  Future<List<SatEntry>> usosCfdi() => lista('uso_cfdi');
  Future<List<SatEntry>> objetosImp() => lista('objeto_imp');

  /// Descripción de una clave exacta (para mostrar lo ya guardado en un
  /// producto/cliente sin re-buscar). Null si no existe.
  Future<String?> descripcionDe(String table, String id) async {
    if (id.trim().isEmpty) return null;
    final db = await _open();
    final rows =
        db.select('SELECT texto FROM $table WHERE id = ? LIMIT 1', [id.trim()]);
    return rows.isEmpty ? null : rows.first['texto'] as String;
  }

  void dispose() {
    _db?.dispose();
    _db = null;
  }
}

final satCatalogServiceProvider = Provider<SatCatalogService>((ref) {
  final svc = SatCatalogService();
  ref.onDispose(svc.dispose);
  return svc;
});
