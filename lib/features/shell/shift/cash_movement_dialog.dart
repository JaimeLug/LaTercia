import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/providers/shift_provider.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/shift_service.dart';
import '../../auth/supervisor_pin_dialog.dart';

/// Deposit/withdrawal form for the currently open [shift]. Requires the
/// `movimientoCaja` permission — cashiers need a supervisor PIN, same
/// pattern as descuento manual / anular.
class CashMovementDialog extends ConsumerStatefulWidget {
  final Shift shift;
  final Employee actor;

  const CashMovementDialog({
    super.key,
    required this.shift,
    required this.actor,
  });

  @override
  ConsumerState<CashMovementDialog> createState() =>
      _CashMovementDialogState();
}

class _CashMovementDialogState extends ConsumerState<CashMovementDialog> {
  String _type = 'deposito';
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) {
      setState(() => _error = 'Ingresa un monto válido');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    final allowed = await SupervisorPinDialog.ensure(
      context,
      ref,
      actor: widget.actor,
      action: PermissionAction.movimientoCaja,
      entity: 'shift',
      entityId: widget.shift.id,
    );
    if (!allowed) {
      if (mounted) setState(() => _submitting = false);
      return;
    }

    try {
      await ref.read(shiftServiceProvider).addCashMovement(
            shiftId: widget.shift.id,
            employeeId: widget.actor.id,
            type: _type,
            amount: amount,
            reason: _reasonController.text.isEmpty
                ? null
                : _reasonController.text,
          );
      await ref.read(currentShiftProvider.notifier).refresh();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Retiro / Depósito de caja'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'deposito', label: Text('Depósito')),
                ButtonSegment(value: 'retiro', label: Text('Retiro')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration:
                  const InputDecoration(labelText: 'Monto', prefixText: r'$ '),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: 'Motivo'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Registrar'),
        ),
      ],
    );
  }
}
