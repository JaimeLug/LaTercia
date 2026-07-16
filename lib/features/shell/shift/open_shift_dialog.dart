import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/providers/shift_provider.dart';
import '../../../core/services/shift_service.dart';

/// Inline form (not a modal dialog — used both as the blocking POS gate and
/// inside the Turno screen) to open a new shift for [employee].
///
/// Blocked at the service layer if a shift is already open system-wide (see
/// `ShiftService.openShift`); this form doesn't re-check, it just surfaces
/// whatever error comes back.
class OpenShiftForm extends ConsumerStatefulWidget {
  final Employee employee;
  final VoidCallback? onOpened;

  const OpenShiftForm({super.key, required this.employee, this.onOpened});

  @override
  ConsumerState<OpenShiftForm> createState() => _OpenShiftFormState();
}

class _OpenShiftFormState extends ConsumerState<OpenShiftForm> {
  final _cashController = TextEditingController(text: '0.00');
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount =
        double.tryParse(_cashController.text.replaceAll(',', '.')) ?? -1;
    if (amount < 0) {
      setState(() => _error = 'Ingresa un fondo inicial válido');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(shiftServiceProvider).openShift(
            employeeId: widget.employee.id,
            startingCash: amount,
          );
      await ref.read(currentShiftProvider.notifier).refresh();
      widget.onOpened?.call();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Empleado: ${widget.employee.name}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        TextField(
          controller: _cashController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(
            labelText: 'Fondo inicial de caja',
            prefixText: r'$ ',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Abrir turno'),
        ),
      ],
    );
  }
}
