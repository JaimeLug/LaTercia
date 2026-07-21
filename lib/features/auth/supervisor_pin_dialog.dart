import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/audit_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/theme/app_theme.dart';

/// Gate reutilizable para las acciones sensibles. `ensure` devuelve `true` de
/// inmediato si el actor ya tiene permiso; si no, pide PIN de supervisor y, si
/// es válido (de otro admin/gerente), audita la aprobación y devuelve `true`.
/// docs/permisos-y-auditoria.md.
class SupervisorPinDialog {
  SupervisorPinDialog._();

  static Future<bool> ensure(
    BuildContext context,
    WidgetRef ref, {
    required Employee actor,
    required PermissionAction action,
    String? entity,
    int? entityId,
  }) async {
    final permissionService = ref.read(permissionServiceProvider);
    if (permissionService.hasPermission(actor, action)) return true;

    final supervisor = await showDialog<Employee>(
      context: context,
      builder: (_) => _SupervisorPinDialogContent(actor: actor),
    );
    if (supervisor == null) return false;

    await ref.read(auditServiceProvider).log(
      employeeId: actor.id,
      action: action.key,
      entity: entity,
      entityId: entityId,
      detail: {
        'actorEmployeeId': actor.id,
        'supervisorEmployeeId': supervisor.id,
      },
    );
    return true;
  }
}

class _SupervisorPinDialogContent extends ConsumerStatefulWidget {
  final Employee actor;
  const _SupervisorPinDialogContent({required this.actor});

  @override
  ConsumerState<_SupervisorPinDialogContent> createState() =>
      _SupervisorPinDialogContentState();
}

class _SupervisorPinDialogContentState
    extends ConsumerState<_SupervisorPinDialogContent> {
  final _pinController = TextEditingController();
  String? _error;
  bool _checking = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _pinController.text;
    if (pin.length != 4) {
      setState(() => _error = 'PIN de 4 dígitos');
      return;
    }

    setState(() {
      _checking = true;
      _error = null;
    });

    final db = ref.read(databaseProvider);
    final permissionService = ref.read(permissionServiceProvider);
    final result = await permissionService.validateSupervisorPin(
      db,
      pin: pin,
      actor: widget.actor,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.pop(context, result.supervisor);
      return;
    }

    setState(() {
      _checking = false;
      _pinController.clear();
      _error = switch (result.error!) {
        SupervisorPinError.invalidPin => 'PIN incorrecto',
        SupervisorPinError.notSupervisor => 'Ese empleado no es supervisor',
        SupervisorPinError.sameEmployee =>
          'Un supervisor no puede autorizarse a sí mismo',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('PIN de supervisor requerido'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta acción requiere autorización de un administrador o '
              'gerente distinto del empleado actual.',
              style: TextStyle(color: LaTerciaColors.tan),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              enabled: !_checking,
              decoration: InputDecoration(
                labelText: 'PIN de supervisor',
                errorText: _error,
                counterText: '',
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _checking ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _checking ? null : _submit,
          child: const Text('Autorizar'),
        ),
      ],
    );
  }
}
