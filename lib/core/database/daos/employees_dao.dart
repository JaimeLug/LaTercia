import 'package:drift/drift.dart';
import '../../utils/pin_hasher.dart';
import '../database.dart';

part 'employees_dao.g.dart';

@DriftAccessor(tables: [Employees])
class EmployeesDao extends DatabaseAccessor<AppDatabase>
    with _$EmployeesDaoMixin {
  EmployeesDao(super.db);

  Future<List<Employee>> getAllEmployees() =>
      (select(employees)
            ..orderBy([(e) => OrderingTerm.asc(e.name)]))
          .get();

  Stream<List<Employee>> watchAllEmployees() =>
      (select(employees)
            ..orderBy([(e) => OrderingTerm.asc(e.name)]))
          .watch();

  Future<Employee?> findByPin(String pin) =>
      (select(employees)
            ..where((e) => e.pin.equals(hashPin(pin)) & e.active.equals(true)))
          .getSingleOrNull();

  /// ¿Algún OTRO empleado **activo** (distinto de [excludeId]) ya usa este PIN?
  ///
  /// Compara contra el hash, igual que el login. Se usa para impedir PINs
  /// duplicados entre cajeros activos antes de guardar — sin esto, dos cajeros
  /// podían compartir PIN y los reportes por empleado quedaban ambiguos
  /// (auditoría 2026-07-18). Los empleados inactivos NO cuentan, para poder
  /// reutilizar el PIN de alguien dado de baja.
  Future<bool> pinInUseByActive(String pin, {int? excludeId}) async {
    final query = select(employees)
      ..where((e) => e.pin.equals(hashPin(pin)) & e.active.equals(true));
    if (excludeId != null) {
      query.where((e) => e.id.equals(excludeId).not());
    }
    return (await query.get()).isNotEmpty;
  }

  Future<int> insertEmployee(EmployeesCompanion employee) =>
      into(employees).insert(employee);

  Future<bool> updateEmployee(EmployeesCompanion employee) =>
      update(employees).replace(employee);

  Future<void> toggleActive(int id, bool active) =>
      (update(employees)..where((e) => e.id.equals(id)))
          .write(EmployeesCompanion(active: Value(active)));

  Future<int> deleteEmployee(int id) =>
      (delete(employees)..where((e) => e.id.equals(id))).go();
}
