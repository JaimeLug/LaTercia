import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import 'audit_service.dart';

/// Arqueo (cash-count) breakdown for a shift, used by both Corte X
/// (read-only, shift still open) and Corte Z (the result of closing it).
///
/// Nothing here is persisted beyond what [Shift] already stores — the whole
/// breakdown is derivable on demand from `Payments`/`CashMovements`/`Orders`,
/// per the "no la persistas en una columna nueva" rule.
class ShiftSummary {
  final Shift shift;

  /// Cash sales only (`Payments.method == 'efectivo'`), net of change given.
  final double cashSales;
  final double deposits;
  final double withdrawals;

  /// `startingCash + cashSales + deposits - withdrawals`.
  final double expectedCash;

  /// Only set once the shift has been (or is being) closed with a counted
  /// amount — null for a Corte X on a still-open shift.
  final double? countedCash;

  /// `countedCash - expectedCash`, null when [countedCash] is null.
  final double? difference;

  /// Sum of `Payments.amountTendered - changeGiven`, grouped by method.
  final Map<String, double> paymentsByMethod;

  final double discountsTotal;
  final int cancelledCount;
  final double cancelledAmount;

  /// Suma de `Payments.tipAmount` del turno (4.1). Va como línea aparte: no es
  /// venta. El efectivo de la propina sí está físicamente en la gaveta, por eso
  /// [cashSales]/[expectedCash] ya lo incluyen —esto es solo para saber cuánto
  /// de lo cobrado corresponde a propina.
  final double tipsTotal;

  /// Suma de reembolsos del turno (4.4). Se resta de [expectedCash] porque el
  /// efectivo devuelto sale físicamente de la gaveta.
  final double refundsTotal;

  const ShiftSummary({
    required this.shift,
    required this.cashSales,
    required this.deposits,
    required this.withdrawals,
    required this.expectedCash,
    required this.paymentsByMethod,
    required this.discountsTotal,
    required this.cancelledCount,
    required this.cancelledAmount,
    required this.tipsTotal,
    required this.refundsTotal,
    this.countedCash,
    this.difference,
  });
}

/// Everything needed to open/close a shift and compute its arqueo — the
/// server-side counterpart of the Turnos/Cortes UI.
///
/// One shift open at a time, system-wide (see `ShiftsDao.getCurrentOpenShift`
/// docs). All money math (deposits, withdrawals, cash sales, expected vs.
/// counted) lives here so the X-cut (read-only, mid-shift) and Z-cut (result
/// of closing) share one implementation instead of drifting apart.
class ShiftService {
  ShiftService(this._db);

  final AppDatabase _db;

  /// Opens a new shift. Throws a [StateError] if one is already open — the
  /// caller (UI) should have already checked via `getCurrentOpenShift`, but
  /// this is the actual invariant guard since UI checks can race.
  Future<Shift> openShift({
    required int employeeId,
    required double startingCash,
  }) {
    return _db.transaction(() async {
      final existing = await _db.shiftsDao.getCurrentOpenShift();
      if (existing != null) {
        throw StateError('Ya hay un turno abierto.');
      }
      final id = await _db.shiftsDao.openShift(
        ShiftsCompanion.insert(
          employeeId: employeeId,
          startedAt: DateTime.now(),
          startingCash: Value(startingCash),
        ),
      );
      await AuditService(_db).log(
        employeeId: employeeId,
        action: 'apertura_turno',
        entity: 'shift',
        entityId: id,
        detail: {'startingCash': startingCash},
      );
      return (await _db.shiftsDao.getShiftById(id))!;
    });
  }

  /// Records a deposit/withdrawal against [shiftId]. Permission gating
  /// (`PermissionAction.movimientoCaja`) happens at the call site via
  /// `SupervisorPinDialog.ensure` before this is called.
  Future<void> addCashMovement({
    required int shiftId,
    required int employeeId,
    required String type,
    required double amount,
    String? reason,
  }) async {
    await _db.cashMovementsDao.insertMovement(
      CashMovementsCompanion.insert(
        shiftId: shiftId,
        employeeId: employeeId,
        type: type,
        amount: amount,
        reason: Value(reason),
      ),
    );
    await AuditService(_db).log(
      employeeId: employeeId,
      action: 'movimiento_caja',
      entity: 'shift',
      entityId: shiftId,
      detail: {'type': type, 'amount': amount, 'reason': reason},
    );
  }

  /// Corte X (open shift) or the basis for Corte Z (about to be closed).
  /// [countedCash] is only known when actually closing.
  Future<ShiftSummary> computeSummary(int shiftId,
      {double? countedCash}) async {
    final shift = await _db.shiftsDao.getShiftById(shiftId);
    if (shift == null) {
      throw StateError('Turno $shiftId no existe.');
    }

    final payments = await _db.paymentsDao.getPaymentsForShift(shiftId);
    final movements = await _db.cashMovementsDao.getMovementsForShift(shiftId);
    final orders = await _db.ordersDao.getOrdersByShift(shiftId);
    final refunds = await _db.refundsDao.getRefundsForShift(shiftId);
    final refundsTotal = refunds.fold(0.0, (a, r) => a + r.amount);

    final paymentsByMethod = <String, double>{};
    for (final p in payments) {
      final net = p.amountTendered - p.changeGiven;
      paymentsByMethod[p.method] = (paymentsByMethod[p.method] ?? 0) + net;
    }
    final cashSales = paymentsByMethod['efectivo'] ?? 0;
    final tipsTotal = payments.fold(0.0, (a, p) => a + p.tipAmount);

    final deposits = movements
        .where((m) => m.type == 'deposito')
        .fold(0.0, (a, m) => a + m.amount);
    final withdrawals = movements
        .where((m) => m.type == 'retiro')
        .fold(0.0, (a, m) => a + m.amount);

    final expected =
        shift.startingCash + cashSales + deposits - withdrawals - refundsTotal;

    final discountsTotal = orders.fold(0.0, (a, o) => a + o.discountAmount);
    final cancelled = orders.where((o) => o.status == 'cancelado').toList();

    return ShiftSummary(
      shift: shift,
      cashSales: cashSales,
      deposits: deposits,
      withdrawals: withdrawals,
      expectedCash: expected,
      countedCash: countedCash,
      difference: countedCash == null ? null : countedCash - expected,
      paymentsByMethod: paymentsByMethod,
      discountsTotal: discountsTotal,
      cancelledCount: cancelled.length,
      cancelledAmount: cancelled.fold(0.0, (a, o) => a + o.total),
      tipsTotal: tipsTotal,
      refundsTotal: refundsTotal,
    );
  }

  /// Closes [shiftId] with the counted cash, assigning the next consecutive
  /// `zNumber` and stamping `endingCash`/`totalSales`, all inside one
  /// transaction. Permission gating (`PermissionAction.corteZ`) happens at
  /// the call site before this is invoked.
  Future<ShiftSummary> closeShift({
    required int shiftId,
    required int employeeId,
    required double countedCash,
  }) {
    return _db.transaction(() async {
      final orders = await _db.ordersDao.getOrdersByShift(shiftId);
      final totalSales = orders
          .where((o) => o.paymentStatus == 'pagado')
          .fold(0.0, (a, o) => a + o.total);

      final nextZ = await _db.shiftsDao.getMaxZNumber() + 1;

      await _db.shiftsDao.closeShift(shiftId, countedCash, totalSales, nextZ);

      await AuditService(_db).log(
        employeeId: employeeId,
        action: 'cierre_turno',
        entity: 'shift',
        entityId: shiftId,
        detail: {
          'countedCash': countedCash,
          'totalSales': totalSales,
          'zNumber': nextZ,
        },
      );

      return computeSummary(shiftId, countedCash: countedCash);
    });
  }
}

final shiftServiceProvider = Provider<ShiftService>((ref) {
  return ShiftService(ref.watch(databaseProvider));
});
