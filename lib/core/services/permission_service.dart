import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';

/// Acciones sensibles que exigen PIN de supervisor. `key` es el string estable
/// guardado en `audit_log.action`: no renombrar. `docs/permisos-y-auditoria.md`.
enum PermissionAction {
  anular('anular'),
  descuentoManual('descuento_manual'),
  abrirGavetaSinVenta('abrir_gaveta_sin_venta'),
  corteZ('corte_z'),
  reimprimir('reimprimir'),
  editarCatalogo('editar_catalogo'),
  movimientoCaja('movimiento_caja'),
  reembolso('reembolso'),
  eliminar('eliminar');

  final String key;
  const PermissionAction(this.key);
}

/// Motivos por los que un PIN de supervisor puede fallar (para un mensaje
/// específico en la UI). `docs/permisos-y-auditoria.md`.
enum SupervisorPinError {
  /// Ningún empleado activo tiene ese PIN.
  invalidPin,

  /// El PIN es de un empleado, pero no es `admin`/`gerente`.
  notSupervisor,

  /// El PIN es del mismo empleado que pide autorización.
  sameEmployee,
}

/// Resultado de [PermissionService.validateSupervisorPin]: el [Employee] que
/// aprueba, o un [SupervisorPinError].
class SupervisorPinResult {
  final Employee? supervisor;
  final SupervisorPinError? error;

  const SupervisorPinResult.success(this.supervisor) : error = null;

  const SupervisorPinResult.failure(this.error) : supervisor = null;

  bool get isSuccess => supervisor != null;
}

/// Matriz de permisos por rol: `admin`/`gerente` pueden todo; los demás
/// necesitan un supervisor distinto que apruebe con PIN.
/// `docs/permisos-y-auditoria.md`.
class PermissionService {
  const PermissionService();

  static const _supervisorRoles = {'admin', 'gerente'};

  bool hasPermission(Employee actor, PermissionAction action) =>
      _supervisorRoles.contains(actor.role);

  /// Busca [pin] y verifica que sea de un supervisor distinto de [actor].
  /// `docs/permisos-y-auditoria.md` §"Validación del PIN de supervisor".
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
      return const SupervisorPinResult.failure(SupervisorPinError.sameEmployee);
    }
    return SupervisorPinResult.success(candidate);
  }
}

final permissionServiceProvider =
    Provider<PermissionService>((ref) => const PermissionService());
