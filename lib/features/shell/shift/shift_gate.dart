import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/session_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/shift_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'open_shift_dialog.dart';

/// Blocks [child] (the POS tab) behind a modal "open a shift" screen when
/// `caja_requiere_turno` is on and no shift is currently open. Does not gate
/// KDS or Admin — those are rendered outside this wrapper.
class ShiftGate extends ConsumerWidget {
  final Widget child;
  const ShiftGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final requiresShift = (settings['caja_requiere_turno'] ?? 'true') == 'true';
    final shiftAsync = ref.watch(currentShiftProvider);

    if (!requiresShift) return child;

    return shiftAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (shift) {
        if (shift != null) return child;

        final employee = ref.watch(sessionProvider);
        if (employee == null) {
          // Should not normally happen (PinGate runs first), but guard
          // rather than crash on a null employee.
          return const Center(child: Text('Sin sesión activa.'));
        }

        return Container(
          color: LaTerciaColors.appBg,
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.point_of_sale,
                          size: 40, color: LaTerciaColors.burntOrange),
                      const SizedBox(height: 12),
                      const Text(
                        'Es necesario abrir un turno de caja antes de vender.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),
                      OpenShiftForm(employee: employee),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
