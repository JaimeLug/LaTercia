import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/employees_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/shift_service.dart';
import '../../../core/utils/formatters.dart';
import '../../shell/shift/cut_ticket.dart';

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
      appBar: AppBar(title: const Text('Turnos — historial de Cortes Z')),
      body: FutureBuilder<List<Shift>>(
        future: ref.read(databaseProvider).shiftsDao.getClosedShifts(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final shifts = snapshot.data!;
          if (shifts.isEmpty) {
            return const Center(child: Text('Aún no hay turnos cerrados.'));
          }
          return ListView.separated(
            itemCount: shifts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final s = shifts[i];
              return ListTile(
                leading: CircleAvatar(
                    child: Text(s.zNumber != null ? 'Z${s.zNumber}' : '—')),
                title: Text(empMap[s.employeeId] ?? 'Empleado #${s.employeeId}'),
                subtitle: Text(
                    '${formatDateTime(s.startedAt)} → ${s.endedAt != null ? formatDateTime(s.endedAt!) : '-'}'),
                trailing: Text(formatCurrency(s.totalSales, symbol)),
                onTap: () => _showZ(context, ref, s, symbol),
              );
            },
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
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: CutTicket(summary: summary, symbol: symbol, isZ: true),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
