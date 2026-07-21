import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/models/order_with_items.dart';
import 'package:latercia/core/services/checkout_service.dart';
import 'package:latercia/core/services/fiscal_export_service.dart';
import 'package:latercia/core/services/fiscal_service.dart';

/// Flujo A de punta a punta: cobrar una venta, congelar su factura individual,
/// y exportarla como prellenado CFDI. Ver docs/facturacion.md §"Flujo A".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cobrar → freezeIndividual → exportar reconcilia con el total',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.settingsDao.setValue('tax_rate', '16');
    await db.settingsDao.setValue('tax_included', 'true');
    await db.settingsDao.setValue('rfc_emisor', 'EMI010101AAA');
    await db.settingsDao.setValue('cp_lugar_expedicion', '97000');

    // Catálogo mínimo de productos y un cajero.
    final catId = await db.categoriesDao.insertCategory(
        CategoriesCompanion.insert(name: 'Bebidas', color: '#000', icon: 'c'));
    final prod = await db.productsDao.insertProduct(ProductsCompanion.insert(
      name: 'Café',
      price: 58,
      categoryId: catId,
      claveProdServ: const Value('50201706'),
      claveUnidad: const Value('H87'),
      objetoImp: const Value('02'),
    ));
    final emp = await db.employeesDao.insertEmployee(
        EmployeesCompanion.insert(name: 'Caja', pin: '1234', role: 'cashier'));
    final product = await (db.select(db.products)
          ..where((t) => t.id.equals(prod)))
        .getSingle();

    // 1) Cobrar la venta (2 cafés = 116, IVA incluido).
    final checkout = CheckoutService(db);
    final order = await checkout.checkout(
      cartItems: [CartItem(product: product, quantity: 2)],
      type: 'para_llevar',
      employeeId: emp,
      subtotal: 116,
      taxAmount: 116 - 116 / 1.16,
      total: 116,
      paymentMethod: 'tarjeta',
      amountTendered: 116,
    );

    // 2) El cliente pidió factura → congelar.
    final fiscal = FiscalService(db);
    final docId = await fiscal.freezeIndividual(
      orderId: order.order.id,
      receptor: (
        rfc: 'AAA010101AAA',
        razonSocial: 'ACME SA',
        cpFiscal: '97000',
        regimen: '601',
        usoCfdi: 'G03',
      ),
      usoCfdi: 'G03',
    );

    // 3) Aparece como individual pendiente y se exporta.
    final exp = FiscalExportService(db);
    final out =
        await exp.exportIndividualesPendientes(DateTime(2020), DateTime(2100));
    expect(out.docIds, contains(docId));

    int col(String n) => fiscalExportHeaders.indexOf(n);
    // La fila del concepto reconcilia: Base + IVA = total pagado.
    final r = out.rows[1];
    final base = double.parse(r[col('Base')]);
    final iva = double.parse(r[col('ImporteImpuesto')]);
    expect(base + iva, closeTo(116, 0.01));
    expect(r[col('FormaPago')], '04'); // tarjeta
    expect(r[col('RfcReceptor')], 'AAA010101AAA');

    // 4) Marcar exportada la saca de pendientes.
    await exp.markExported(out.docIds);
    final out2 =
        await exp.exportIndividualesPendientes(DateTime(2020), DateTime(2100));
    expect(out2.docIds, isNot(contains(docId)));
  });
}
