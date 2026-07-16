import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/providers/shift_provider.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/shift_service.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/supervisor_pin_dialog.dart';
import 'cut_ticket.dart';

/// Counted-cash form for closing [shift]. Requires `corteZ` permission.
/// On success, replaces its own content with the resulting Corte Z ticket.
class CloseShiftDialog extends ConsumerStatefulWidget {
  final Shift shift;
  final Employee actor;
  final String symbol;

  const CloseShiftDialog({
    super.key,
    required this.shift,
    required this.actor,
    required this.symbol,
  });

  @override
  ConsumerState<CloseShiftDialog> createState() => _CloseShiftDialogState();
}

class _CloseShiftDialogState extends ConsumerState<CloseShiftDialog> {
  final _countedController = TextEditingController();
  bool _submitting = false;
  String? _error;
  ShiftSummary? _result;

  @override
  void dispose() {
    _countedController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final counted =
        double.tryParse(_countedController.text.replaceAll(',', '.'));
    if (counted == null || counted < 0) {
      setState(() => _error = 'Ingresa el efectivo contado');
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
      action: PermissionAction.corteZ,
      entity: 'shift',
      entityId: widget.shift.id,
    );
    if (!allowed) {
      if (mounted) setState(() => _submitting = false);
      return;
    }

    try {
      final summary = await ref.read(shiftServiceProvider).closeShift(
            shiftId: widget.shift.id,
            employeeId: widget.actor.id,
            countedCash: counted,
          );
      await ref.read(currentShiftProvider.notifier).refresh();
      // Backup best-effort al cerrar turno (5.2); no bloquea el cierre.
      unawaited(ref.read(backupServiceProvider).backupOnShiftClose());
      if (mounted) {
        setState(() {
          _result = summary;
          _submitting = false;
        });
      }
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
    if (_result != null) {
      return AlertDialog(
        title: const Text('Turno cerrado'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: CutTicket(summary: _result!, symbol: widget.symbol, isZ: true),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Cerrar turno — arqueo de caja'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
                'Fondo inicial: ${formatCurrency(widget.shift.startingCash, widget.symbol)}'),
            const SizedBox(height: 12),
            TextField(
              controller: _countedController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Efectivo contado',
                prefixText: r'$ ',
              ),
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
              : const Text('Cerrar turno'),
        ),
      ],
    );
  }
}
