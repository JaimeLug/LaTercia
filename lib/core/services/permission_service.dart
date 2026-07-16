import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';

/// The sensitive actions gated by the supervisor-PIN mechanism.
///
/// [key] is the stable string stored in `audit_log.action` / matched against
/// in tests — keep it snake_case and don't rename it once shipped, or old
/// audit rows stop matching new queries.
enum PermissionAction {
  anular('anular'),
  descuentoManual('descuento_manual'),
  abrirGavetaSinVenta('abrir_gaveta_sin_venta'),
  corteZ('corte_z'),
  reimprimir('reimprimir'),
  editarCatalogo('editar_catalogo'),
  movimientoCaja('movimiento_caja'),
  reembolso('reembolso');

  final String key;
  const PermissionAction(this.key);
}

/// Reasons a supervisor-PIN entry can fail validation, so the UI can show a
/// specific message instead of a generic "incorrect PIN".
enum SupervisorPinError {
  /// No active employee has this PIN.
  invalidPin,

  /// The PIN belongs to an employee, but they're not `admin`/`gerente`.
  notSupervisor,

  /// The PIN belongs to the same employee who is asking for authorization —
  /// a supervisor can't approve their own action this way.
  sameEmployee,
}

/// Result of [PermissionService.validateSupervisorPin]: either the approving
/// [Employee] on success, or a [SupervisorPinError] on failure.
class SupervisorPinResult {
  final Employee? supervisor;
  final SupervisorPinError? error;

  const SupervisorPinResult.success(this.supervisor) : error = null;

  const SupervisorPinResult.failure(this.error) : supervisor = null;

  bool get isSuccess => supervisor != null;
}

/// Role-based permission matrix for the 7 sensitive actions.
///
/// `admin`/`gerente` always have every permission. Everyone else (in
/// practice: `cashier`) needs a supervisor (a *different* `admin`/`gerente`
/// employee) to approve via PIN — see [SupervisorPinDialog].
class PermissionService {
  const PermissionService();

  static const _supervisorRoles = {'admin', 'gerente'};

  bool hasPermission(Employee actor, PermissionAction action) =>
      _supervisorRoles.contains(actor.role);

  /// Looks up [pin] and checks it belongs to a supervisor (`admin`/`gerente`)
  /// other than [actor]. Pure lookup + validation, kept separate from any
  /// widget so it's directly testable.
  Future<SupervisorPinResult> validateSupervisorPin(
    AppDatabase db, {
    required String pin,
    required Employee actor,
  }) async {
    final candidate = await db.employeesDao.findByPin(pin);
    if (candidate == null) {
      return const SupervisorPinResult.failure(SupervisorPinError.invalidPin);
    }
    if (!_supervisorRoles.contains(candidate.role)) {
      return const SupervisorPinResult.failure(
          SupervisorPinError.notSupervisor);
    }
    if (candidate.id == actor.id) {
      return const SupervisorPinResult.failure(
          SupervisorPinError.sameEmployee);
    }
    return SupervisorPinResult.success(candidate);
  }
}

final permissionServiceProvider =
    Provider<PermissionService>((ref) => const PermissionService());
