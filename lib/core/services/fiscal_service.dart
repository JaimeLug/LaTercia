import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../utils/pricing.dart';

/// Datos fiscales del receptor de una factura. `docs/facturacion.md`.
typedef FiscalReceptor = ({
  String? rfc,
  String? razonSocial,
  String? cpFiscal,
  String? regimen,
  String? usoCfdi,
});

/// Línea de entrada para congelar un concepto fiscal (lo que se sabe de una
/// línea de la orden + los atributos fiscales del producto). `docs/facturacion.md`.
typedef FiscalLineInput = ({
  String descripcion,
  double cantidad,
  double lineTotal, // importe mostrado de la línea (con IVA si taxIncluded)
  double taxRatePct, // tasa efectiva en % (ej. 16)
  bool taxIncluded,
  String? claveProdServ,
  String? claveUnidad,
  String? objetoImp,
});

/// Un concepto fiscal ya calculado (base/IVA desglosados), listo para congelar
/// en [FiscalDocItems]. `docs/facturacion.md` §"Prorrateo del descuento".
class FiscalConcepto {
  const FiscalConcepto({
    required this.descripcion,
    required this.cantidad,
    required this.valorUnitario,
    required this.importe,
    required this.descuento,
    required this.base,
    required this.tasaIva,
    required this.importeIva,
    this.claveProdServ,
    this.claveUnidad,
    this.objetoImp,
  });

  final String descripcion;
  final double cantidad;
  final double valorUnitario; // sin IVA
  final double importe; // sin IVA (antes de descuento)
  final double descuento;
  final double base; // gravable (importe − descuento)
  final double tasaIva; // fracción (ej. 0.16)
  final double importeIva;
  final String? claveProdServ;
  final String? claveUnidad;
  final String? objetoImp;
}

/// Receptor de la factura global (público en general). El CP fiscal se rellena
/// al construir con el CP del emisor. `docs/facturacion.md` §"Flujo B".
const _rfcPublicoGeneral = 'XAXX010101000';

/// Calcula los conceptos fiscales de una orden, prorrateando el [descuento]
/// para que cuadren exacto con los totales de la orden. Pura (sin BD ni UI).
/// `docs/facturacion.md` §"Prorrateo del descuento".
List<FiscalConcepto> buildFiscalConceptos(
  List<FiscalLineInput> lines, {
  double descuento = 0,
}) {
  final gross = lines.fold(0.0, (s, l) => s + l.lineTotal);
  final factor = gross > 0 ? (gross - descuento) / gross : 1.0;
  return [for (final l in lines) _conceptoFor(l, factor)];
}

FiscalConcepto _conceptoFor(FiscalLineInput l, double factor) {
  final r = l.taxRatePct <= 0 ? 0.0 : l.taxRatePct;
  final net = l.taxIncluded ? l.lineTotal / (1 + r / 100) : l.lineTotal;
  final desc = net * (1 - factor);
  final base = net * factor;
  return FiscalConcepto(
    descripcion: l.descripcion,
    claveProdServ: l.claveProdServ,
    claveUnidad: l.claveUnidad,
    objetoImp: l.objetoImp,
    cantidad: l.cantidad,
    valorUnitario: l.cantidad != 0 ? net / l.cantidad : net,
    importe: net,
    descuento: desc,
    base: base,
    tasaIva: r / 100,
    importeIva: base * r / 100,
  );
}

/// Congela el snapshot fiscal de las ventas y arma los documentos fiscales
/// (individual y global). No timbra. `docs/facturacion.md`.
class FiscalService {
  FiscalService(this._db);

  final AppDatabase _db;

  /// Congela los conceptos de una orden y crea un [FiscalDocs] individual.
  /// Si el receptor no trae RFC, el documento queda en estado `sin_datos`
  /// (requiere factura pero faltan los datos del cliente; se completan después
  /// con [completarReceptor]). `docs/facturacion.md` §"Flujo A".
  Future<int> freezeIndividual({
    required int orderId,
    required FiscalReceptor receptor,
    required String usoCfdi,
  }) {
    return _db.transaction(() async {
      final order = await _db.ordersDao.getOrderById(orderId);
      if (order == null) throw StateError('La orden $orderId no existe.');
      final lines = await _linesForOrder(order);
      final conceptos =
          buildFiscalConceptos(lines, descuento: order.discountAmount);

      final estado = (receptor.rfc == null || receptor.rfc!.trim().isEmpty)
          ? 'sin_datos'
          : 'pendiente';
      final docId = await _db.into(_db.fiscalDocs).insert(
            FiscalDocsCompanion.insert(
              orderId: Value(orderId),
              tipo: 'individual',
              estado: Value(estado),
              receptorRfc: Value(receptor.rfc),
              receptorRazonSocial: Value(receptor.razonSocial),
              receptorCpFiscal: Value(receptor.cpFiscal),
              receptorRegimen: Value(receptor.regimen),
              receptorUsoCfdi: Value(usoCfdi),
            ),
          );
      await _insertConceptos(docId, conceptos);
      return docId;
    });
  }

  /// Completa (o corrige) los datos del receptor de un documento que quedó
  /// `sin_datos`, dejándolo `pendiente` (listo para exportar). No re-congela
  /// los conceptos. `docs/facturacion.md` §"Flujo A".
  Future<void> completarReceptor(
    int fiscalDocId,
    FiscalReceptor receptor,
  ) async {
    await (_db.update(_db.fiscalDocs)..where((t) => t.id.equals(fiscalDocId)))
        .write(FiscalDocsCompanion(
      estado: const Value('pendiente'),
      receptorRfc: Value(receptor.rfc),
      receptorRazonSocial: Value(receptor.razonSocial),
      receptorCpFiscal: Value(receptor.cpFiscal),
      receptorRegimen: Value(receptor.regimen),
      receptorUsoCfdi: Value(receptor.usoCfdi),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// El documento fiscal individual de una orden, si ya existe. Sirve para
  /// facturar una venta pasada desde el historial de órdenes sin duplicarla
  /// (y para saber si quedó "sin datos"). docs/facturacion.md §"Flujo A".
  Future<FiscalDoc?> individualForOrder(int orderId) async {
    final docs = await (_db.select(_db.fiscalDocs)
          ..where((t) => t.orderId.equals(orderId))
          ..where((t) => t.tipo.equals('individual')))
        .get();
    return docs.isEmpty ? null : docs.last;
  }

  /// Consolida las ventas del periodo [desde, hasta] que estén pagadas, no
  /// canceladas y **sin** factura individual, en un [FiscalDocs] global
  /// (receptor público en general). Con [itemizado] (default) hay una fila por
  /// concepto; si es false, una línea por ticket con clave genérica.
  /// `docs/facturacion.md` §"Flujo B".
  Future<int> buildGlobal({
    required DateTime desde,
    required DateTime hasta,
    required String periodoRef,
    bool itemizado = true,
  }) {
    return _db.transaction(() async {
      final settings = await _db.settingsDao.getAllSettings();
      final cpEmisor = settings['cp_lugar_expedicion'] ?? '';

      final orders = await _db.ordersDao.getOrdersByDateRange(desde, hasta);
      final yaFacturadas = await _individuallyInvoicedIds();
      final elegibles = orders.where((o) =>
          o.paymentStatus == 'pagado' &&
          o.status != 'cancelado' &&
          !yaFacturadas.contains(o.id));

      final docId = await _db.into(_db.fiscalDocs).insert(
            FiscalDocsCompanion.insert(
              tipo: 'global',
              periodoRef: Value(periodoRef),
              receptorRfc: const Value(_rfcPublicoGeneral),
              receptorRazonSocial: const Value('PUBLICO EN GENERAL'),
              receptorCpFiscal: Value(cpEmisor),
              receptorRegimen: const Value('616'),
              receptorUsoCfdi: const Value('S01'),
            ),
          );

      final conceptos = <FiscalConcepto>[];
      for (final o in elegibles) {
        if (itemizado) {
          final lines = await _linesForOrder(o);
          conceptos
              .addAll(buildFiscalConceptos(lines, descuento: o.discountAmount));
        } else {
          conceptos.add(_conceptoPorTicket(o));
        }
      }
      await _insertConceptos(docId, conceptos);
      return docId;
    });
  }

  /// Ids de órdenes que ya tienen una factura individual (para excluirlas de la
  /// global y no facturarlas dos veces).
  Future<Set<int>> _individuallyInvoicedIds() async {
    final docs = await (_db.select(_db.fiscalDocs)
          ..where((t) => t.tipo.equals('individual')))
        .get();
    return {
      for (final d in docs)
        if (d.orderId != null) d.orderId!
    };
  }

  /// Traduce las líneas activas de una orden a [FiscalLineInput], resolviendo
  /// la tasa/modo de IVA efectivos y las claves SAT del producto.
  Future<List<FiscalLineInput>> _linesForOrder(Order order) async {
    final items = await _db.orderItemsDao.getItemsForOrder(order.id);
    final settings = await _db.settingsDao.getAllSettings();
    final globalRate = double.tryParse(settings['tax_rate'] ?? '') ?? 0;
    final globalIncluded = settings['tax_included'] != 'false';

    final lines = <FiscalLineInput>[];
    for (final it in items) {
      if (it.itemStatus == 'cancelado') continue;
      final prod = await _db.productsDao.getProductById(it.productId);
      lines.add((
        descripcion: it.productName,
        cantidad: it.quantity.toDouble(),
        lineTotal: it.unitPrice * it.quantity,
        taxRatePct: effectiveTaxRate(prod?.taxRate, globalRate),
        taxIncluded: effectiveTaxIncluded(prod?.taxIncluded, globalIncluded),
        claveProdServ: prod?.claveProdServ,
        claveUnidad: prod?.claveUnidad,
        objetoImp: prod?.objetoImp,
      ));
    }
    return lines;
  }

  /// Un concepto por ticket para el modo global no itemizado (clave genérica
  /// `01010101` / unidad `ACT`). `docs/facturacion.md` §"Flujo B".
  FiscalConcepto _conceptoPorTicket(Order o) {
    final base = o.total - o.taxAmount;
    return FiscalConcepto(
      descripcion: 'Venta ${o.orderNumber}',
      claveProdServ: '01010101',
      claveUnidad: 'ACT',
      objetoImp: o.taxAmount > 0 ? '02' : '01',
      cantidad: 1,
      valorUnitario: base,
      importe: base,
      descuento: 0,
      base: base,
      tasaIva: base > 0 ? o.taxAmount / base : 0,
      importeIva: o.taxAmount,
    );
  }

  Future<void> _insertConceptos(int docId, List<FiscalConcepto> cs) async {
    for (final c in cs) {
      await _db.into(_db.fiscalDocItems).insert(
            FiscalDocItemsCompanion.insert(
              fiscalDocId: docId,
              claveProdServ: Value(c.claveProdServ),
              claveUnidad: Value(c.claveUnidad),
              descripcion: c.descripcion,
              cantidad: c.cantidad,
              valorUnitario: c.valorUnitario,
              importe: c.importe,
              descuento: Value(c.descuento),
              objetoImp: Value(c.objetoImp),
              base: c.base,
              tasaIva: Value(c.tasaIva),
              importeIva: Value(c.importeIva),
            ),
          );
    }
  }
}

final fiscalServiceProvider = Provider<FiscalService>((ref) {
  return FiscalService(ref.watch(databaseProvider));
});
