import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/orders_provider.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/checkout_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/print_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/supervisor_pin_dialog.dart';
import '../../../core/utils/formatters.dart';
import '../../kds/widgets/elapsed_timer.dart';
import 'payment_modal.dart';

class OrderQueuePanel extends ConsumerStatefulWidget {
  const OrderQueuePanel({super.key});

  @override
  ConsumerState<OrderQueuePanel> createState() => _OrderQueuePanelState();
}

class _OrderQueuePanelState extends ConsumerState<OrderQueuePanel> {
  bool _expanded = false;
  String _filter = 'pendiente';

  static const _filters = [
    'pendiente',
    'en_preparacion',
    'listo',
    'entregado',
    'Todos',
  ];

  static bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  static const _labels = {
    'Todos': 'Todos',
    'pendiente': 'Pendiente',
    'en_preparacion': 'En prep.',
    'listo': 'Listo',
    'entregado': 'Entregado',
  };

  static const _typeIcons = {
    'mesa': Icons.table_restaurant,
    'para_llevar': Icons.shopping_bag_outlined,
    'delivery': Icons.delivery_dining,
  };

  Color _typeColor(String type) {
    switch (type) {
      case 'mesa':
        return LaTerciaColors.mesa;
      case 'delivery':
        return LaTerciaColors.delivery;
      default:
        return LaTerciaColors.llevar;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ordersProvider holds every order that isn't delivered/cancelled yet,
    // with no age limit — a mesa order abandoned mid-testing days ago would
    // otherwise sit here forever. The queue only cares about today's orders.
    final activeOrders = ref
        .watch(ordersProvider)
        .where((o) => _isToday(o.order.createdAt))
        .toList();
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final symbol = settings['currency_symbol'] ?? r'$';
    final warnYellow = int.tryParse(settings['kds_warn_yellow'] ?? '5') ?? 5;
    final warnRed = int.tryParse(settings['kds_warn_red'] ?? '10') ?? 10;

    return Container(
      color: LaTerciaColors.darkBrown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Text(
                    'COLA · ${activeOrders.length} activas',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(width: 14),
                  if (!_expanded)
                    Expanded(
                      child: SizedBox(
                        height: 28,
                        child: activeOrders.isEmpty
                            ? const Center(
                                child: Text('Sin pedidos en cola',
                                    style: TextStyle(
                                        color: Color(0xFF9C8B72),
                                        fontSize: 12)))
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: activeOrders.length,
                                itemBuilder: (ctx, i) {
                                  final o = activeOrders[i].order;
                                  final color = _typeColor(o.type);
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color:
                                                color.withValues(alpha: 0.6)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                              _typeIcons[o.type] ??
                                                  Icons.receipt_long,
                                              size: 12,
                                              color: color),
                                          const SizedBox(width: 6),
                                          Text(o.orderNumber,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(width: 6),
                                          ElapsedTimer(
                                            startTime: o.createdAt,
                                            warnYellowMinutes: warnYellow,
                                            warnRedMinutes: warnRed,
                                            fontSize: 11.5,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    )
                  else
                    const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_more : Icons.expand_less,
                    color: Colors.white70,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              constraints: const BoxConstraints(maxHeight: 280),
              color: LaTerciaColors.cream,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      children: _filters.map((f) {
                        final selected = _filter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _FilterPill(
                            label: _labels[f] ?? f,
                            selected: selected,
                            onTap: () => setState(() => _filter = f),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: FutureBuilder<List<Order>>(
                      future: _fetchOrders(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final orders = snapshot.data!;
                        final filtered = _filter == 'Todos'
                            ? orders
                            : orders.where((o) => o.status == _filter).toList();

                        if (filtered.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Sin órdenes',
                                style: TextStyle(color: LaTerciaColors.tan)),
                          );
                        }

                        return ListView(
                          shrinkWrap: true,
                          children: filtered
                              .map((o) => _OrderRow(order: o, symbol: symbol))
                              .toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<List<Order>> _fetchOrders() async {
    final db = ref.read(databaseProvider);
    return db.ordersDao.getTodayOrders();
  }
}

class _OrderRow extends ConsumerWidget {
  final Order order;
  final String symbol;
  const _OrderRow({required this.order, required this.symbol});

  static const _statusColors = {
    'pendiente': LaTerciaColors.timerWarn,
    'en_preparacion': LaTerciaColors.mesa,
    'listo': LaTerciaColors.success,
    'entregado': LaTerciaColors.llevar,
    'cancelado': LaTerciaColors.danger,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 9,
        backgroundColor: _statusColors[order.status] ?? LaTerciaColors.tan,
      ),
      title: Text('${order.orderNumber} — ${order.type.toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle: Text(formatDateTime(order.createdAt),
          style: const TextStyle(fontSize: 11.5)),
      trailing: Text(
        formatCurrency(order.total, symbol),
        style: const TextStyle(
            fontWeight: FontWeight.w700, color: LaTerciaColors.darkBrown),
      ),
      onTap: () => _showDetail(context, ref),
    );
  }

  Future<void> _showDetail(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final items = await db.orderItemsDao.getItemsForOrder(order.id);
    if (!context.mounted) return;

    // A pending order (sent to the kitchen without charging) can still be
    // collected here — the pay-at-the-end mesa flow.
    final canCharge =
        order.paymentStatus == 'pendiente' && order.status != 'cancelado';

    // A paid order that the kitchen never marked "listo" would otherwise sit
    // in the active queue forever (paid ≠ delivered by design). Let the
    // cashier close it out from here without needing the KDS. markReady on a
    // paid order delivers it and frees its table.
    final canDeliver = order.paymentStatus == 'pagado' &&
        order.status != 'entregado' &&
        order.status != 'cancelado';

    // Cancelling (anular) is a supervisor-gated action; available while the
    // order is still open (not already delivered or cancelled).
    final canCancel =
        order.status != 'entregado' && order.status != 'cancelado';

    // Anular una línea (4.3) solo aplica antes de pagar: una línea ya pagada se
    // devuelve con un reembolso (4.4).
    final canVoidLines =
        order.paymentStatus == 'pendiente' && order.status != 'cancelado';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Orden ${order.orderNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${order.type}'),
            Text('Estado: ${order.status}'),
            Text('Pago: ${order.paymentStatus}'),
            Text('Total: ${formatCurrency(order.total, symbol)}'),
            const Divider(),
            ...items.map((i) {
              final cancelled = i.itemStatus == 'cancelado';
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      '${i.quantity}× ${i.productName}',
                      style: cancelled
                          ? const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: LaTerciaColors.tan)
                          : null,
                    ),
                  ),
                  if (canVoidLines && !cancelled)
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _voidItem(context, ref, i);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.backspace_outlined,
                            size: 16, color: LaTerciaColors.danger),
                      ),
                    ),
                ],
              );
            }),
            if (order.note != null && order.note!.isNotEmpty) ...[
              const Divider(),
              Text('Nota: ${order.note}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (canCancel)
            TextButton.icon(
              icon: const Icon(Icons.cancel_outlined, size: 17),
              label: const Text('Anular'),
              style:
                  TextButton.styleFrom(foregroundColor: LaTerciaColors.danger),
              onPressed: () {
                Navigator.pop(context);
                _cancelOrder(context, ref);
              },
            ),
          if (canDeliver)
            TextButton.icon(
              icon: const Icon(Icons.done_all, size: 17),
              label: const Text('Marcar entregado'),
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(ordersProvider.notifier).markReady(order.id);
              },
            ),
          if (canCharge)
            FilledButton.icon(
              icon: const Icon(Icons.payments, size: 17),
              label: const Text('Cobrar'),
              onPressed: () {
                Navigator.pop(context);
                _chargePending(context, ref);
              },
            ),
        ],
      ),
    );
  }

  /// Cancels (anula) the order: asks for a reason, requires supervisor
  /// authorization if the actor is a cashier (same `PermissionAction.anular`
  /// gate as the admin Orders screen), then restores stock and records the
  /// cancellation in the audit log.
  Future<void> _cancelOrder(BuildContext context, WidgetRef ref) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Anular orden ${order.orderNumber}'),
        content: TextField(
          controller: reasonCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Razón de la anulación'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar anulación'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

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

    await ref.read(ordersProvider.notifier).cancelOrder(
          order.id,
          reasonCtrl.text,
          order.tableId,
          employeeId: actor?.id,
        );
  }

  /// Anula una sola línea de la orden (4.3): pide motivo, exige PIN de
  /// supervisor si el actor es cajero (mismo gate `PermissionAction.anular`),
  /// devuelve el stock, reduce los montos de la orden y reimprime la comanda
  /// marcada "CANCELADO" (best-effort).
  Future<void> _voidItem(
      BuildContext context, WidgetRef ref, OrderItem item) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Anular ${item.quantity}× ${item.productName}'),
        content: TextField(
          controller: reasonCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Razón de la anulación'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Anular línea'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final actor = ref.read(sessionProvider);
    if (actor != null) {
      if (!context.mounted) return;
      final allowed = await SupervisorPinDialog.ensure(
        context,
        ref,
        actor: actor,
        action: PermissionAction.anular,
        entity: 'order_item',
        entityId: item.id,
      );
      if (!allowed) return;
    }

    await ref.read(ordersProvider.notifier).voidOrderItem(
          orderId: order.id,
          item: item,
          reason: reasonCtrl.text,
          employeeId: actor?.id,
        );

    // Reimpresión best-effort de la comanda "CANCELADO" (detrás de flag).
    final settings = ref.read(settingsProvider).valueOrNull ?? {};
    unawaited(ref.read(printServiceProvider).printItemCancellation(
          order: order,
          item: item,
          settings: settings,
        ));
  }

  /// Opens the payment modal to collect a pending order, charging the
  /// already-created order (not creating a new one) via
  /// [CheckoutService.chargeExistingOrder].
  void _chargePending(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => PaymentModal(
        total: order.total,
        // La comanda de cocina ya se imprimió al enviar la orden a cocina;
        // este es el cobro diferido, solo hay que imprimir el ticket de venta.
        printKitchenComanda: false,
        onCheckout: ({required List<PaymentDraft> payments}) async {
          final employee = ref.read(sessionProvider);
          if (employee == null) return null;
          final result =
              await ref.read(checkoutServiceProvider).chargeExistingOrder(
                    orderId: order.id,
                    employeeId: employee.id,
                    payments: payments,
                  );
          await ref.read(ordersProvider.notifier).loadActiveOrders();
          return result;
        },
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? LaTerciaColors.burntOrange : Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
                color: selected
                    ? LaTerciaColors.burntOrange
                    : LaTerciaColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : LaTerciaColors.cocoa,
            ),
          ),
        ),
      ),
    );
  }
}
