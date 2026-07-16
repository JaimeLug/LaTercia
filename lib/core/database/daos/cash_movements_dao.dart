import 'package:drift/drift.dart';
import '../database.dart';

part 'cash_movements_dao.g.dart';

/// Deposits/withdrawals ('deposito'/'retiro') against an open shift's cash
/// drawer. See [ShiftService] for the arqueo math built on top of these.
@DriftAccessor(tables: [CashMovements])
class CashMovementsDao extends DatabaseAccessor<AppDatabase>
    with _$CashMovementsDaoMixin {
  CashMovementsDao(super.db);

  Future<int> insertMovement(CashMovementsCompanion movement) =>
      into(cashMovements).insert(movement);

  Future<List<CashMovement>> getMovementsForShift(int shiftId) =>
      (select(cashMovements)
            ..where((m) => m.shiftId.equals(shiftId))
            ..orderBy([(m) => OrderingTerm.desc(m.ts)]))
          .get();
}
