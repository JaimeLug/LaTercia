import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/models/order_with_items.dart';
import 'package:latercia/core/services/checkout_service.dart';
import 'package:latercia/core/utils/pricing.dart';

/// División de cuenta por artículo: cada persona termina como una orden
/// independiente (mismo `checkout()` de siempre, con un subconjunto del
/// carrito) — valida la decisión de arquitectura de docs/division-cuenta.md.
void main() {
  late AppDatabase db;
  late CheckoutService checkout;
  late int catId;
  late int empId;
  late Product cafe;
  late Product pan;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    checkout = CheckoutService(db);
    catId = await db.categoriesDao.insertCategory(
        CategoriesCompanion.insert(name: 'c', color: '#000', icon: 'i'));
    empId = await db.employeesDao.insertEmployee(
        EmployeesCompanion.insert(name: 'e', pin: '1', role: 'cashier'));
    final cafeId = await db.productsDao.insertProduct(
        ProductsCompanion.insert(name: 'Café', price: 35, categoryId: catId));
    final panId = await db.productsDao.insertProduct(
        ProductsCompanion.insert(name: 'Pan', price: 20, categoryId: catId));
    cafe = (await db.productsDao.getProductById(cafeId))!;
    pan = (await db.productsDao.getProductById(panId))!;
  });
  tearDown(() => db.close());

  test(
      'un carrito dividido en 2 grupos produce 2 órdenes independientes, '
      'cada una con lo suyo y su propio pago', () async {
    // Simula lo que hace _checkoutGroup: computeTaxedTotals sobre el
    // subconjunto de cada persona, luego checkout() con ese subconjunto.
    final totalsCafe = computeTaxedTotals(lines: const [
      TaxLine(lineTotal: 35, taxRate: 0, taxIncluded: true),
    ]);
    final ordenCafe = await checkout.checkout(
      cartItems: [CartItem(product: cafe, quantity: 1)],
      type: 'mesa',
      employeeId: empId,
      subtotal: totalsCafe.subtotal,
      taxAmount: totalsCafe.tax,
      total: totalsCafe.total,
      paymentMethod: 'efectivo',
      amountTendered: 35,
    );

    final totalsPan = computeTaxedTotals(lines: const [
      TaxLine(lineTotal: 20, taxRate: 0, taxIncluded: true),
    ]);
    final ordenPan = await checkout.checkout(
      cartItems: [CartItem(product: pan, quantity: 1)],
      type: 'mesa',
      employeeId: empId,
      subtotal: totalsPan.subtotal,
      taxAmount: totalsPan.tax,
      total: totalsPan.total,
      paymentMethod: 'tarjeta',
      amountTendered: 20,
    );

    // Dos órdenes DISTINTAS, cada una con su folio, sus items y su pago.
    expect(ordenCafe.order.id, isNot(ordenPan.order.id));
    expect(ordenCafe.order.orderNumber, isNot(ordenPan.order.orderNumber));
    expect(ordenCafe.order.total, closeTo(35, 0.001));
    expect(ordenPan.order.total, closeTo(20, 0.001));
    expect(ordenCafe.items.single.productName, 'Café');
    expect(ordenPan.items.single.productName, 'Pan');

    final pagosCafe =
        await db.paymentsDao.getPaymentsForOrder(ordenCafe.order.id);
    final pagosPan =
        await db.paymentsDao.getPaymentsForOrder(ordenPan.order.id);
    expect(pagosCafe.single.method, 'efectivo');
    expect(pagosPan.single.method, 'tarjeta');

    // Ambas quedan pagadas y son órdenes reales del día.
    final all = await db.ordersDao.getTodayOrders();
    expect(all, hasLength(2));
    expect(all.every((o) => o.paymentStatus == 'pagado'), isTrue);
  });
}
