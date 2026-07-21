import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/services/fiscal_service.dart';
import 'package:latercia/core/utils/pricing.dart';

/// Facturación — servicio fiscal. Ver docs/facturacion.md.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('buildFiscalConceptos (pura: separación base/IVA)', () {
    test('IVA incluido: separa base e IVA hacia atrás', () {
      final cs = buildFiscalConceptos([
        (
          descripcion: 'Café',
          cantidad: 1,
          lineTotal: 116, // precio con IVA incluido
          taxRatePct: 16,
          taxIncluded: true,
          claveProdServ: '50201706',
          claveUnidad: 'H87',
          objetoImp: '02',
        ),
      ]);
      final c = cs.single;
      expect(c.base, closeTo(100, 0.001));
      expect(c.importeIva, closeTo(16, 0.001));
      expect(c.importe, closeTo(100, 0.001)); // valor sin IVA
      expect(c.tasaIva, closeTo(0.16, 0.0001)); // fracción, no porcentaje
      expect(c.base + c.importeIva, closeTo(116, 0.001)); // = lo que se paga
    });

    test('IVA añadido: el IVA se suma sobre la base', () {
      final cs = buildFiscalConceptos([
        (
          descripcion: 'Café',
          cantidad: 2,
          lineTotal: 200, // precio SIN IVA
          taxRatePct: 16,
          taxIncluded: false,
          claveProdServ: null,
          claveUnidad: null,
          objetoImp: null,
        ),
      ]);
      final c = cs.single;
      expect(c.base, closeTo(200, 0.001));
      expect(c.importeIva, closeTo(32, 0.001));
      expect(c.valorUnitario, closeTo(100, 0.001)); // 200 / 2
    });

    test('tasa 0: sin IVA', () {
      final cs = buildFiscalConceptos([
        (
          descripcion: 'Agua',
          cantidad: 1,
          lineTotal: 25,
          taxRatePct: 0,
          taxIncluded: true,
          claveProdServ: null,
          claveUnidad: null,
          objetoImp: '01',
        ),
      ]);
      final c = cs.single;
      expect(c.base, closeTo(25, 0.001));
      expect(c.importeIva, 0);
    });

    test(
        'descuento prorrateado: conceptos reconcilian con el total de la orden',
        () {
      // Dos líneas con IVA incluido y un descuento a nivel orden. El resultado
      // debe cuadrar con computeTaxedTotals (misma matemática por línea).
      final lines = <FiscalLineInput>[
        (
          descripcion: 'A',
          cantidad: 1,
          lineTotal: 116,
          taxRatePct: 16,
          taxIncluded: true,
          claveProdServ: null,
          claveUnidad: null,
          objetoImp: '02',
        ),
        (
          descripcion: 'B',
          cantidad: 1,
          lineTotal: 58,
          taxRatePct: 16,
          taxIncluded: true,
          claveProdServ: null,
          claveUnidad: null,
          objetoImp: '02',
        ),
      ];
      const descuento = 17.4; // 10% de 174
      final cs = buildFiscalConceptos(lines, descuento: descuento);

      final sumBase = cs.fold(0.0, (s, c) => s + c.base);
      final sumIva = cs.fold(0.0, (s, c) => s + c.importeIva);
      final sumDesc = cs.fold(0.0, (s, c) => s + c.descuento);

      // Referencia autoritativa: computeTaxedTotals con las mismas líneas.
      final totals = computeTaxedTotals(
        lines: const [
          TaxLine(lineTotal: 116, taxRate: 16, taxIncluded: true),
          TaxLine(lineTotal: 58, taxRate: 16, taxIncluded: true),
        ],
        discount: Discount(
          id: 1,
          name: 'x',
          type: 'fixed',
          value: descuento,
          minOrderAmount: 0,
          active: true,
          createdAt: DateTime(2026),
        ),
      );

      final sumImporte = cs.fold(0.0, (s, c) => s + c.importe);
      expect(sumIva, closeTo(totals.tax, 0.001));
      expect(sumBase + sumIva, closeTo(totals.total, 0.001));
      // Cada Base = Importe − Descuento por concepto (invariante del CFDI).
      for (final c in cs) {
        expect(c.base, closeTo(c.importe - c.descuento, 0.001));
      }
      expect(sumImporte, closeTo(sumBase + sumDesc, 0.001));
      // El Descuento del CFDI va en base SIN IVA: 17.4 con IVA ÷ 1.16 = 15.
      expect(sumDesc, closeTo(15, 0.01));
    });
  });

  group('FiscalService (contra la BD)', () {
    late AppDatabase db;
    late FiscalService svc;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      svc = FiscalService(db);
      // IVA global: 16% incluido (default de La Tercia).
      await db.settingsDao.setValue('tax_rate', '16');
      await db.settingsDao.setValue('tax_included', 'true');
      await db.settingsDao.setValue('cp_lugar_expedicion', '97000');
    });
    tearDown(() => db.close());

    Future<int> ventaPagada(String numero, double precio,
        {String? claveProdServ}) async {
      final catId = await db.categoriesDao.insertCategory(
          CategoriesCompanion.insert(name: 'c', color: '#000', icon: 'i'));
      final prodId = await db.productsDao.insertProduct(
          ProductsCompanion.insert(
              name: 'Prod $numero',
              price: precio,
              categoryId: catId,
              claveProdServ: Value(claveProdServ)));
      final empId = await db.employeesDao.insertEmployee(
          EmployeesCompanion.insert(name: 'e', pin: numero, role: 'cashier'));
      final orderId = await db.ordersDao.insertOrder(OrdersCompanion.insert(
        orderNumber: numero,
        type: 'para_llevar',
        employeeId: empId,
        subtotal: Value(precio),
        taxAmount: Value(precio - precio / 1.16),
        total: Value(precio),
        paymentStatus: const Value('pagado'),
      ));
      await db.orderItemsDao.insertOrderItems([
        OrderItemsCompanion.insert(
          orderId: orderId,
          productId: prodId,
          productName: 'Prod $numero',
          quantity: 1,
          unitPrice: precio,
        ),
      ]);
      return orderId;
    }

    test('freezeIndividual congela conceptos con las claves del producto',
        () async {
      final orderId = await ventaPagada('A-1', 116, claveProdServ: '50201706');
      final docId = await svc.freezeIndividual(
        orderId: orderId,
        receptor: (
          rfc: 'AAA010101AAA',
          razonSocial: 'ACME',
          cpFiscal: '97000',
          regimen: '601',
          usoCfdi: 'G03',
        ),
        usoCfdi: 'G03',
      );

      final doc = await (db.select(db.fiscalDocs)
            ..where((t) => t.id.equals(docId)))
          .getSingle();
      expect(doc.tipo, 'individual');
      expect(doc.receptorRfc, 'AAA010101AAA');

      final items = await (db.select(db.fiscalDocItems)
            ..where((t) => t.fiscalDocId.equals(docId)))
          .get();
      expect(items, hasLength(1));
      expect(items.first.claveProdServ, '50201706');
      expect(items.first.base, closeTo(100, 0.01));
      expect(items.first.importeIva, closeTo(16, 0.01));
    });

    test('buildGlobal consolida solo lo pagado y no facturado individualmente',
        () async {
      final o1 = await ventaPagada('G-1', 116);
      await ventaPagada('G-2', 58);
      // o1 ya tiene factura individual → NO debe entrar a la global.
      await svc.freezeIndividual(
        orderId: o1,
        receptor: (
          rfc: null,
          razonSocial: null,
          cpFiscal: null,
          regimen: null,
          usoCfdi: null
        ),
        usoCfdi: 'G03',
      );

      final docId = await svc.buildGlobal(
        desde: DateTime(2020),
        hasta: DateTime(2100),
        periodoRef: '2026-07',
      );

      final doc = await (db.select(db.fiscalDocs)
            ..where((t) => t.id.equals(docId)))
          .getSingle();
      expect(doc.tipo, 'global');
      expect(doc.receptorRfc, 'XAXX010101000');
      expect(doc.receptorCpFiscal, '97000'); // CP del emisor

      final items = await (db.select(db.fiscalDocItems)
            ..where((t) => t.fiscalDocId.equals(docId)))
          .get();
      // Solo G-2 (G-1 quedó fuera por tener factura individual).
      expect(items, hasLength(1));
      expect(items.first.descripcion, 'Prod G-2');
    });

    test('buildGlobal no itemizado: una línea por ticket, clave genérica',
        () async {
      await ventaPagada('T-1', 116);
      final docId = await svc.buildGlobal(
        desde: DateTime(2020),
        hasta: DateTime(2100),
        periodoRef: '2026-07',
        itemizado: false,
      );
      final items = await (db.select(db.fiscalDocItems)
            ..where((t) => t.fiscalDocId.equals(docId)))
          .get();
      expect(items, hasLength(1));
      expect(items.first.claveProdServ, '01010101');
      expect(items.first.claveUnidad, 'ACT');
      expect(items.first.descripcion, 'Venta T-1');
    });

    test(
        'freezeIndividual sin RFC queda "sin_datos" y completarReceptor lo '
        'deja "pendiente"', () async {
      final orderId = await ventaPagada('SD-1', 116);
      // Marca "requiere factura" pero sin datos del cliente.
      final docId = await svc.freezeIndividual(
        orderId: orderId,
        receptor: (
          rfc: null,
          razonSocial: null,
          cpFiscal: null,
          regimen: null,
          usoCfdi: null
        ),
        usoCfdi: 'G03',
      );

      var doc = await (db.select(db.fiscalDocs)
            ..where((t) => t.id.equals(docId)))
          .getSingle();
      expect(doc.estado, 'sin_datos');
      // Los conceptos SÍ quedaron congelados aunque falten los datos.
      final items = await (db.select(db.fiscalDocItems)
            ..where((t) => t.fiscalDocId.equals(docId)))
          .get();
      expect(items, hasLength(1));

      // Se completan los datos después → pendiente.
      await svc.completarReceptor(docId, (
        rfc: 'AAA010101AAA',
        razonSocial: 'ACME',
        cpFiscal: '97000',
        regimen: '601',
        usoCfdi: 'G03',
      ));
      doc = await (db.select(db.fiscalDocs)..where((t) => t.id.equals(docId)))
          .getSingle();
      expect(doc.estado, 'pendiente');
      expect(doc.receptorRfc, 'AAA010101AAA');
    });
  });
}
