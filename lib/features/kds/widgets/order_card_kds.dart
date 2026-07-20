import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/models/order_with_items.dart';
import '../../../core/providers/orders_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import 'elapsed_timer.dart';

const _typeInfo = {
  'mesa': (LaTerciaColors.mesa, 'MESA', Icons.table_restaurant),
  'para_llevar': (
    LaTerciaColors.llevar,
    'PARA LLEVAR',
    Icons.shopping_bag_outlined
  ),
  'delivery': (LaTerciaColors.delivery, 'DELIVERY', Icons.delivery_dining),
};

class OrderCardKds extends ConsumerStatefulWidget {
  final OrderWithItems orderWithItems;
  final VoidCallback? onSoundPlay;

  /// Controller de la lista de items. La cocina solo tiene 6 botones físicos
  /// (sin mouse ni pantalla táctil) — `KdsScreen` necesita poder desplazar
  /// ESTA tarjeta desde Anterior/Siguiente cuando le queda contenido oculto
  /// (2026-07-20), así que le pasa su propio controller externo. Si se usa
  /// esta tarjeta suelta (p.ej. en un test) y no se pasa ninguno, se crea y
  /// gestiona uno internamente — comportamiento previo, sin cambios.
  final ScrollController? itemsScrollController;

  const OrderCardKds({
    super.key,
    required this.orderWithItems,
    this.onSoundPlay,
    this.itemsScrollController,
  });

  @override
  ConsumerState<OrderCardKds> createState() => _OrderCardKdsState();
}

class _OrderCardKdsState extends ConsumerState<OrderCardKds>
    with SingleTickerProviderStateMixin {
  late AnimationController _dismissController;
  late Animation<double> _opacityAnimation;
  bool _dismissing = false;

  // 2026-07-20 — reporte del dueño: en pedidos con muchos productos, la
  // lista YA tenía scroll interno, pero sin ninguna señal visual de que
  // había más abajo — se leía como "eso es todo" y se podía perder un
  // producto. `_itemsScrollController` + este flag pintan un degradado con
  // flecha SOLO cuando de verdad falta contenido por ver.
  ScrollController? _ownedController;
  ScrollController get _itemsScrollController =>
      widget.itemsScrollController ?? (_ownedController ??= ScrollController());
  bool _hasMoreBelow = false;

  @override
  void initState() {
    super.initState();
    _dismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacityAnimation =
        Tween<double>(begin: 1, end: 0).animate(_dismissController);
  }

  @override
  void dispose() {
    _dismissController.dispose();
    // Solo si lo creamos nosotros: el externo (pasado por KdsScreen) lo
    // gestiona y libera quien lo creó.
    _ownedController?.dispose();
    super.dispose();
  }

  /// Recalcula si queda contenido por debajo del borde visible de la lista
  /// de items. Se dispara solo por `NotificationListener<ScrollMetricsNotification>`
  /// (layout inicial Y cualquier scroll), nunca desde `build()` — evita
  /// "setState during build".
  void _updateHasMoreBelow(ScrollMetrics m) {
    final hasMore = m.maxScrollExtent > 0 && m.pixels < m.maxScrollExtent - 2;
    if (hasMore == _hasMoreBelow) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _hasMoreBelow = hasMore);
    });
  }

  Future<void> _markEnPrep() async {
    await ref
        .read(ordersProvider.notifier)
        .updateStatus(widget.orderWithItems.order.id, 'en_preparacion');
  }

  Future<void> _markListo() async {
    setState(() => _dismissing = true);
    await _dismissController.forward();
    widget.onSoundPlay?.call();
    await ref
        .read(ordersProvider.notifier)
        .markReady(widget.orderWithItems.order.id);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final warnYellow = int.tryParse(settings['kds_warn_yellow'] ?? '5') ?? 5;
    final warnRed = int.tryParse(settings['kds_warn_red'] ?? '10') ?? 10;

    final order = widget.orderWithItems.order;
    final items = widget.orderWithItems.items;
    final elapsed = DateTime.now().difference(order.createdAt);

    final borderColor = order.status == 'listo'
        ? LaTerciaColors.timerOk
        : ElapsedTimer.colorFor(elapsed, warnYellow, warnRed);

    final type = _typeInfo[order.type] ??
        (LaTerciaColors.kdsMuted, order.type.toUpperCase(), Icons.receipt_long);

    final card =
        _buildCard(order, items, borderColor, type, warnYellow, warnRed);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: _dismissing
          ? FadeTransition(opacity: _opacityAnimation, child: card)
          : card,
    );
  }

  Widget _buildCard(
    Order order,
    List<OrderItem> items,
    Color borderColor,
    (Color, String, IconData) type,
    int warnYellow,
    int warnRed,
  ) {
    final (typeColor, typeLabel, typeIcon) = type;

    return Container(
      decoration: BoxDecoration(
        color: LaTerciaColors.kdsCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // 2026-07-20 (3ª pasada) — min: la tarjeta se encoge a su
          // contenido (pedidos cortos = tarjeta chica) en vez de siempre
          // estirarse al tope disponible. Necesario para que el `Flexible`
          // de los items (abajo) funcione como "crece con el contenido,
          // pero con tope" en vez de "siempre al máximo".
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    order.orderNumber,
                    style: const TextStyle(
                      fontFamily: 'DM Serif Display',
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  formatTime(order.createdAt),
                  style: const TextStyle(
                      color: LaTerciaColors.kdsMuted, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(typeIcon, size: 12, color: typeColor),
                  const SizedBox(width: 4),
                  Text(
                    typeLabel,
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
                color: LaTerciaColors.kdsBorder.withValues(alpha: 0.7),
                height: 22),
            // Items — con degradado + flecha si hay más abajo del corte
            // visible (solo aparece cuando de verdad hace falta desplazar).
            // Flexible (no Expanded, 2026-07-20 3ª pasada): toma solo el
            // alto que su contenido necesita, hasta el tope que imponga el
            // ConstrainedBox exterior (KdsOrderGrid) — con Expanded, la
            // tarjeta SIEMPRE se estiraba al máximo aunque el pedido fuera
            // corto.
            Flexible(
              child: Stack(
                children: [
                  NotificationListener<ScrollMetricsNotification>(
                    onNotification: (n) {
                      _updateHasMoreBelow(n.metrics);
                      return false;
                    },
                    child: Scrollbar(
                      controller: _itemsScrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _itemsScrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final item in items)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                            fontSize: 16.5,
                                            color: Colors.white),
                                        children: [
                                          TextSpan(
                                            text: '${item.quantity}× ',
                                            style: const TextStyle(
                                                color: LaTerciaColors.gold,
                                                fontWeight: FontWeight.w700),
                                          ),
                                          TextSpan(text: item.productName),
                                        ],
                                      ),
                                    ),
                                    if (item.modifiersJson != null &&
                                        item.modifiersJson!.isNotEmpty)
                                      ..._parseModifiers(item.modifiersJson!)
                                          .map(
                                        (m) => Padding(
                                          padding: const EdgeInsets.only(
                                              left: 16, top: 2),
                                          child: Text(
                                            m['included'] == true
                                                ? '↳ ${m['name']} (incluido)'
                                                : '↳ ${m['name']}',
                                            style: const TextStyle(
                                              color: LaTerciaColors.kdsMuted,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (item.itemNote != null &&
                                        item.itemNote!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 16, top: 2),
                                        child: Text(
                                          item.itemNote!,
                                          style: const TextStyle(
                                            color: LaTerciaColors.kdsNoteText,
                                            fontStyle: FontStyle.italic,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            if (order.customerName != null &&
                                order.customerName!.isNotEmpty)
                              _buildNoteBox('Cliente: ${order.customerName}'),
                            if (order.note != null && order.note!.isNotEmpty)
                              _buildNoteBox(order.note!),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_hasMoreBelow)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Container(
                          height: 30,
                          alignment: Alignment.bottomCenter,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                LaTerciaColors.kdsCard.withValues(alpha: 0),
                                LaTerciaColors.kdsCard,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: LaTerciaColors.gold,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Divider(
                color: LaTerciaColors.kdsBorder.withValues(alpha: 0.7),
                height: 22),
            // Footer: timer + actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElapsedTimer(
                  startTime: order.createdAt,
                  warnYellowMinutes: warnYellow,
                  warnRedMinutes: warnRed,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildActions(order),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteBox(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: LaTerciaColors.kdsNoteBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: LaTerciaColors.kdsNoteText,
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildActions(Order order) {
    if (order.status == 'pendiente') {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _markEnPrep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: LaTerciaColors.gold,
                  side: const BorderSide(color: LaTerciaColors.gold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('En prep',
                    style:
                        TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _markListo,
                style: FilledButton.styleFrom(
                  backgroundColor: LaTerciaColors.timerOk,
                  foregroundColor: LaTerciaColors.kdsBg,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.check, size: 17),
                label: const Text('Listo',
                    style:
                        TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      );
    }

    if (order.status == 'en_preparacion') {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton.icon(
          onPressed: _markListo,
          style: FilledButton.styleFrom(
            backgroundColor: LaTerciaColors.timerOk,
            foregroundColor: LaTerciaColors.kdsBg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.check, size: 17),
          label: const Text('Listo',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
        ),
      );
    }

    // 'listo' but still visible here means it hasn't been paid yet — the
    // order clears automatically from the KDS once the cashier charges it
    // (see OrdersNotifier.markPaid / markReady). No manual "deliver" action
    // exists, since completing an unpaid order would hide it from both the
    // kitchen and the register.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: LaTerciaColors.timerOk.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: LaTerciaColors.timerOk.withValues(alpha: 0.5)),
      ),
      child: const Center(
        child: Text(
          '✓ Listo · esperando cobro',
          style: TextStyle(
            color: LaTerciaColors.timerOk,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _parseModifiers(String json) {
    try {
      final list = jsonDecode(json) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
