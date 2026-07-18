import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/employees_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/shift_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../shell/shift/cut_ticket.dart';
import '../widgets/admin_panel.dart';

/// Corte Z history: every closed shift, tap to see its full ticket. Backs
/// the "should also be viewable later for closed shifts" requirement from
/// 2.3 — the same result screen `CloseShiftDialog` shows right after
/// closing is reused here.
class ShiftsScreen extends ConsumerWidget {
  const ShiftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final symbol = settings['currency_symbol'] ?? r'$';
    final employees = ref.watch(employeesProvider).valueOrNull ?? [];
    final empMap = {for (final e in employees) e.id: e.name};

    return Scaffold(
      backgroundColor: LaTerciaColors.appBg,
      appBar: adminAppBar('Turnos — historial de Cortes Z'),
      body: FutureBuilder<List<Shift>>(
        future: ref.read(databaseProvider).shiftsDao.getClosedShifts(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) return adminLoading();
          final shifts = snapshot.data!;
          if (shifts.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.point_of_sale_outlined,
              message: 'Aún no hay turnos cerrados.\n'
                  'Aparecerán aquí después del primer corte Z.',
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: AdminPanel(
              child: Column(
                children: [
                  const AdminHeaderRow(cells: [
                    SizedBox(width: 56, child: Center(child: Text('Z'))),
                    Expanded(flex: 3, child: Text('EMPLEADO')),
                    Expanded(flex: 4, child: Text('PERIODO')),
                    Expanded(
                        flex: 2,
                        child: Text('TOTAL', textAlign: TextAlign.right)),
                  ]),
                  ...shifts.asMap().entries.map((entry) {
                    final s = entry.value;
                    final isLast = entry.key == shifts.length - 1;
                    return AdminRow(
                      isLast: isLast,
                      onTap: () => _showZ(context, ref, s, symbol),
                      cells: [
                        SizedBox(
                          width: 56,
                          child: Center(
                            child: Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: LaTerciaColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                s.zNumber != null ? '${s.zNumber}' : '—',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                    color: LaTerciaColors.burntOrange),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                              empMap[s.employeeId] ??
                                  'Empleado #${s.employeeId}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: LaTerciaColors.darkBrown)),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            '${formatDateTime(s.startedAt)}  →  '
                            '${s.endedAt != null ? formatDateTime(s.endedAt!) : '—'}',
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: LaTerciaColors.tan),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            formatCurrency(s.totalSales, symbol),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: LaTerciaColors.darkBrown),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showZ(
      BuildContext context, WidgetRef ref, Shift shift, String symbol) async {
    final summary = await ref
        .read(shiftServiceProvider)
        .computeSummary(shift.id, countedCash: shift.endingCash);
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: LaTerciaColors.creamAlt,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: CutTicket(summary: summary, symbol: symbol, isZ: true),
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: LaTerciaColors.burntOrange),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
