import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';

/// CustomersDao.earnLoyalty / redeemLoyalty — ver docs/fidelizacion.md.
void main() {
  late AppDatabase db;
  late int customerId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    customerId = await db.customersDao
        .insertCustomer(CustomersCompanion.insert(name: 'Ana'));
  });
  tearDown(() => db.close());

  group('earnLoyalty', () {
    test('sin programa activo (ninguno): no suma nada', () async {
      await db.settingsDao.setValue('loyalty_type', 'ninguno');
      await db.customersDao.earnLoyalty(customerId, 100);
      final c = await db.customersDao.getAllCustomers();
      expect(c.single.loyaltyStamps, 0);
      expect(c.single.loyaltyPoints, 0);
    });

    test('sellos: +1 por cada venta, sin importar el monto', () async {
      await db.settingsDao.setValue('loyalty_type', 'sellos');
      await db.customersDao.earnLoyalty(customerId, 5);
      await db.customersDao.earnLoyalty(customerId, 500);
      final c = await db.customersDao.getAllCustomers();
      expect(c.single.loyaltyStamps, 2);
    });

    test('puntos: gana floor(monto / tasa)', () async {
      await db.settingsDao.setValue('loyalty_type', 'puntos');
      await db.settingsDao.setValue('loyalty_points_per_currency', '10');
      await db.customersDao.earnLoyalty(customerId, 55); // 55/10 = 5.5 → 5
      final c = await db.customersDao.getAllCustomers();
      expect(c.single.loyaltyPoints, 5);
    });

    test('puntos: se acumulan entre ventas', () async {
      await db.settingsDao.setValue('loyalty_type', 'puntos');
      await db.settingsDao.setValue('loyalty_points_per_currency', '10');
      await db.customersDao.earnLoyalty(customerId, 30); // +3
      await db.customersDao.earnLoyalty(customerId, 25); // +2
      final c = await db.customersDao.getAllCustomers();
      expect(c.single.loyaltyPoints, 5);
    });
  });

  group('redeemLoyalty', () {
    test('sellos: resetea el contador a 0', () async {
      await db.settingsDao.setValue('loyalty_type', 'sellos');
      await (db.update(db.customers)..where((c) => c.id.equals(customerId)))
          .write(const CustomersCompanion(loyaltyStamps: Value(10)));

      await db.customersDao.redeemLoyalty(customerId);

      final c = await db.customersDao.getAllCustomers();
      expect(c.single.loyaltyStamps, 0);
    });

    test('puntos: resta el umbral, el sobrante se queda', () async {
      await db.settingsDao.setValue('loyalty_type', 'puntos');
      await db.settingsDao.setValue('loyalty_points_required', '100');
      await (db.update(db.customers)..where((c) => c.id.equals(customerId)))
          .write(const CustomersCompanion(loyaltyPoints: Value(130)));

      await db.customersDao.redeemLoyalty(customerId);

      final c = await db.customersDao.getAllCustomers();
      expect(c.single.loyaltyPoints, 30);
    });

    test('puntos: nunca queda negativo aunque tenga menos que el umbral',
        () async {
      await db.settingsDao.setValue('loyalty_type', 'puntos');
      await db.settingsDao.setValue('loyalty_points_required', '100');
      await (db.update(db.customers)..where((c) => c.id.equals(customerId)))
          .write(const CustomersCompanion(loyaltyPoints: Value(40)));

      await db.customersDao.redeemLoyalty(customerId);

      final c = await db.customersDao.getAllCustomers();
      expect(c.single.loyaltyPoints, 0);
    });
  });
}
