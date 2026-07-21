import 'package:csv/csv.dart';
import 'package:drift/drift.dart' show Value;
import 'package:excel/excel.dart' as xlsx;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';

/// Columnas del export (CFDI 4.0), una fila por concepto. `docs/facturacion.md`
/// §"Exportador".
const fiscalExportHeaders = <String>[
  // Comprobante
  'Fecha', 'FormaPago', 'MetodoPago', 'Moneda', 'TipoDeComprobante',
  'LugarExpedicion', 'Folio',
  // Emisor (referencia para el facturador)
  'RfcEmisor', 'RegimenFiscalEmisor',
  // Receptor
  'RfcReceptor', 'NombreReceptor', 'DomicilioFiscalReceptor',
  'RegimenFiscalReceptor', 'UsoCFDI',
  // Concepto
  'ClaveProdServ', 'NoIdentificacion', 'Cantidad', 'ClaveUnidad', 'Descripcion',
  'ValorUnitario', 'Importe', 'Descuento', 'ObjetoImp', 'Impuesto',
  'TipoFactor',
  'TasaOCuota', 'Base', 'ImporteImpuesto',
];

/// Resultado de una exportación: las filas y los documentos que abarcó (para
/// marcarlos como exportados si el usuario guarda el archivo).
typedef FiscalExport = ({List<List<String>> rows, List<int> docIds});

/// Construye el archivo de prellenado CFDI 4.0 (Excel/CSV) a partir de los
/// documentos fiscales congelados. NO timbra. `docs/facturacion.md`.
class FiscalExportService {
  FiscalExportService(this._db);

  final AppDatabase _db;

  /// `Payments.method` → `c_FormaPago`. Tarjeta → `04` por default (no se
  /// distingue crédito/débito). `docs/facturacion.md` §"Mapeos SAT".
  static const _formaPagoSat = {
    'efectivo': '01',
    'transferencia': '03',
    'tarjeta': '04',
    'otro': '99',
  };

  /// Exporta un documento fiscal (típicamente la global) a filas.
  Future<FiscalExport> exportDoc(int fiscalDocId) async {
    final settings = await _db.settingsDao.getAllSettings();
    final doc = await (_db.select(_db.fiscalDocs)
          ..where((t) => t.id.equals(fiscalDocId)))
        .getSingle();
    return (
      rows: [fiscalExportHeaders, ...await _rowsForDoc(doc, settings)],
      docIds: [doc.id],
    );
  }

  /// Exporta todas las facturas individuales **pendientes** cuyo documento se
  /// creó dentro del periodo.
  Future<FiscalExport> exportIndividualesPendientes(
      DateTime desde, DateTime hasta) async {
    final settings = await _db.settingsDao.getAllSettings();
    final docs = await (_db.select(_db.fiscalDocs)
          ..where((t) => t.tipo.equals('individual'))
          ..where((t) => t.estado.equals('pendiente')))
        .get();
    final enPeriodo = docs.where(
        (d) => !d.createdAt.isBefore(desde) && d.createdAt.isBefore(hasta));

    final rows = <List<String>>[fiscalExportHeaders];
    final ids = <int>[];
    for (final d in enPeriodo) {
      rows.addAll(await _rowsForDoc(d, settings));
      ids.add(d.id);
    }
    return (rows: rows, docIds: ids);
  }

  /// Marca los documentos como exportados (con fecha). Se llama después de que
  /// el usuario guardó el archivo, no antes.
  Future<void> markExported(List<int> docIds) async {
    for (final id in docIds) {
      await (_db.update(_db.fiscalDocs)..where((t) => t.id.equals(id))).write(
        FiscalDocsCompanion(
          estado: const Value('exportada'),
          exportedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<List<List<String>>> _rowsForDoc(
      FiscalDoc doc, Map<String, String> settings) async {
    final items = await (_db.select(_db.fiscalDocItems)
          ..where((t) => t.fiscalDocId.equals(doc.id)))
        .get();
    final comp = await _comprobante(doc, settings);
    return [
      for (final it in items) [...comp, ..._concepto(it)]
    ];
  }

  Future<List<String>> _comprobante(
      FiscalDoc doc, Map<String, String> settings) async {
    String fecha;
    String formaPago;
    String folio;
    if (doc.orderId != null) {
      final order = await _db.ordersDao.getOrderById(doc.orderId!);
      final pagos = await _db.paymentsDao.getPaymentsForOrder(doc.orderId!);
      fecha = _fecha(order?.createdAt ?? DateTime.now());
      formaPago =
          _formaPagoSat[pagos.isNotEmpty ? pagos.first.method : ''] ?? '99';
      folio = order?.orderNumber ?? '${doc.id}';
    } else {
      // Global: sin orden única. FormaPago 01 (efectivo) por default en café.
      fecha = _fecha(DateTime.now());
      formaPago = '01';
      folio = doc.periodoRef ?? 'GLOBAL-${doc.id}';
    }
    return [
      fecha,
      formaPago,
      'PUE',
      'MXN',
      'I',
      settings['cp_lugar_expedicion'] ?? '',
      folio,
      settings['rfc_emisor'] ?? '',
      settings['regimen_fiscal_emisor'] ?? '',
      doc.receptorRfc ?? '',
      doc.receptorRazonSocial ?? '',
      doc.receptorCpFiscal ?? '',
      doc.receptorRegimen ?? '',
      doc.receptorUsoCfdi ?? '',
    ];
  }

  List<String> _concepto(FiscalDocItem it) {
    final tieneIva = it.tasaIva > 0;
    return [
      it.claveProdServ ?? '',
      '', // NoIdentificacion (SKU) — opcional, no se congela aún
      _num(it.cantidad),
      it.claveUnidad ?? '',
      it.descripcion,
      _money(it.valorUnitario),
      _money(it.importe),
      _money(it.descuento),
      it.objetoImp ?? '',
      tieneIva ? '002' : '',
      tieneIva ? 'Tasa' : '',
      tieneIva ? it.tasaIva.toStringAsFixed(6) : '',
      _money(it.base),
      _money(it.importeIva),
    ];
  }

  String _fecha(DateTime d) => DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(d);
  String _money(double v) => v.toStringAsFixed(2);
  String _num(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  String toCsv(List<List<String>> rows) =>
      const ListToCsvConverter().convert(rows);

  List<int> toXlsx(List<List<String>> rows) {
    final book = xlsx.Excel.createExcel();
    const sheetName = 'CFDI';
    for (final row in rows) {
      book.appendRow(sheetName, row.map((c) => xlsx.TextCellValue(c)).toList());
    }
    final def = book.getDefaultSheet();
    if (def != null && def != sheetName) book.delete(def);
    return book.encode() ?? const <int>[];
  }
}

final fiscalExportServiceProvider = Provider<FiscalExportService>((ref) {
  return FiscalExportService(ref.watch(databaseProvider));
});
