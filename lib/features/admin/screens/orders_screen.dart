import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/employees_provider.dart';
import '../../../core/providers/orders_provider.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/audit_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/print_service.dart';
import '../../../core/services/refund_service.dart';
import '../../../core/utils/csv_exporter.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/supervisor_pin_dialog.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now().add(const Duration(days: 1)),
  );
  String _statusFilter = 'Todos';
  int? _employeeFilter;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final symbol = settings['currency_symbol'] ?? r'$';
    final employees = ref.watch(employeesProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Órdenes'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Exportar CSV'),
            onPressed: () => _export(context, symbol),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                      '${formatDate(_dateRange.start)} — ${formatDate(_dateRange.end)}'),
                  onPressed: _pickDateRange,
                ),
                DropdownButton<String>(
                  value: _statusFilter,
                  items: ['Todos', 'pendiente', 'en_preparacion',
                      'listo', 'entregado', 'cancelado']
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s == 'Todos'
                                ? 'Todos'
                                : s),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _statusFilter = v!),
                ),
                DropdownButton<int?>(
                  value: _employeeFilter,
                  hint: const Text('Empleado'),
                  items: [
                    const DropdownMenuItem<int?>(
                        value: null, child: Text('Todos')),
                    ...employees.map((e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(e.name),
                        )),
                  ],
                  onChanged: (v) =>
                      setState(() => _employeeFilter = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Order>>(
              future: ref
                  .read(databaseProvider)
                  .ordersDao
                  .getOrdersByDateRange(
                      _dateRange.start, _dateRange.end),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                var orders = snapshot.data!;
                if (_statusFilter != 'Todos') {
                  orders = orders
                      .where((o) => o.status == _statusFilter)
                      .toList();
                }
                if (_employeeFilter != null) {
                  orders = orders
                      .where(
                          (o) => o.employeeId == _employeeFilter)
                      .toList();
                }

                final empMap = {
                  for (final e in employees) e.id: e.name
                };

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('# Orden')),
                      DataColumn(label: Text('Tipo')),
                      DataColumn(label: Text('Cliente')),
                      DataColumn(label: Text('Empleado')),
                      DataColumn(label: Text('Total')),
                      DataColumn(label: Text('Estado')),
                      DataColumn(label: Text('Hora')),
                    ],
                    rows: orders.map((o) {
                      return DataRow(
                        onSelectChanged: (_) =>
                            _showDetail(context, o),
                        cells: [
                          DataCell(Text(o.orderNumber)),
                          DataCell(Text(o.type)),
                          DataCell(
                              Text(o.customerName ?? '-')),
                          DataCell(Text(
                              empMap[o.employeeId] ?? '-')),
                          DataCell(Text(
                              formatCurrency(o.total, symbol))),
                          DataCell(_StatusChip(o.status)),
                          DataCell(Text(
                              formatDateTime(o.createdAt))),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  Future<void> _showDetail(BuildContext context, Order order) async {
    final db = ref.read(databaseProvider);
    final items = await db.orderItemsDao.getItemsForOrder(order.id);
    final payments = await db.paymentsDao.getPaymentsForOrder(order.id);
    final settings = ref.read(settingsProvider).valueOrNull ?? {};
    final symbol = settings['currency_symbol'] ?? r'$';

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Orden ${order.orderNumber}'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Tipo: ${order.type}'),
                Text('Estado: ${order.status}'),
                Text(
                    'Pago: ${order.paymentStatus}'),
                if (order.note != null)
                  Text('Nota: ${order.note}'),
                const Divider(),
                const Text('Artículos:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold)),
                ...items.map((i) => Text(
                    '${i.quantity}× ${i.productName} — ${formatCurrency(i.unitPrice * i.quantity, symbol)}')),
                const Divider(),
                Text(
                    'Subtotal: ${formatCurrency(order.subtotal, symbol)}'),
                if (order.discountAmount > 0)
                  Text(
                      'Descuento: -${formatCurrency(order.discountAmount, symbol)}'),
                Text(
                    'Total: ${formatCurrency(order.total, symbol)}'),
                if (payments.isNotEmpty) ...[
                  const Divider(),
                  const Text('Pago:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold)),
                  ...payments.map((p) =>
                      Text('${p.method}: ${formatCurrency(p.amountTendered, symbol)}')),
                ],
                if (order.cancelReason != null) ...[
                  const Divider(),
                  Text(
                      'Razón de cancelación: ${order.cancelReason}',
                      style: const TextStyle(
                          color: Colors.red)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (payments.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.print, size: 17),
              label: const Text('Reimprimir ticket'),
              onPressed: () =>
                  _reprintTicket(context, order, items, payments),
            ),
          if (order.paymentStatus == 'pagado')
            TextButton.icon(
              icon: const Icon(Icons.currency_exchange, size: 17),
              label: const Text('Reembolsar'),
              onPressed: () => _showRefundDialog(context, order),
            ),
          if (order.status != 'entregado' &&
              order.status != 'cancelado')
            TextButton(
              onPressed: () =>
                  _showCancelDialog(context, order),
              style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).colorScheme.error),
              child: const Text('Cancelar orden'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Reconstruye el ticket de la orden con la marca "— REIMPRESIÓN —" y lo
  /// manda a la cola de impresión. Registra `reimprimir` en el audit_log.
  /// Admin/gerente ya tienen acceso a esta pantalla, así que no hace falta un
  /// gate de supervisor adicional.
  Future<void> _reprintTicket(
    BuildContext context,
    Order order,
    List<OrderItem> items,
    List<Payment> payments,
  ) async {
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

    // El empleado que atendió la orden (para la línea "Atendió"); si no se
    // encuentra, cae en el actor de sesión.
    final actor = ref.read(sessionProvider);
    final employeesList = ref.read(employeesProvider).valueOrNull ?? [];
    Employee? ticketEmployee;
    for (final e in employeesList) {
      if (e.id == order.employeeId) {
        ticketEmployee = e;
        break;
      }
    }
    ticketEmployee ??= actor;
    if (ticketEmployee == null) return;

    await printService.printSaleAndKitchen(
      order: order,
      items: items,
      payment: payments.last,
      settings: settings,
      employee: ticketEmployee,
      reprint: true,
    );

    await ref.read(auditServiceProvider).log(
          employeeId: actor?.id,
          action: PermissionAction.reimprimir.key,
          entity: 'order',
          entityId: order.id,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reimpresión enviada a la cola.')),
      );
    }
  }

  /// Reembolso post-pago (4.4): monto (default el total), motivo y devolución de
  /// stock opcional. Exige PIN de supervisor (cajero) y registra un
  /// contra-movimiento en `refunds` sin editar la venta.
  Future<void> _showRefundDialog(BuildContext context, Order order) async {
    final symbol =
        ref.read(settingsProvider).valueOrNull?['currency_symbol'] ?? r'$';
    final amountCtrl =
        TextEditingController(text: order.total.toStringAsFixed(2));
    final reasonCtrl = TextEditingController();
    var restock = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text('Reembolsar ${order.orderNumber}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixText: '$symbol ',
                  labelText: 'Monto a reembolsar',
                  helperText:
                      'Total pagado: ${formatCurrency(order.total, symbol)}',
                ),
              ),
              TextField(
                controller: reasonCtrl,
                decoration:
                    const InputDecoration(labelText: 'Motivo del reembolso'),
              ),
              CheckboxListTile(
                value: restock,
                onChanged: (v) => setLocal(() => restock = v ?? false),
                title: const Text('Devolver stock al inventario'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Volver')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Reembolsar')),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) return;

    final actor = ref.read(sessionProvider);
    // Un reembolso siempre debe quedar atribuido a un empleado real (A3): sin
    // sesión no se registra (nunca un employeeId inventado como 0).
    if (actor == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicia sesión para reembolsar.')),
        );
      }
      return;
    }
    if (!context.mounted) return;
    // El PIN de supervisor (si el actor es cajero) queda registrado por el
    // propio diálogo en audit_log con ambos empleados.
    final allowed = await SupervisorPinDialog.ensure(
      context,
      ref,
      actor: actor,
      action: PermissionAction.reembolso,
      entity: 'order',
      entityId: order.id,
    );
    if (!allowed) return;

    try {
      await ref.read(refundServiceProvider).refund(
            orderId: order.id,
            amount: amount,
            reason: reasonCtrl.text.isEmpty ? null : reasonCtrl.text,
            employeeId: actor.id,
            restock: restock,
          );
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Reembolso de ${formatCurrency(amount, symbol)} registrado.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al reembolsar: $e')),
        );
      }
    }
  }

  Future<void> _showCancelDialog(
      BuildContext context, Order order) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar orden'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
              labelText: 'Razón de cancelación'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Volver')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar cancelación')),
        ],
      ),
    );
    if (confirmed == true) {
      final actor = ref.read(sessionProvider);
      if (actor != null) {
        if (!context.mounted) return;
        final allowed = await SupervisorPinDialog.ensure(
          context,
          ref,
          actor: actor,
          action: PermissionAction.anular,
          entity: 'order',
          entityId: order.id,
        );
        if (!allowed) return;
      }
      if (!context.mounted) return;
      await ref
          .read(ordersProvider.notifier)
          .cancelOrder(
              order.id, reasonCtrl.text, order.tableId,
              employeeId: actor?.id);
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _export(BuildContext context, String symbol) async {
    final orders = await ref
        .read(databaseProvider)
        .ordersDao
        .getOrdersByDateRange(_dateRange.start, _dateRange.end);
    if (!context.mounted) return;
    await exportToCSV(
      context: context,
      rows: orders.map((o) => {
        'Número': o.orderNumber,
        'Tipo': o.type,
        'Cliente': o.customerName ?? '',
        'Total': o.total.toString(),
        'Estado': o.status,
        'Fecha': formatDateTime(o.createdAt),
      }).toList(),
      headers: ['Número', 'Tipo', 'Cliente', 'Total', 'Estado', 'Fecha'],
      defaultFileName: 'ordenes-${formatDate(DateTime.now())}.csv',
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final colors = {
      'pendiente': Colors.amber,
      'en_preparacion': Colors.orange,
      'listo': Colors.green,
      'entregado': Colors.blue,
      'cancelado': Colors.red,
    };
    final color = colors[status] ?? Colors.grey;
    return Chip(
      label: Text(status, style: const TextStyle(fontSize: 11)),
      backgroundColor: color.withValues(alpha: 0.2),
      side: BorderSide(color: color),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
