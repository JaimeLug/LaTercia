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

  Future<int> deleteCustomer(int id) =>
      (delete(customers)..where((c) => c.id.equals(id))).go();
}
