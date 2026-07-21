// Convierte los CSV oficiales del SAT (tool/sat_csv/) en un único SQLite
// pre-armado e indexado: assets/sat/catalogos_sat.sqlite. El módulo de
// facturación lo abre en solo lectura para el buscador de claves.
// Ver docs/facturacion.md §"Catálogos SAT".
//
// Se corre a mano en desarrollo cuando cambian los CSV:
//   dart run tool/build_sat_catalog.dart
// El .sqlite resultante se commitea como asset (los CSV no viajan en la app).

import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Archivo CSV → nombre de tabla en el SQLite.
const _tables = <String, String>{
  'c_ClaveProdServ.csv': 'clave_prod_serv',
  'c_ClaveUnidad.csv': 'clave_unidad',
  'c_RegimenFiscal.csv': 'regimen_fiscal',
  'c_UsoCFDI.csv': 'uso_cfdi',
  'c_FormaPago.csv': 'forma_pago',
  'c_MetodoPago.csv': 'metodo_pago',
  'c_ObjetoImp.csv': 'objeto_imp',
  'c_Moneda.csv': 'moneda',
  'c_TipoDeComprobante.csv': 'tipo_comprobante',
  'claves_sugeridas_cafeteria.csv': 'cafeteria_sugeridas',
};

void main() {
  final root = Directory.current.path;
  final csvDir = Directory(p.join(root, 'tool', 'sat_csv'));
  final outFile = File(p.join(root, 'assets', 'sat', 'catalogos_sat.sqlite'));

  if (!csvDir.existsSync()) {
    stderr.writeln('No existe ${csvDir.path}');
    exit(1);
  }
  outFile.parent.createSync(recursive: true);
  if (outFile.existsSync()) outFile.deleteSync();

  final db = sqlite3.open(outFile.path);
  // Sin journal ni sync: es un build de un archivo desechable, no una BD viva.
  db.execute('PRAGMA journal_mode = OFF');
  db.execute('PRAGMA synchronous = OFF');

  const converter = CsvToListConverter(eol: '\n', shouldParseNumbers: false);
  // Los CSV del SAT vienen con saltos \r\n (Windows). Se normalizan a \n antes
  // de parsear; sin esto, las filas con campos entre comillas (ej. la lista de
  // regímenes de c_UsoCFDI) se fusionaban y se perdían miles de filas.
  String normalize(String s) =>
      s.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  var totalRows = 0;
  for (final entry in _tables.entries) {
    final file = File(p.join(csvDir.path, entry.key));
    if (!file.existsSync()) {
      stderr.writeln('  ⚠ falta ${entry.key}, se omite');
      continue;
    }
    final rows = converter.convert(normalize(file.readAsStringSync()));
    if (rows.isEmpty) continue;

    final headers = rows.first.map((h) => _sanitizeCol(h.toString())).toList();
    final table = entry.value;

    final cols = headers.map((h) => '"$h" TEXT').join(', ');
    db.execute('CREATE TABLE $table ($cols)');

    final placeholders = List.filled(headers.length, '?').join(', ');
    final stmt = db.prepare('INSERT INTO $table VALUES ($placeholders)');
    db.execute('BEGIN');
    for (final row in rows.skip(1)) {
      // Alinea la fila al número de columnas del header (por si viene corta).
      final values = List<Object?>.generate(
          headers.length, (i) => i < row.length ? row[i].toString() : '');
      stmt.execute(values);
    }
    db.execute('COMMIT');
    stmt.dispose();

    // Índice en `texto` para el buscador (las tablas del SAT lo traen).
    if (headers.contains('texto')) {
      db.execute('CREATE INDEX idx_${table}_texto ON $table(texto)');
    }

    final count = db.select('SELECT COUNT(*) c FROM $table').first['c'];
    totalRows += count as int;
    stdout.writeln('  $table: $count filas');
  }

  db.dispose();
  final sizeKb = (outFile.lengthSync() / 1024).toStringAsFixed(0);
  stdout.writeln('OK → ${outFile.path} ($sizeKb KB, $totalRows filas)');
}

/// Normaliza un nombre de columna a algo seguro para SQL (por si el CSV trae
/// espacios o mayúsculas raras). El SAT usa snake_case, así que casi siempre
/// pasa tal cual.
String _sanitizeCol(String raw) {
  final s = raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
  return s.isEmpty ? 'col' : s;
}
