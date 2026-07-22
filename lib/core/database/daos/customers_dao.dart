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

  /// Suma sellos/puntos — sellos y puntos son mecánicas INDEPENDIENTES
  /// (`loyalty_sellos_activo`/`loyalty_puntos_activo` en Settings, ambas
  /// pueden estar activas a la vez). Llamar junto a [incrementVisits] al
  /// cobrar una venta con cliente vinculado. Los puntos se ganan por
  /// PRODUCTO (`Products.loyaltyPointsValue` × cantidad), no por monto
  /// gastado — de ahí que reciba las líneas de la orden. Lee los settings del
  /// propio `AppDatabase` (mismo patrón que `InventoryDao` para
  /// `insumos_activo`), sin necesidad de pasarlos como parámetro.
  /// docs/fidelizacion.md.
  Future<void> earnLoyalty(
    int id,
    List<({int productId, int quantity})> items,
  ) async {
    final settings = await attachedDatabase.settingsDao.getAllSettings();
    final sellosOn = settings['loyalty_sellos_activo'] == 'true';
    final puntosOn = settings['loyalty_puntos_activo'] == 'true';
    if (!sellosOn && !puntosOn) return;

    final customer = await (select(customers)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
    if (customer == null) return;

    var pointsEarned = 0;
    if (puntosOn) {
      for (final item in items) {
        final product =
            await attachedDatabase.productsDao.getProductById(item.productId);
        pointsEarned += (product?.loyaltyPointsValue ?? 0) * item.quantity;
      }
    }
    final stampsEarned = sellosOn ? 1 : 0;
    if (stampsEarned == 0 && pointsEarned == 0) return;

    await (update(customers)..where((c) => c.id.equals(id))).write(
      CustomersCompanion(
        loyaltyStamps: Value(customer.loyaltyStamps + stampsEarned),
        loyaltyPoints: Value(customer.loyaltyPoints + pointsEarned),
      ),
    );
  }

  /// Consume la(s) recompensa(s) ganada(s): resetea sellos a 0 y/o resta el
  /// umbral de puntos (el sobrante se queda) — independientes entre sí, según
  /// cuál se haya canjeado en el POS. Llamar SOLO al cobrar de una vez (nunca
  /// en el flujo de "pagar después" — v1, ver docs/fidelizacion.md).
  Future<void> redeemLoyalty(
    int id, {
    bool stamps = false,
    bool points = false,
  }) async {
    if (!stamps && !points) return;
    final customer = await (select(customers)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
    if (customer == null) return;

    var newStamps = customer.loyaltyStamps;
    var newPoints = customer.loyaltyPoints;
    if (stamps) newStamps = 0;
    if (points) {
      final settings = await attachedDatabase.settingsDao.getAllSettings();
      final required =
          int.tryParse(settings['loyalty_points_required'] ?? '') ?? 0;
      final remaining = customer.loyaltyPoints - required;
      newPoints = remaining < 0 ? 0 : remaining;
    }

    await (update(customers)..where((c) => c.id.equals(id))).write(
      CustomersCompanion(
        loyaltyStamps: Value(newStamps),
        loyaltyPoints: Value(newPoints),
      ),
    );
  }

  Future<int> deleteCustomer(int id) =>
      (delete(customers)..where((c) => c.id.equals(id))).go();
}
