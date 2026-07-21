import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/services/fiscal_export_service.dart';
import 'package:latercia/core/services/fiscal_service.dart';

/// Exportador CFDI 4.0. Ver docs/facturacion.md §"Exportador".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FiscalService fiscal;
  late FiscalExportService exp;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    fiscal = FiscalService(db);
    exp = FiscalExportService(db);
    await db.settingsDao.setValue('tax_rate', '16');
    await db.settingsDao.setValue('tax_included', 'true');
    await db.settingsDao.setValue('rfc_emisor', 'EMI010101AAA');
    await db.settingsDao.setValue('regimen_fiscal_emisor', '621');
    await db.settingsDao.setValue('cp_lugar_expedicion', '97000');
  });
  tearDown(() => db.close());

  Future<int> ventaPagada(String numero, double precio,
      {String metodo = 'efectivo', String? clave}) async {
    final catId = await db.categoriesDao.insertCategory(
        CategoriesCompanion.insert(name: 'c', color: '#000', icon: 'i'));
    final prodId = await db.productsDao.insertProduct(ProductsCompanion.insert(
        name: 'Prod $numero',
        price: precio,
        categoryId: catId,
        claveProdServ: Value(clave),
        claveUnidad: const Value('H87'),
        objetoImp: const Value('02')));
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
          unitPrice: precio),
    ]);
    await db.paymentsDao.insertPayment(PaymentsCompanion.insert(
        orderId: orderId, method: metodo, amountTendered: precio));
    return orderId;
  }

  int col(String name) => fiscalExportHeaders.indexOf(name);

  test('exportDoc: encabezado + una fila por concepto, columnas correctas',
      () async {
    final orderId =
        await ventaPagada('A-1', 116, metodo: 'tarjeta', clave: '50201706');
    final docId = await fiscal.freezeIndividual(
      orderId: orderId,
      receptor: (
        rfc: 'AAA010101AAA',
        razonSocial: 'ACME',
        cpFiscal: '97000',
        regimen: '601',
        usoCfdi: 'G03'
      ),
      usoCfdi: 'G03',
    );

    final out = await exp.exportDoc(docId);
    expect(out.rows.first, fiscalExportHeaders); // encabezado
    expect(out.rows.length, 2); // 1 concepto
    final r = out.rows[1];

    expect(r[col('TipoDeComprobante')], 'I');
    expect(r[col('Moneda')], 'MXN');
    expect(r[col('MetodoPago')], 'PUE');
    expect(r[col('FormaPago')], '04'); // tarjeta → 04
    expect(r[col('Folio')], 'A-1');
    expect(r[col('RfcEmisor')], 'EMI010101AAA');
    expect(r[col('RfcReceptor')], 'AAA010101AAA');
    expect(r[col('UsoCFDI')], 'G03');
    expect(r[col('ClaveProdServ')], '50201706');
    expect(r[col('ClaveUnidad')], 'H87');
    expect(r[col('ObjetoImp')], '02');
    expect(r[col('Impuesto')], '002');
    expect(r[col('TipoFactor')], 'Tasa');
    expect(r[col('TasaOCuota')], '0.160000');
    expect(r[col('Base')], '100.00');
    expect(r[col('ImporteImpuesto')], '16.00');
  });

  test('efectivo mapea a FormaPago 01', () async {
    final orderId = await ventaPagada('B-1', 58, metodo: 'efectivo');
    final docId = await fiscal.freezeIndividual(
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
    final out = await exp.exportDoc(docId);
    expect(out.rows[1][col('FormaPago')], '01');
  });

  test('exportIndividualesPendientes junta las pendientes y markExported',
      () async {
    final o1 = await ventaPagada('C-1', 116, clave: 'x');
    final o2 = await ventaPagada('C-2', 58, clave: 'y');
    // Con RFC → quedan "pendiente" (exportables); sin RFC serían "sin_datos".
    const conRfc = (
      rfc: 'AAA010101AAA',
      razonSocial: 'ACME',
      cpFiscal: '97000',
      regimen: '601',
      usoCfdi: 'G03'
    );
    final d1 = await fiscal.freezeIndividual(
        orderId: o1, receptor: conRfc, usoCfdi: 'G03');
    await fiscal.freezeIndividual(
        orderId: o2, receptor: conRfc, usoCfdi: 'G03');

    final out =
        await exp.exportIndividualesPendientes(DateTime(2020), DateTime(2100));
    expect(out.docIds.length, 2);
    expect(out.rows.length, 3); // encabezado + 2 conceptos

    // Al marcar exportadas, ya no vuelven a salir como pendientes.
    await exp.markExported(out.docIds);
    final doc = await (db.select(db.fiscalDocs)..where((t) => t.id.equals(d1)))
        .getSingle();
    expect(doc.estado, 'exportada');
    expect(doc.exportedAt, isNotNull);

    final out2 =
        await exp.exportIndividualesPendientes(DateTime(2020), DateTime(2100));
    expect(out2.docIds, isEmpty);
  });

  test('las facturas "sin_datos" no se incluyen en el export de pendientes',
      () async {
    final o1 = await ventaPagada('SD-1', 116, clave: 'x');
    // Sin RFC → queda "sin_datos", no debe exportarse.
    await fiscal.freezeIndividual(
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
    final out =
        await exp.exportIndividualesPendientes(DateTime(2020), DateTime(2100));
    expect(out.docIds, isEmpty); // no hay pendientes exportables
  });

  test('global exporta con receptor público en general', () async {
    await ventaPagada('G-1', 116, clave: 'z');
    final docId = await fiscal.buildGlobal(
      desde: DateTime(2020),
      hasta: DateTime(2100),
      periodoRef: '2026-07',
    );
    final out = await exp.exportDoc(docId);
    final r = out.rows[1];
    expect(r[col('RfcReceptor')], 'XAXX010101000');
    expect(r[col('UsoCFDI')], 'S01');
    expect(r[col('Folio')], '2026-07');
    expect(r[col('FormaPago')], '01');
  });

  test('toCsv y toXlsx producen contenido', () async {
    final orderId = await ventaPagada('D-1', 116, clave: 'w');
    final docId = await fiscal.buildGlobal(
        desde: DateTime(2020), hasta: DateTime(2100), periodoRef: 'p');
    // ignore: unused_local_variable
    final _ = orderId;
    final out = await exp.exportDoc(docId);
    final csv = exp.toCsv(out.rows);
    expect(csv, contains('TipoDeComprobante'));
    expect(exp.toXlsx(out.rows), isNotEmpty);
  });
}
