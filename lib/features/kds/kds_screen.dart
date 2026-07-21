import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/order_with_items.dart';
import '../../core/providers/orders_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/kds_button_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/kds_modifiers.dart';
import '../../core/utils/kds_selection.dart';
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

  bool _allDay = false; // vista consolidada "7× Frappé de Café"

  // Cuadrícula de scroll continuo (todas las órdenes en un lienzo, no páginas).
  // docs/kds.md §"Pantalla y navegación".
  final ScrollController _gridScrollController = ScrollController();
  // Una GlobalKey por orden, para traerla a la vista (Scrollable.ensureVisible).
  final Map<int, GlobalKey> _cardKeys = {};

  GlobalKey _cardKeyFor(int orderId) =>
      _cardKeys.putIfAbsent(orderId, () => GlobalKey());

  // ScrollControllers por orden que posee la pantalla (no cada tarjeta), para
  // moverlos desde la botonera. docs/kds.md §"Pantalla y navegación".
  final Map<int, ScrollController> _itemScrollControllers = {};

  ScrollController _itemsControllerFor(int orderId) =>
      _itemScrollControllers.putIfAbsent(orderId, () => ScrollController());

  // Scroll de la vista All-day. docs/kds.md §All-day.
  final ScrollController _allDayScrollController = ScrollController();

  // Botonera: cursor de la tarjeta seleccionada. docs/kds.md §"Pantalla y
  // navegación".
  int? _selectedOrderId;
  StreamSubscription<KdsButton>? _buttonSub;
  StreamSubscription<String>? _rawButtonSub;
  bool _botoneraStarted = false;
  // GlobalKey al ScaffoldMessenger local (no `.of(context)`, que encontraría el
  // raíz de la app: el context de este State vive fuera del árbol de build()).
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    // Auto-scroll para un tablero de pared sin tocar. docs/kds.md.
    _rotateTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (_allDay || !mounted || !_gridScrollController.hasClients) return;
      final position = _gridScrollController.position;
      if (position.maxScrollExtent <= 0) return; // todo cabe, nada que mover
      final target = position.pixels + position.viewportDimension;
      _gridScrollController.animateTo(
        target > position.maxScrollExtent ? 0 : target,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Stream de botones (local o reenviado por WS). docs/kds-conexion.md.
    _buttonSub = ref.read(kdsButtonStreamProvider).listen(_onButton);
    // Diagnóstico de mensajes crudos no reconocidos (solo en el proceso con el
    // socket real). docs/kds-conexion.md §Botonera.
    final buttons = ref.read(kdsButtonServiceProvider);
    _rawButtonSub = buttons.mensajeCrudo.listen((raw) {
      if (!mounted || parseKdsButton(raw) != null) return;
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: LaTerciaColors.danger,
          content: Text('⚠️ Botonera: mensaje no reconocido → "$raw"',
              style: const TextStyle(color: Colors.white)),
        ),
      );
    });
  }

  void _toast(String message, {bool warn = false}) {
    if (!mounted) return;
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: warn ? LaTerciaColors.gold : LaTerciaColors.kdsPanel,
        content: Text(message,
            style: TextStyle(
                color: warn ? LaTerciaColors.darkBrown : Colors.white,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _rotateTimer?.cancel();
    _buttonSub?.cancel();
    _rawButtonSub?.cancel();
    _pulseController.dispose();
    _gridScrollController.dispose();
    _allDayScrollController.dispose();
    for (final c in _itemScrollControllers.values) {
      c.dispose();
    }
    _player.dispose();
    super.dispose();
  }

  /// Arranca/detiene el servidor de la botonera según `botonera_activa`
  /// (reactivo). `docs/kds-conexion.md` §Botonera.
  void _syncBotonera(Map<String, String> settings) {
    final enabled = settings['botonera_activa'] == 'true';
    final service = ref.read(kdsButtonServiceProvider);
    if (enabled && !_botoneraStarted) {
      _botoneraStarted = true;
      final port = int.tryParse(settings['botonera_puerto'] ?? '') ?? 8080;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => service.start(port: port));
    } else if (!enabled && _botoneraStarted) {
      _botoneraStarted = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => service.stop());
    }
  }

  /// Lista activa actual (mismo orden que la cuadrícula), para que la
  /// botonera navegue sobre exactamente lo que se ve en pantalla.
  List<OrderWithItems> get _activeOrdered {
    final orders = ref.read(ordersProvider);
    return orders
        .where((o) =>
            o.order.status == 'pendiente' || o.order.status == 'en_preparacion')
        .toList()
      ..sort((a, b) => a.order.createdAt.compareTo(b.order.createdAt));
  }

  void _onButton(KdsButton btn) {
    if (!mounted) return;
    final active = _activeOrdered;
    final ids = active.map((o) => o.order.id).toList();
    // Siempre hay una selección operable si hay algo activo. docs/kds.md.
    final current = effectiveSelection(ids, _selectedOrderId);

    switch (btn) {
      case KdsButton.tiempo:
        // TIEMPO alterna la vista All-day. docs/kds.md §All-day.
        setState(() => _allDay = !_allDay);
        _toast(_allDay ? '🕐 Vista: All-day' : '🕐 Vista: Tarjetas');
        return;
      case KdsButton.recall:
        ref.read(ordersProvider.notifier).recallLastReady().then((done) {
          _toast(done
              ? '↩️ Última orden recuperada'
              : '↩️ Nada que recuperar (pasó la ventana de 60s, o ninguna)');
        });
        return;
      case KdsButton.anterior:
      case KdsButton.siguiente:
        final forward = btn == KdsButton.siguiente;
        // En All-day, las flechas desplazan la lista. docs/kds.md §All-day.
        if (_allDay) {
          _scrollAllDay(forward);
          return;
        }
        if (ids.isEmpty) {
          _toast('Sin pedidos activos para navegar', warn: true);
          return;
        }
        // Desplaza dentro de la tarjeta si le queda contenido; si no, cambia de
        // orden. docs/kds.md §"Pantalla y navegación".
        if (current != null && _scrollSelectedCard(current, forward)) {
          return;
        }
        final idx = current == null ? -1 : ids.indexOf(current);
        final nextIdx = forward
            ? (idx + 1) % ids.length
            : (idx - 1 + ids.length) % ids.length;
        final newId = ids[nextIdx];
        _selectAndReveal(newId);
        final num =
            active.firstWhere((o) => o.order.id == newId).order.orderNumber;
        _toast('→ Orden $num seleccionada');
        return;
      case KdsButton.prep:
      case KdsButton.listo:
        if (current == null) {
          _toast('Sin pedidos activos', warn: true);
          return;
        }
        final notifier = ref.read(ordersProvider.notifier);
        final num =
            active.firstWhere((o) => o.order.id == current).order.orderNumber;
        if (btn == KdsButton.prep) {
          notifier.updateStatus(current, 'en_preparacion');
          _selectAndReveal(current);
          _toast('👨‍🍳 En preparación: $num');
        } else {
          _playOrderDone();
          notifier.markReady(current);
          // Encadena a la siguiente (cadencia de bump bar). docs/kds.md.
          _selectAndReveal(nextAfterReady(ids, current));
          _toast('✅ Listo: $num');
        }
        return;
    }
  }

  /// Fija la selección y trae esa tarjeta a la vista (`id == null` solo limpia).
  /// docs/kds.md §"Pantalla y navegación".
  void _selectAndReveal(int? id) {
    setState(() => _selectedOrderId = id);
    if (id == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_gridScrollController.hasClients) return;
      // Si todo cabe en pantalla no hay que desplazar nada: centrar la tarjeta
      // seleccionada la sacaría de la esquina y dejaría los pedidos flotando al
      // centro. Solo se centra cuando hay tantos pedidos que sí hay scroll.
      if (_gridScrollController.position.maxScrollExtent <= 0) return;
      final ctx = _cardKeys[id]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      }
    });
  }

  /// Desplaza la tarjeta [orderId] si le queda contenido en [forward]; devuelve
  /// `true` si desplazó (el caller no cambia de orden). docs/kds.md.
  bool _scrollSelectedCard(int orderId, bool forward) {
    final controller = _itemScrollControllers[orderId];
    if (controller == null || !controller.hasClients) return false;
    final position = controller.position;
    if (forward
        ? position.pixels >= position.maxScrollExtent - 2
        : position.pixels <= 2) {
      return false;
    }
    final step = position.viewportDimension;
    final target = (forward ? position.pixels + step : position.pixels - step)
        .clamp(0.0, position.maxScrollExtent);
    controller.animateTo(target,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    return true;
  }

  /// Anterior/Siguiente en All-day desplazan la lista. docs/kds.md §All-day.
  void _scrollAllDay(bool forward) {
    if (!_allDayScrollController.hasClients) return;
    final position = _allDayScrollController.position;
    if (forward && position.pixels >= position.maxScrollExtent - 2) {
      _toast('Fin de la lista', warn: true);
      return;
    }
    if (!forward && position.pixels <= 2) {
      _toast('Inicio de la lista', warn: true);
      return;
    }
    final step = position.viewportDimension;
    final target = (forward ? position.pixels + step : position.pixels - step)
        .clamp(0.0, position.maxScrollExtent);
    _allDayScrollController.animateTo(target,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
    _syncBotonera(settings);

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

    // Resaltado a pintar (la selección real, o la primera activa). El estado
    // real lo fija _onButton. docs/kds.md.
    final highlightId = effectiveSelection(
        active.map((o) => o.order.id).toList(), _selectedOrderId);

    // ScaffoldMessenger propio: confina los avisos de la botonera a esta
    // pantalla (KdsScreen vive montada en el IndexedStack de _Root; sin esto
    // los toasts flotarían sobre POS/Admin).
    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        backgroundColor: LaTerciaColors.kdsBg,
        body: Column(
          children: [
            _buildHeader(businessName, active.length),
            // Barra permanente con la selección de la botonera (siempre visible,
            // para no perder de vista cuál pedido está seleccionado).
            if (settings['botonera_activa'] == 'true')
              _buildSelectionBar(active, highlightId),
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
                      : _buildScrollableGrid(active, highlightId),
            ),
          ],
        ),
      ),
    );
  }

  /// Barra fija con la selección de la botonera (no un SnackBar; siempre visible).
  Widget _buildSelectionBar(List<OrderWithItems> active, int? highlightId) {
    String label;
    if (active.isEmpty) {
      label = 'Botonera: sin pedidos activos';
    } else if (highlightId == null) {
      label = 'Botonera: sin selección';
    } else {
      final idx = active.indexWhere((o) => o.order.id == highlightId);
      final num = idx >= 0 ? active[idx].order.orderNumber : '—';
      label = 'Botonera → Seleccionada: $num  (${idx + 1} de ${active.length})';
    }
    return Container(
      width: double.infinity,
      color: LaTerciaColors.gold,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.gamepad, size: 16, color: LaTerciaColors.darkBrown),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: LaTerciaColors.darkBrown,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
        ],
      ),
    );
  }

  /// Cuadrícula de scroll continuo (ver [KdsOrderGrid]). Poda las keys y libera
  /// los ScrollController de órdenes ya inactivas. docs/kds.md.
  Widget _buildScrollableGrid(List<OrderWithItems> active, int? highlightId) {
    final activeIds = active.map((o) => o.order.id).toSet();
    _cardKeys.removeWhere((id, _) => !activeIds.contains(id));
    _itemScrollControllers.removeWhere((id, controller) {
      final stale = !activeIds.contains(id);
      if (stale) controller.dispose();
      return stale;
    });

    return KdsOrderGrid(
      orders: active,
      highlightId: highlightId,
      controller: _gridScrollController,
      cardKeyFor: _cardKeyFor,
      itemsControllerFor: _itemsControllerFor,
      onSoundPlay: _playOrderDone,
    );
  }

  /// Vista all-day: consolida cantidades pendientes por producto + combinación
  /// de modificadores. docs/kds.md §All-day.
  Widget _buildAllDay(List<OrderWithItems> active) {
    final groups =
        <String, ({String product, List<KdsModifier> mods, int count})>{};
    for (final o in active) {
      for (final it in o.items) {
        if (it.itemStatus == 'listo' || it.itemStatus == 'cancelado') continue;
        final mods = parseKdsModifiers(it.modifiersJson)
          ..sort((a, b) => a.label.compareTo(b.label));
        final key = '${it.productName}|${mods.map((m) => m.label).join(',')}';
        final prev = groups[key];
        groups[key] = (
          product: it.productName,
          mods: mods,
          count: (prev?.count ?? 0) + it.quantity,
        );
      }
    }
    // Orden: producto de mayor total arriba, con sus variantes seguidas.
    // docs/kds.md §All-day.
    final productTotals = <String, int>{};
    for (final e in groups.values) {
      productTotals[e.product] = (productTotals[e.product] ?? 0) + e.count;
    }
    final entries = groups.values.toList()
      ..sort((a, b) {
        final byTotal =
            productTotals[b.product]!.compareTo(productTotals[a.product]!);
        if (byTotal != 0) return byTotal;
        final byProduct = a.product.compareTo(b.product);
        if (byProduct != 0) return byProduct;
        return b.count.compareTo(a.count);
      });

    return ListView.separated(
      // Controller propio para desplazarla con la botonera. docs/kds.md.
      controller: _allDayScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      itemCount: entries.length,
      separatorBuilder: (_, __) =>
          const Divider(color: LaTerciaColors.kdsMuted, height: 1),
      itemBuilder: (ctx, i) {
        final e = entries[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  '${e.count}×',
                  style: const TextStyle(
                    fontFamily: 'DM Serif Display',
                    color: LaTerciaColors.gold,
                    fontSize: 44,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.product,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    for (final m in e.mods)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '↳ ${m.label}',
                          style: const TextStyle(
                            color: LaTerciaColors.kdsMuted,
                            fontSize: 18,
                          ),
                        ),
                      ),
                  ],
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
          // Toggle All-day ↔ tarjetas. docs/kds.md §All-day.
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
                final done =
                    await ref.read(ordersProvider.notifier).recallLastReady();
                if (done && mounted) {
                  _messengerKey.currentState?.showSnackBar(
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
              final t =
                  activeCount > 0 ? (0.5 + 0.5 * _pulseController.value) : 1.0;
              return Opacity(opacity: activeCount > 0 ? t : 1, child: child);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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

/// Cuadrícula de órdenes con scroll continuo (extraída como widget propio para
/// poder testearla sin el resto de KdsScreen). docs/kds.md §"Pantalla y
/// navegación".
class KdsOrderGrid extends StatelessWidget {
  const KdsOrderGrid({
    super.key,
    required this.orders,
    required this.highlightId,
    required this.controller,
    required this.cardKeyFor,
    this.itemsControllerFor,
    this.onSoundPlay,
  });

  final List<OrderWithItems> orders;
  final int? highlightId;
  final ScrollController controller;
  final Key Function(int orderId) cardKeyFor;
  // Controller del scroll de items dentro de cada tarjeta — opcional; KdsScreen
  // lo pasa para moverlo desde la botonera. docs/kds.md.
  final ScrollController Function(int orderId)? itemsControllerFor;
  final VoidCallback? onSoundPlay;

  // Ancho fijo (columnas parejas); el alto crece con el contenido (ver build).
  static const cardW = 340.0, gap = 16.0, pad = 20.0;

  @override
  Widget build(BuildContext context) {
    // Scroll ENTRE pedidos horizontal (el vertical es solo el de los productos
    // dentro de cada tarjeta); tarjetas de alto automático con tope = alto de
    // pantalla, y scroll interno pasado el tope. docs/kds.md §"Pantalla y
    // navegación".
    return LayoutBuilder(builder: (context, constraints) {
      final maxCardHeight =
          (constraints.maxHeight - pad * 2).clamp(200.0, double.infinity);
      return Scrollbar(
        // Key propia: cada tarjeta trae su propio Scrollbar/scroll interno, así
        // que `find.byType` no basta para identificar el de la cuadrícula en tests.
        key: const Key('kds-grid-scrollbar'),
        controller: controller,
        thumbVisibility: true,
        child: SingleChildScrollView(
          key: const Key('kds-grid-scroll-view'),
          controller: controller,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(pad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final o in orders) ...[
                ConstrainedBox(
                  key: cardKeyFor(o.order.id),
                  constraints: BoxConstraints(
                    minWidth: cardW,
                    maxWidth: cardW,
                    maxHeight: maxCardHeight,
                  ),
                  child: SelectableOrderCard(
                    selected: o.order.id == highlightId,
                    child: OrderCardKds(
                      key: ValueKey(o.order.id),
                      orderWithItems: o,
                      onSoundPlay: onSoundPlay,
                      itemsScrollController:
                          itemsControllerFor?.call(o.order.id),
                    ),
                  ),
                ),
                const SizedBox(width: gap),
              ],
            ],
          ),
        ),
      );
    });
  }
}

/// Envuelve una tarjeta del KDS con un anillo cuando está seleccionada (cursor
/// de la botonera). Necesita padding propio para que el anillo no quede tapado.
class SelectableOrderCard extends StatelessWidget {
  final bool selected;
  final Widget child;
  const SelectableOrderCard(
      {super.key, required this.selected, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.all(selected ? 5 : 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? LaTerciaColors.gold : Colors.transparent,
          width: 5,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: LaTerciaColors.gold.withValues(alpha: 0.45),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          if (selected)
            Positioned(
              top: -12,
              left: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: LaTerciaColors.gold,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text('SELECCIONADA',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: LaTerciaColors.darkBrown)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      icon: const Icon(Icons.undo, size: 18),
      label: const Text('Recall',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
    );
  }
}
