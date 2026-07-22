import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/employees_provider.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/audit_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/shift_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/supervisor_pin_dialog.dart';
import '../../shell/shift/cut_ticket.dart';
import '../widgets/admin_panel.dart';

/// Historial de cortes Z: cada turno cerrado, tocar para ver su ticket
/// completo (reusa la pantalla de resultado de `CloseShiftDialog`). Se puede
/// eliminar un corte (soft delete, con PIN de supervisor). docs/soft-delete.md.
class ShiftsScreen extends ConsumerStatefulWidget {
  const ShiftsScreen({super.key});

  @override
  ConsumerState<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends ConsumerState<ShiftsScreen> {
  late Future<List<Shift>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Shift>> _load() =>
      ref.read(databaseProvider).shiftsDao.getClosedShifts();

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final symbol = settings['currency_symbol'] ?? r'$';
    final employees = ref.watch(employeesProvider).valueOrNull ?? [];
    final empMap = {for (final e in employees) e.id: e.name};

    return Scaffold(
      backgroundColor: LaTerciaColors.appBg,
      appBar: adminAppBar('Turnos — historial de Cortes Z'),
      body: FutureBuilder<List<Shift>>(
        future: _future,
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
                      onTap: () => _showZ(context, s, symbol),
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
                                fontSize: 12.5, color: LaTerciaColors.tan),
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

  Future<void> _showZ(BuildContext context, Shift shift, String symbol) async {
    final summary = await ref
        .read(shiftServiceProvider)
        .computeSummary(shift.id, countedCash: shift.endingCash);
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: LaTerciaColors.creamAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: CutTicket(summary: summary, symbol: symbol, isZ: true),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Eliminar corte'),
            style: TextButton.styleFrom(foregroundColor: LaTerciaColors.danger),
            onPressed: () => _eliminarCorte(context, shift),
          ),
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

  /// Soft delete de un corte, con PIN de supervisor. El corte desaparece del
  /// historial y de los reportes, pero queda en la BD. docs/soft-delete.md.
  Future<void> _eliminarCorte(BuildContext context, Shift shift) async {
    final actor = ref.read(sessionProvider);
    if (actor == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar este corte?'),
        content: Text(
          'El corte Z ${shift.zNumber != null ? '#${shift.zNumber} ' : ''}'
          'se ocultará del historial y de los reportes. Queda en la base de '
          'datos por si acaso, pero deja de contar. Úsalo para limpiar cortes '
          'de prueba.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: LaTerciaColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    if (!context.mounted) return;

    final allowed = await SupervisorPinDialog.ensure(
      context,
      ref,
      actor: actor,
      action: PermissionAction.eliminar,
      entity: 'shift',
      entityId: shift.id,
    );
    if (!allowed) return;

    await ref.read(databaseProvider).shiftsDao.softDeleteShift(shift.id);
    await ref.read(auditServiceProvider).log(
      employeeId: actor.id,
      action: PermissionAction.eliminar.key,
      entity: 'shift',
      entityId: shift.id,
      detail: {'zNumber': shift.zNumber, 'total': shift.totalSales},
    );
    if (context.mounted) Navigator.pop(context); // cierra el detalle del corte
    _reload();
  }
}
