import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';

/// CustomersDao.earnLoyalty / redeemLoyalty — sellos y puntos son mecánicas
/// INDEPENDIENTES (ambas pueden estar activas a la vez) y los puntos se
/// ganan por PRODUCTO (Products.loyaltyPointsValue), no por monto gastado.
/// docs/fidelizacion.md.
void main() {
  late AppDatabase db;
  late int customerId;
  late int catId;
  late int productId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    customerId = await db.customersDao
        .insertCustomer(CustomersCompanion.insert(name: 'Ana'));
    catId = await db.categoriesDao.insertCategory(
        CategoriesCompanion.insert(name: 'Bebidas', color: '#000', icon: 'i'));
    productId = await db.productsDao.insertProduct(
        ProductsCompanion.insert(name: 'Café', price: 35, categoryId: catId));
  });
  tearDown(() => db.close());

  group('earnLoyalty', () {
    test('con ambas mecánicas desactivadas: no suma nada', () async {
      await db.customersDao
          .earnLoyalty(customerId, [(productId: productId, quantity: 1)]);
      final c = await db.customersDao.getAllCustomers();
      expect(c.single.loyaltyStamps, 0);
      expect(c.single.loyaltyPoints, 0);
    });

    test('sellos: +1 por cada venta, sin importar cuántos artículos', () async {
      await db.settingsDao.setValue('loyalty_sellos_activo', 'true');
      await db.customersDao
          .earnLoyalty(customerId, [(productId: productId, quantity: 1)]);
      await db.customersDao
          .earnLoyalty(customerId, [(productId: productId, quantity: 5)]);
      final c = await db.customersDao.getAllCustomers();
      expect(c.single.loyaltyStamps, 2);
    });

    test('puntos: gana loyaltyPointsValue × cantidad', () async {
      await db.settingsDao.setValue('loyalty_puntos_activo', 'true');
      await db.productsDao.updateLoyaltyPointsValue(productId, 3);
      await db.customersDao
          .earnLoyalty(customerId, [(productId: productId, quantity: 4)]);
      final c = await db.customersDao.getAllCustomers();
      expect(c.single.loyaltyPoints, 12);
    });

    test('puntos: se acumulan entre ventas', () async {
      await db.settingsDao.setValue('loyalty_puntos_activo', 'true');
      await db.productsDao.updateLoyaltyPointsValue(productId, 2);
      await db.customersDao
          .earnLoyalty(customerId, [(productId: productId, quantity: 3)]); // +6
      await db.customersDao
          .earnLoyalty(customerId, [(productId: productId, quantity: 2)]); // +4
      final c = await db.customersDao.getAllCustomers();
      expect(c.single.loyaltyPoints, 10);
    });

    test('sellos y puntos activos a la vez: suma ambos en un solo cobro',
        () async {
      await db.settingsDao.setValue('loyalty_sellos_activo', 'true');
      await db.settingsDao.setValue('loyalty_puntos_activo', 'true');
      await db.productsDao.updateLoyaltyPointsValue(productId, 5);
      await db.customersDao
          .earnLoyalty(customerId, [(productId: productId, quantity: 1)]);
      final c = await db.customersDao.getAllCustomers();
      expect(c.single.loyaltyStamps, 1);
      expect(c.single.loyaltyPoints, 5);
    });
  });

  group('redeemLoyalty', () {
    test('stamps:true resetea el contador de sellos a 0', () async {
      await (db.update(db.customers)..where((c) => c.id.equals(customerId)))
          .write(const CustomersCompanion(loyaltyStamps: Value(10)));

      await db.customersDao.redeemLoyalty(customerId, stamps: true);

      final c = await db.customersDao.getAllCustomers();
      expect(c.single.loyaltyStamps, 0);
    });

    test('points:true resta el umbral, el sobrante se queda', () async {
      await db.settingsDao.setValue('loyalty_points_required', '100');
      await (db.update(db.customers)..where((c) => c.id.equals(customerId)))
          .write(const CustomersCompanion(loyaltyPoints: Value(130)));

      await db.customersDao.redeemLoyalty(customerId, points: true);

      final c = await db.customersDao.getAllCustomers();
      expect(c.single.loyaltyPoints, 30);
    });

    test('points:true nunca queda negativo aunque tenga menos que el umbral',
        () async {
      await db.settingsDao.setValue('loyalty_points_required', '100');
      await (db.update(db.customers)..where((c) => c.id.equals(customerId)))
          .write(const CustomersCompanion(loyaltyPoints: Value(40)));

      await db.customersDao.redeemLoyalty(customerId, points: true);

      final c = await db.customersDao.getAllCustomers();
      expect(c.single.loyaltyPoints, 0);
    });

    test('stamps y points independientes: canjear uno no toca el otro',
        () async {
      await db.settingsDao.setValue('loyalty_points_required', '100');
      await (db.update(db.customers)..where((c) => c.id.equals(customerId)))
          .write(const CustomersCompanion(
              loyaltyStamps: Value(10), loyaltyPoints: Value(130)));

      await db.customersDao.redeemLoyalty(customerId, stamps: true);

      final c = await db.customersDao.getAllCustomers();
      expect(c.single.loyaltyStamps, 0);
      expect(c.single.loyaltyPoints, 130); // intacto
    });
  });
}
