import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/session_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/shift_provider.dart';
import '../../../core/services/shift_service.dart';
import '../../../core/theme/app_theme.dart';
import 'cash_movement_dialog.dart';
import 'close_shift_dialog.dart';
import 'cut_ticket.dart';
import 'open_shift_dialog.dart';

/// Turno / Corte X screen — reachable from the top nav bar at any time.
/// Muestra el turno actual (o el formulario de apertura), permite registrar
/// depósitos/retiros, ver el Corte X en vivo o cerrar el turno (Corte Z).
/// docs/ventas-cobro-turnos.md §Turnos.
class ShiftScreen extends ConsumerWidget {
  const ShiftScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftAsync = ref.watch(currentShiftProvider);
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final symbol = settings['currency_symbol'] ?? r'$';
    final employee = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Turno de caja')),
      body: shiftAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (shift) {
          if (employee == null) {
            return const Center(child: Text('Sin sesión activa.'));
          }
          if (shift == null) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('No hay turno abierto',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 16),
                          OpenShiftForm(employee: employee),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('Retiro / Depósito'),
                            onPressed: () async {
                              await showDialog<bool>(
                                context: context,
                                builder: (_) => CashMovementDialog(
                                  shift: shift,
                                  actor: employee,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.point_of_sale),
                            label: const Text('Cerrar turno'),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: LaTerciaColors.danger),
                            onPressed: () async {
                              await showDialog<bool>(
                                context: context,
                                builder: (_) => CloseShiftDialog(
                                  shift: shift,
                                  actor: employee,
                                  symbol: symbol,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Corte X (parcial, turno abierto)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    FutureBuilder(
                      future: ref
                          .read(shiftServiceProvider)
                          .computeSummary(shift.id),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return CutTicket(
                          summary: snapshot.data!,
                          symbol: symbol,
                          isZ: false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
