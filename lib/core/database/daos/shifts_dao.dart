import 'package:drift/drift.dart';
import '../database.dart';

part 'shifts_dao.g.dart';

@DriftAccessor(tables: [Shifts])
class ShiftsDao extends DatabaseAccessor<AppDatabase> with _$ShiftsDaoMixin {
  ShiftsDao(super.db);

  /// El único turno abierto del sistema (uno a la vez), o null.
  /// `docs/ventas-cobro-turnos.md` §Turnos.
  Future<Shift?> getCurrentOpenShift() =>
      (select(shifts)..where((s) => s.endedAt.isNull() & s.deletedAt.isNull()))
          .getSingleOrNull();

  Future<int> openShift(ShiftsCompanion shift) => into(shifts).insert(shift);

  Future<void> closeShift(int shiftId, double endingCash, double totalSales,
          [int? zNumber]) =>
      (update(shifts)..where((s) => s.id.equals(shiftId))).write(
        ShiftsCompanion(
          endedAt: Value(DateTime.now()),
          endingCash: Value(endingCash),
          totalSales: Value(totalSales),
          zNumber: zNumber == null ? const Value.absent() : Value(zNumber),
        ),
      );

  Future<List<Shift>> getShiftsByEmployee(int employeeId) => (select(shifts)
        ..where((s) => s.employeeId.equals(employeeId) & s.deletedAt.isNull())
        ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
      .get();

  /// Turnos ya cerrados (con `endedAt`), más reciente primero (historial de
  /// cortes Z en Admin). Excluye los eliminados (soft delete).
  Future<List<Shift>> getClosedShifts() => (select(shifts)
        ..where((s) => s.endedAt.isNotNull() & s.deletedAt.isNull())
        ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
      .get();

  Future<Shift?> getShiftById(int id) =>
      (select(shifts)..where((s) => s.id.equals(id))).getSingleOrNull();

  /// Soft delete: oculta el corte del historial y de los reportes sin borrarlo
  /// de la BD. docs/soft-delete.md.
  Future<void> softDeleteShift(int shiftId) =>
      (update(shifts)..where((s) => s.id.equals(shiftId)))
          .write(ShiftsCompanion(deletedAt: Value(DateTime.now())));

  /// El `zNumber` más alto asignado (o 0). El próximo corte Z es este + 1.
  /// Cuenta también los eliminados: el número Z no se reutiliza.
  Future<int> getMaxZNumber() async {
    final maxExp = shifts.zNumber.max();
    final query = selectOnly(shifts)..addColumns([maxExp]);
    final row = await query.getSingle();
    return row.read(maxExp) ?? 0;
  }
}
