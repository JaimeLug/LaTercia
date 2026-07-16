import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/order_with_items.dart';
import '../../core/providers/orders_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/formatters.dart';
import 'widgets/order_card_kds.dart';

class KdsScreen extends ConsumerStatefulWidget {
  const KdsScreen({super.key});

  @override
  ConsumerState<KdsScreen> createState() => _KdsScreenState();
}

class _KdsScreenState extends ConsumerState<KdsScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  Timer? _clockTimer;
  Timer? _rotateTimer;
  String _clockStr = '';
  Set<int> _prevOrderIds = {};
  bool _hasLoadedOnce = false;
  late final AnimationController _pulseController;

  // FASE 5.3 — alto tráfico.
  bool _allDay = false; // vista consolidada "7× Frappé de Café"
  int _page = 0; // página actual de tarjetas
  int _pageCount = 1; // calculado en build; lo usa el auto-rotate

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    // Auto-rotación de páginas para un tablero de pared sin tocar (5.3).
    _rotateTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!_allDay && _pageCount > 1 && mounted) {
        setState(() => _page = (_page + 1) % _pageCount);
      }
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _rotateTimer?.cancel();
    _pulseController.dispose();
    _player.dispose();
    super.dispose();
  }

  void _updateClock() {
    setState(() => _clockStr = formatTime(DateTime.now()));
  }

  Future<void> _playNewOrder(bool enabled) async {
    if (!enabled) return;
    try {
      await _player.play(AssetSource('sounds/chime_new_order.mp3'));
    } catch (e, st) {
      appLogger.warn('No se pudo reproducir el sonido de nueva orden', e, st);
    }
  }

  Future<void> _playOrderDone() async {
    try {
      await _player.play(AssetSource('sounds/chime_order_done.mp3'));
    } catch (e, st) {
      appLogger.warn('No se pudo reproducir el sonido de orden lista', e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final businessName = settings['business_name'] ?? 'La Tercia';
    final soundEnabled = settings['kds_sound'] == 'true';

    // Detect new orders
    final active = orders
        .where((o) =>
            o.order.status == 'pendiente' || o.order.status == 'en_preparacion')
        .toList()
      ..sort((a, b) => a.order.createdAt.compareTo(b.order.createdAt));

    // Compare order IDs (not counts) so a new order arriving at the same
    // moment another one is completed — which leaves the total count
    // unchanged — still triggers the chime.
    final activeIds = active.map((o) => o.order.id).toSet();
    final newIds = activeIds.difference(_prevOrderIds);
    if (newIds.isNotEmpty && _hasLoadedOnce) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playNewOrder(soundEnabled);
      });
    }
    _prevOrderIds = activeIds;
    _hasLoadedOnce = true;

    return Scaffold(
      backgroundColor: LaTerciaColors.kdsBg,
      body: Column(
        children: [
          _buildHeader(businessName, active.length),
          Expanded(
            child: active.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            color: LaTerciaColors.timerOk, size: 56),
                        SizedBox(height: 14),
                        Text(
                          'Sin pedidos',
                          style: TextStyle(
                            fontFamily: 'DM Serif Display',
                            color: LaTerciaColors.timerOk,
                            fontSize: 40,
                          ),
                        ),
                      ],
                    ),
                  )
                : _allDay
                    ? _buildAllDay(active)
                    : _buildPaginatedGrid(active),
          ),
        ],
      ),
    );
  }

  /// Tarjetas paginadas de tamaño fijo: nunca se encogen (legibilidad a 2 m).
  /// Lo que no cabe en la pantalla pasa a la siguiente página (5.3).
  Widget _buildPaginatedGrid(List<OrderWithItems> active) {
    return LayoutBuilder(builder: (ctx, c) {
      const cardW = 320.0, cardH = 452.0, gap = 16.0, pad = 20.0, barH = 46.0;
      final cols =
          ((c.maxWidth - pad * 2 + gap) / (cardW + gap)).floor().clamp(1, 99);
      final rows = ((c.maxHeight - pad * 2 - barH + gap) / (cardH + gap))
          .floor()
          .clamp(1, 99);
      final perPage = (cols * rows).clamp(1, 999);
      final pageCount = (active.length / perPage).ceil().clamp(1, 999);
      // Guardado para el auto-rotate; clamp de la página actual.
      _pageCount = pageCount;
      final page = _page.clamp(0, pageCount - 1);
      if (_page != page) _page = page;

      final start = page * perPage;
      final end = (start + perPage) > active.length
          ? active.length
          : (start + perPage);
      final slice = active.sublist(start, end);

      return Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(pad),
              child: Align(
                alignment: Alignment.topLeft,
                child: Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final o in slice)
                      SizedBox(
                        width: cardW,
                        height: cardH,
                        child: OrderCardKds(
                          key: ValueKey(o.order.id),
                          orderWithItems: o,
                          onSoundPlay: _playOrderDone,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (pageCount > 1) _buildPageBar(page, pageCount),
        ],
      );
    });
  }

  Widget _buildPageBar(int page, int pageCount) {
    return Container(
      height: 46,
      color: LaTerciaColors.kdsPanel,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () => setState(
                () => _page = (page - 1 + pageCount) % pageCount),
          ),
          Text(
            'Página ${page + 1} / $pageCount',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () => setState(() => _page = (page + 1) % pageCount),
          ),
        ],
      ),
    );
  }

  /// Vista all-day: consolida las cantidades pendientes por producto en toda la
  /// cocina ("7× Frappé de Café"), en texto grande legible a distancia (5.3).
  Widget _buildAllDay(List<OrderWithItems> active) {
    final counts = <String, int>{};
    for (final o in active) {
      for (final it in o.items) {
        if (it.itemStatus == 'listo' || it.itemStatus == 'cancelado') continue;
        counts[it.productName] = (counts[it.productName] ?? 0) + it.quantity;
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      itemCount: entries.length,
      separatorBuilder: (_, __) =>
          const Divider(color: LaTerciaColors.kdsMuted, height: 1),
      itemBuilder: (ctx, i) {
        final e = entries[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  '${e.value}×',
                  style: const TextStyle(
                    fontFamily: 'DM Serif Display',
                    color: LaTerciaColors.gold,
                    fontSize: 44,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  e.key,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(String businessName, int activeCount) {
    return Container(
      height: 68,
      color: LaTerciaColors.kdsPanel,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Image.asset('assets/images/logo-color.png',
              width: 34, height: 34, cacheWidth: 80),
          const SizedBox(width: 12),
          Text(
            businessName,
            style: const TextStyle(
              fontFamily: 'DM Serif Display',
              color: Colors.white,
              fontSize: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'COCINA',
            style: TextStyle(
              color: LaTerciaColors.kdsMuted,
              fontSize: 15,
              letterSpacing: 4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Toggle vista all-day (consolidada) ↔ tarjetas (5.3).
          TextButton.icon(
            onPressed: () => setState(() => _allDay = !_allDay),
            style: TextButton.styleFrom(
              foregroundColor:
                  _allDay ? LaTerciaColors.gold : LaTerciaColors.kdsMuted,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              side: BorderSide(
                  color:
                      _allDay ? LaTerciaColors.gold : LaTerciaColors.kdsMuted),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            icon: Icon(_allDay ? Icons.grid_view : Icons.summarize, size: 18),
            label: Text(_allDay ? 'Tarjetas' : 'All-day',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12.5)),
          ),
          const SizedBox(width: 14),
          if (ref.read(ordersProvider.notifier).canRecall) ...[
            _RecallButton(
              onRecall: () async {
                final done = await ref
                    .read(ordersProvider.notifier)
                    .recallLastReady();
                if (done && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Última orden recuperada'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(width: 14),
          ],
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final t = activeCount > 0
                  ? (0.5 + 0.5 * _pulseController.value)
                  : 1.0;
              return Opacity(opacity: activeCount > 0 ? t : 1, child: child);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: (activeCount > 0
                        ? LaTerciaColors.gold
                        : LaTerciaColors.timerOk)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activeCount > 0
                      ? LaTerciaColors.gold
                      : LaTerciaColors.timerOk,
                ),
              ),
              child: Text(
                '$activeCount pedidos activos',
                style: TextStyle(
                  color: activeCount > 0
                      ? LaTerciaColors.gold
                      : LaTerciaColors.timerOk,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Text(
            _clockStr,
            style: const TextStyle(
              fontFamily: 'DM Serif Display',
              color: Colors.white,
              fontSize: 26,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Header action to undo the last order marked "listo" (within the recall
/// window). Only shown while [OrdersNotifier.canRecall] is true.
class _RecallButton extends StatelessWidget {
  final Future<void> Function() onRecall;
  const _RecallButton({required this.onRecall});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onRecall,
      style: TextButton.styleFrom(
        foregroundColor: LaTerciaColors.gold,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        side: const BorderSide(color: LaTerciaColors.gold),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      icon: const Icon(Icons.undo, size: 18),
      label: const Text('Recall',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
    );
  }
}
