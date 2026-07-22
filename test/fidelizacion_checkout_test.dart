import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/models/order_with_items.dart';
import 'package:latercia/core/services/checkout_service.dart';

/// Fidelización de punta a punta: un cobro real gana sellos/puntos, y con
/// redeemLoyalty:true los consume. Ver docs/fidelizacion.md.
void main() {
  late AppDatabase db;
  late CheckoutService checkout;
  late int catId;
  late int empId;
  late int customerId;
  late Product cafe;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    checkout = CheckoutService(db);
    catId = await db.categoriesDao.insertCategory(
        CategoriesCompanion.insert(name: 'Bebidas', color: '#000', icon: 'i'));
    empId = await db.employeesDao.insertEmployee(
        EmployeesCompanion.insert(name: 'e', pin: '1', role: 'cashier'));
    customerId = await db.customersDao
        .insertCustomer(CustomersCompanion.insert(name: 'Ana'));
    final productId = await db.productsDao.insertProduct(
        ProductsCompanion.insert(name: 'Café', price: 35, categoryId: catId));
    cafe = (await db.productsDao.getProductById(productId))!;
  });
  tearDown(() => db.close());

  test('un cobro con cliente vinculado gana un sello (además de la visita)',
      () async {
    await db.settingsDao.setValue('loyalty_type', 'sellos');

    await checkout.checkout(
      cartItems: [CartItem(product: cafe, quantity: 1)],
      type: 'para_llevar',
      employeeId: empId,
      customerId: customerId,
      total: 35,
      paymentMethod: 'efectivo',
      amountTendered: 35,
    );

    final c = (await db.customersDao.getAllCustomers()).single;
    expect(c.loyaltyStamps, 1);
    expect(c.visits, 1); // incrementVisits sigue funcionando igual que antes
  });

  test('redeemLoyalty:true consume la recompensa en el mismo cobro', () async {
    await db.settingsDao.setValue('loyalty_type', 'sellos');
    // Cliente ya trae 9 sellos; esta compra los completa a 10 y se canjea de
    // una vez (igual que lo haría el POS con el pill "Recompensa aplicada").
    for (var i = 0; i < 9; i++) {
      await db.customersDao.earnLoyalty(customerId, 35);
    }
    expect((await db.customersDao.getAllCustomers()).single.loyaltyStamps, 9);

    await checkout.checkout(
      cartItems: [CartItem(product: cafe, quantity: 1)],
      type: 'para_llevar',
      employeeId: empId,
      customerId: customerId,
      total: 35,
      paymentMethod: 'efectivo',
      amountTendered: 35,
      redeemLoyalty: true,
    );

    final c = (await db.customersDao.getAllCustomers()).single;
    // Ganó el sello #10 de ESTA compra y de inmediato se canjeó → vuelve a 0.
    expect(c.loyaltyStamps, 0);
  });

  test('sin redeemLoyalty, los sellos NO se resetean aunque alcancen el umbral',
      () async {
    await db.settingsDao.setValue('loyalty_type', 'sellos');
    for (var i = 0; i < 10; i++) {
      await db.customersDao.earnLoyalty(customerId, 35);
    }

    await checkout.checkout(
      cartItems: [CartItem(product: cafe, quantity: 1)],
      type: 'para_llevar',
      employeeId: empId,
      customerId: customerId,
      total: 35,
      paymentMethod: 'efectivo',
      amountTendered: 35,
      // redeemLoyalty por default es false.
    );

    final c = (await db.customersDao.getAllCustomers()).single;
    expect(c.loyaltyStamps, 11); // sigue sumando, no se quema
  });

  test('sin customerId (venta anónima): no gana ni cuenta visitas', () async {
    await db.settingsDao.setValue('loyalty_type', 'sellos');

    await checkout.checkout(
      cartItems: [CartItem(product: cafe, quantity: 1)],
      type: 'para_llevar',
      employeeId: empId,
      total: 35,
      paymentMethod: 'efectivo',
      amountTendered: 35,
    );

    final c = (await db.customersDao.getAllCustomers()).single;
    expect(c.loyaltyStamps, 0);
    expect(c.visits, 0);
  });
}
