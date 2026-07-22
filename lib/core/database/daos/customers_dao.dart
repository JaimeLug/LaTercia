import 'package:drift/drift.dart';
import '../database.dart';

part 'customers_dao.g.dart';

@DriftAccessor(tables: [Customers])
class CustomersDao extends DatabaseAccessor<AppDatabase>
    with _$CustomersDaoMixin {
  CustomersDao(super.db);

  Future<List<Customer>> getAllCustomers() =>
      (select(customers)..orderBy([(c) => OrderingTerm.asc(c.name)])).get();

  Stream<List<Customer>> watchAllCustomers() =>
      (select(customers)..orderBy([(c) => OrderingTerm.asc(c.name)])).watch();

  Future<List<Customer>> searchCustomers(String query) => (select(customers)
        ..where((c) =>
            c.name.lower().contains(query.toLowerCase()) |
            c.phone.lower().contains(query.toLowerCase())))
      .get();

  Future<int> insertCustomer(CustomersCompanion customer) =>
      into(customers).insert(customer);

  Future<bool> updateCustomer(CustomersCompanion customer) =>
      update(customers).replace(customer);

  Future<void> incrementVisits(int id, double amountSpent) async {
    final customer = await (select(customers)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
    if (customer != null) {
      await (update(customers)..where((c) => c.id.equals(id))).write(
        CustomersCompanion(
          visits: Value(customer.visits + 1),
          totalSpent: Value(customer.totalSpent + amountSpent),
        ),
      );
    }
  }

  /// Suma sellos/puntos según `loyalty_type` en Settings — llamar junto a
  /// [incrementVisits] al cobrar una venta con cliente vinculado. Lee los
  /// settings del propio `AppDatabase` (mismo patrón que `InventoryDao` para
  /// `insumos_activo`), sin necesidad de pasarlos como parámetro.
  /// docs/fidelizacion.md.
  Future<void> earnLoyalty(int id, double amountSpent) async {
    final settings = await attachedDatabase.settingsDao.getAllSettings();
    final type = settings['loyalty_type'] ?? 'ninguno';
    if (type == 'ninguno') return;

    final customer = await (select(customers)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
    if (customer == null) return;

    if (type == 'sellos') {
      await (update(customers)..where((c) => c.id.equals(id))).write(
          CustomersCompanion(loyaltyStamps: Value(customer.loyaltyStamps + 1)));
    } else if (type == 'puntos') {
      final rate =
          double.tryParse(settings['loyalty_points_per_currency'] ?? '');
      if (rate == null || rate <= 0) return;
      final earned = (amountSpent / rate).floor();
      if (earned <= 0) return;
      await (update(customers)..where((c) => c.id.equals(id))).write(
          CustomersCompanion(
              loyaltyPoints: Value(customer.loyaltyPoints + earned)));
    }
  }

  /// Consume la recompensa ganada: resetea sellos a 0, o resta el umbral de
  /// puntos (el sobrante se queda). Llamar SOLO al cobrar de una vez (nunca en
  /// el flujo de "pagar después" — v1, ver docs/fidelizacion.md).
  Future<void> redeemLoyalty(int id) async {
    final settings = await attachedDatabase.settingsDao.getAllSettings();
    final type = settings['loyalty_type'] ?? 'ninguno';
    final customer = await (select(customers)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
    if (customer == null) return;

    if (type == 'sellos') {
      await (update(customers)..where((c) => c.id.equals(id)))
          .write(const CustomersCompanion(loyaltyStamps: Value(0)));
    } else if (type == 'puntos') {
      final required =
          int.tryParse(settings['loyalty_points_required'] ?? '') ?? 0;
      final remaining = customer.loyaltyPoints - required;
      await (update(customers)..where((c) => c.id.equals(id))).write(
          CustomersCompanion(
              loyaltyPoints: Value(remaining < 0 ? 0 : remaining)));
    }
  }

  Future<int> deleteCustomer(int id) =>
      (delete(customers)..where((c) => c.id.equals(id))).go();
}
