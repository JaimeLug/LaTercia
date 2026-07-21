import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import 'audit_service.dart';

/// Arqueo de un turno, para Corte X (solo lectura) y Corte Z (al cerrar). Se
/// deriva a demanda, no se persiste. `docs/ventas-cobro-turnos.md` §Arqueo.
class ShiftSummary {
  final Shift shift;

  /// Ventas en efectivo, neto del cambio dado.
  final double cashSales;
  final double deposits;
  final double withdrawals;

  /// `startingCash + cashSales + deposits - withdrawals - refundsTotal`.
  final double expectedCash;

  /// Solo al cerrar con un monto contado; null en un Corte X.
  final double? countedCash;

  /// `countedCash - expectedCash`, null si [countedCash] es null.
  final double? difference;

  /// `Payments.amountTendered - changeGiven`, agrupado por método.
  final Map<String, double> paymentsByMethod;

  final double discountsTotal;
  final int cancelledCount;
  final double cancelledAmount;

  /// Propinas del turno (línea aparte, no venta). `docs/ventas-cobro-turnos.md`.
  final double tipsTotal;

  /// Reembolsos del turno; se restan de [expectedCash].
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

/// Abrir/cerrar turno y calcular el arqueo. Un solo turno abierto a la vez;
/// todo el cálculo de dinero vive aquí. `docs/ventas-cobro-turnos.md` §Turnos.
class ShiftService {
  ShiftService(this._db);

  final AppDatabase _db;

  /// Abre un turno; lanza si ya hay uno abierto (guarda real del invariante).
  /// `docs/ventas-cobro-turnos.md` §"Abrir / cerrar".
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

  /// Registra un depósito/retiro. El permiso (`movimientoCaja`) se valida en el
  /// punto de llamada. `docs/ventas-cobro-turnos.md`.
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

  /// Corte X (turno abierto) o la base del Corte Z. [countedCash] solo se
  /// conoce al cerrar. `docs/ventas-cobro-turnos.md` §Arqueo.
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

  /// Cierra [shiftId] con el efectivo contado, asigna el `zNumber` y sella
  /// `endingCash`/`totalSales`, en una transacción. El permiso (`corteZ`) se
  /// valida en el punto de llamada. `docs/ventas-cobro-turnos.md`.
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
