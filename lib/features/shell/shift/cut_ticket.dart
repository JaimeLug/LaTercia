import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/settings_provider.dart';
import '../../../core/services/print_service.dart';
import '../../../core/services/shift_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/csv_exporter.dart';
import '../../../core/utils/formatters.dart';

/// Receipt-styled read-out of a [ShiftSummary] — used for both Corte X (the
/// open shift, no `countedCash`) and Corte Z (a closed shift, always has
/// one). Mirrors the visual language of `ReceiptDialog` for consistency.
class CutTicket extends ConsumerWidget {
  final ShiftSummary summary;
  final String symbol;
  final bool isZ;

  const CutTicket({
    super.key,
    required this.summary,
    required this.symbol,
    required this.isZ,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = summary;
    final shift = s.shift;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LaTerciaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isZ ? 'CORTE Z' : 'CORTE X (parcial)',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (isZ && shift.zNumber != null)
            Text(
              'Folio Z-${shift.zNumber}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          Text(
            'Turno #${shift.id} · ${formatDateTime(shift.startedAt)}'
            '${shift.endedAt != null ? ' — ${formatDateTime(shift.endedAt!)}' : ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const Divider(height: 24),
          _row('Fondo inicial', formatCurrency(shift.startingCash, symbol)),
          _row('Ventas efectivo', formatCurrency(s.cashSales, symbol)),
          _row('Depósitos', formatCurrency(s.deposits, symbol)),
          _row('Retiros', '-${formatCurrency(s.withdrawals, symbol)}'),
          _row('Esperado en caja', formatCurrency(s.expectedCash, symbol),
              bold: true),
          if (s.countedCash != null) ...[
            const SizedBox(height: 6),
            _row('Efectivo contado',
                formatCurrency(s.countedCash!, symbol), bold: true),
            _row(
              'Diferencia',
              '${s.difference! >= 0 ? '+' : ''}${formatCurrency(s.difference!, symbol)}',
              bold: true,
              color: s.difference == 0
                  ? LaTerciaColors.success
                  : LaTerciaColors.danger,
            ),
          ],
          const Divider(height: 24),
          const Text('Desglose por método de pago',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          if (s.paymentsByMethod.isEmpty)
            const Text('Sin pagos registrados',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ...s.paymentsByMethod.entries
              .map((e) => _row(e.key, formatCurrency(e.value, symbol))),
          const Divider(height: 24),
          _row('Descuentos otorgados',
              formatCurrency(s.discountsTotal, symbol)),
          if (s.tipsTotal > 0)
            _row('Propinas', formatCurrency(s.tipsTotal, symbol)),
          if (s.refundsTotal > 0)
            _row('Reembolsos', '-${formatCurrency(s.refundsTotal, symbol)}'),
          _row('Cancelaciones',
              '${s.cancelledCount} (${formatCurrency(s.cancelledAmount, symbol)})'),
          if (shift.totalSales > 0 || isZ)
            _row('Total ventas', formatCurrency(shift.totalSales, symbol),
                bold: true),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Imprimir'),
                  onPressed: () => _print(context, ref),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Exportar CSV'),
                  onPressed: () => _export(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _print(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider).valueOrNull ?? {};
    final printService = ref.read(printServiceProvider);

    if (!printService.printingEnabled(settings)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'La impresión está desactivada. Actívala en Configuración.'),
          ),
        );
      }
      return;
    }

    await printService.printCutTicket(
        summary: summary, settings: settings, isZ: isZ);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corte enviado a la cola de impresión.')),
      );
    }
  }

  Future<void> _export(BuildContext context) async {
    final rows = <Map<String, dynamic>>[
      {'Concepto': 'Fondo inicial', 'Monto': summary.shift.startingCash},
      {'Concepto': 'Ventas efectivo', 'Monto': summary.cashSales},
      {'Concepto': 'Depósitos', 'Monto': summary.deposits},
      {'Concepto': 'Retiros', 'Monto': -summary.withdrawals},
      {'Concepto': 'Esperado en caja', 'Monto': summary.expectedCash},
      if (summary.countedCash != null)
        {'Concepto': 'Efectivo contado', 'Monto': summary.countedCash},
      if (summary.difference != null)
        {'Concepto': 'Diferencia', 'Monto': summary.difference},
      for (final e in summary.paymentsByMethod.entries)
        {'Concepto': 'Pago ${e.key}', 'Monto': e.value},
      {'Concepto': 'Descuentos', 'Monto': summary.discountsTotal},
      {'Concepto': 'Propinas', 'Monto': summary.tipsTotal},
      {'Concepto': 'Reembolsos', 'Monto': -summary.refundsTotal},
      {'Concepto': 'Cancelaciones (monto)', 'Monto': summary.cancelledAmount},
      {'Concepto': 'Cancelaciones (conteo)', 'Monto': summary.cancelledCount},
      {'Concepto': 'Total ventas', 'Monto': summary.shift.totalSales},
    ];
    await exportToCSV(
      context: context,
      rows: rows,
      headers: ['Concepto', 'Monto'],
      defaultFileName:
          '${isZ ? 'corte-z' : 'corte-x'}-turno${summary.shift.id}.csv',
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: color,
      fontSize: bold ? 15 : 13,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
