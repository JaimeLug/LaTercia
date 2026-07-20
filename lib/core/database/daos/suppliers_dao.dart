import 'package:drift/drift.dart';
import '../database.dart';

part 'suppliers_dao.g.dart';

@DriftAccessor(tables: [Suppliers])
class SuppliersDao extends DatabaseAccessor<AppDatabase>
    with _$SuppliersDaoMixin {
  SuppliersDao(super.db);

  Future<List<Supplier>> getAllSuppliers() =>
      (select(suppliers)..orderBy([(s) => OrderingTerm(expression: s.name)]))
          .get();

  Future<List<Supplier>> getActiveSuppliers() => (select(suppliers)
        ..where((s) => s.active.equals(true))
        ..orderBy([(s) => OrderingTerm(expression: s.name)]))
      .get();

  Future<int> insertSupplier(SuppliersCompanion entry) =>
      into(suppliers).insert(entry);

  Future<void> updateSupplier(SuppliersCompanion entry) =>
      (update(suppliers)..where((s) => s.id.equals(entry.id.value)))
          .write(entry);

  /// Soft delete — conserva el historial de compras ligado a este proveedor.
  Future<void> setActive(int id, bool active) =>
      (update(suppliers)..where((s) => s.id.equals(id)))
          .write(SuppliersCompanion(active: Value(active)));
}
