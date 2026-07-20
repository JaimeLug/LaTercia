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

  // FASE 5.3 — alto tráfico.
  bool _allDay = false; // vista consolidada "7× Frappé de Café"

  // 2026-07-20 — rediseño: antes las tarjetas se repartían en páginas fijas
  // y "Siguiente" saltaba de golpe a un lienzo completamente distinto (con 6-7
  // pedidos activos, las órdenes 5+ quedaban en otra "pantalla" invisible
  // hasta darle clic). Ahora es una cuadrícula con scroll continuo: todas las
  // órdenes activas viven en el mismo lienzo, y avanzar es desplazarse, no
  // saltar. El controller también sirve para llevar la vista hasta la tarjeta
  // seleccionada por la botonera (`_selectAndReveal`).
  final ScrollController _gridScrollController = ScrollController();
  // Una GlobalKey por orden activa, para poder ubicar su posición en el
  // scroll y traerla a la vista (Scrollable.ensureVisible).
  final Map<int, GlobalKey> _cardKeys = {};

  GlobalKey _cardKeyFor(int orderId) =>
      _cardKeys.putIfAbsent(orderId, () => GlobalKey());

  // 2026-07-20 — cocina solo tiene 6 botones físicos (sin mouse ni pantalla
  // táctil): dos flechas, recall, prep, listo, tiempo. Anterior/Siguiente
  // hacían un movimiento horizontal (cambiar de orden), pero no había forma
  // de desplazarse VERTICALMENTE dentro de un pedido largo ni en la vista
  // All-day. Fix: `KdsScreen` posee un ScrollController por orden (en vez de
  // que cada tarjeta gestione el suyo aislado) para poder leer/mover su
  // posición desde `_onButton` — ver `_scrollSelectedCard`.
  final Map<int, ScrollController> _itemScrollControllers = {};

  ScrollController _itemsControllerFor(int orderId) =>
      _itemScrollControllers.putIfAbsent(orderId, () => ScrollController());

  // Scroll de la vista All-day (lista vertical consolidada) — mismo problema
  // y misma solución: Anterior/Siguiente la desplazan cuando esa vista está
  // activa (ahí no tiene sentido "cambiar de orden").
  final ScrollController _allDayScrollController = ScrollController();

  // FASE 3.5 — botonera física (ESP32). Cursor de la tarjeta "seleccionada":
  // ANTERIOR/SIGUIENTE la mueven; PREP/LISTO actúan sobre ella.
  int? _selectedOrderId;
  StreamSubscription<KdsButton>? _buttonSub;
  StreamSubscription<String>? _rawButtonSub;
  bool _botoneraStarted = false;
  // GlobalKey (no `ScaffoldMessenger.of(context)`): el context de este State
  // vive FUERA del árbol que arma build(), así que `.of(context)` seguiría
  // encontrando el ScaffoldMessenger raíz de la app en vez del propio de esta
  // pantalla. La key apunta directo al ScaffoldMessenger local.
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    // Auto-scroll para un tablero de pared sin tocar (5.3) — antes saltaba de
    // golpe a la "siguiente página"; ahora se desplaza suave un lienzo hacia
    // abajo (y vuelve arriba al llegar al final), consistente con el resto
    // del rediseño de scroll continuo.
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

    // El stream real: local si este proceso tiene el socket del ESP32
    // (KDS embebido/POS), o reenviado por WS si es la ventana separada —
    // ver `kdsButtonStreamProvider`.
    _buttonSub = ref.read(kdsButtonStreamProvider).listen(_onButton);
    // Diagnóstico (3.5) de mensajes crudos no reconocidos: solo existe en el
    // proceso que tiene el socket real (no se reenvía por WS) — en la ventana
    // separada simplemente no habrá diagnóstico de mensajes basura, pero sí
    // de los botones reconocidos (que es lo que importa operar).
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
  /// (reactivo — apagar el flag en Configuración lo detiene sin cerrar la
  /// app). Llamado desde build() con el settings ya cargado.
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
    // Siempre hay una selección operable si hay algo activo — antes, si la
    // selección se perdía (p.ej. tras marcar "listo"), PREP/LISTO quedaban en
    // no-op silencioso hasta la siguiente navegación. Corrige el bug
    // reportado de "el botón solo sirve una vez".
    final current = effectiveSelection(ids, _selectedOrderId);

    switch (btn) {
      case KdsButton.tiempo:
        // "TIEMPO": alterna la vista all-day (5.3) — la lectura de conjunto
        // por tiempos, en vez de tarjeta por tarjeta. Con la cola vacía ambas
        // vistas se ven igual ("Sin pedidos"), así que el aviso es lo único
        // que confirma que el botón sí hizo algo.
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
        // Cocina solo tiene estos 6 botones (sin mouse ni touch, 2026-07-20)
        // — en All-day, Anterior/Siguiente son la ÚNICA forma de bajar la
        // lista consolidada (no hay "órdenes" entre las que cambiar aquí).
        if (_allDay) {
          _scrollAllDay(forward);
          return;
        }
        if (ids.isEmpty) {
          _toast('Sin pedidos activos para navegar', warn: true);
          return;
        }
        // Si la tarjeta seleccionada tiene más contenido en esa dirección
        // (pedido largo, varios productos), desplázala primero — recién
        // cuando ya no queda más que ver ahí, el botón cambia de orden. Para
        // un pedido corto que cabe completo, esto es un no-op y el botón
        // cambia de orden directo, como siempre.
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
          // Encadena a la siguiente tarjeta (cadencia de bump bar) en vez de
          // exigir otra navegación manual tras cada "listo".
          _selectAndReveal(nextAfterReady(ids, current));
          _toast('✅ Listo: $num');
        }
        return;
    }
  }

  /// Fija la selección de la botonera Y desplaza el scroll para que esa
  /// tarjeta quede a la vista — sin esto, con la cuadrícula de scroll
  /// continuo (2026-07-20) la botonera podía "seleccionar" una orden que
  /// quedó fuera de la pantalla, invisible hasta que alguien desplazara a
  /// mano. `id == null` limpia la selección sin intentar desplazar nada.
  void _selectAndReveal(int? id) {
    setState(() => _selectedOrderId = id);
    if (id == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _cardKeys[id]?.currentContext;
      if (ctx != null && mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      }
    });
  }

  /// Desplaza la tarjeta [orderId] en la dirección [forward] si le queda
  /// contenido por ver ahí (2026-07-20 — cocina solo tiene 6 botones, sin
  /// mouse ni touch). Devuelve `true` si desplazó algo (el botón "se
  /// consume" en el scroll) o `false` si no había nada más que ver en esa
  /// dirección — ahí el caller (`_onButton`) debe cambiar de orden. Para un
  /// pedido corto que cabe completo (`maxScrollExtent == 0`), esto siempre
  /// devuelve `false` de inmediato: cambia de orden directo, sin pausa.
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

  /// Anterior/Siguiente en la vista All-day: ahí no hay "órdenes" entre las
  /// que cambiar, así que desplazan la lista consolidada — es la única forma
  /// de bajarla sin mouse ni touch (2026-07-20).
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

    // Resaltado a mostrar: la selección real si sigue vigente, si no la
    // primera activa — así siempre hay una tarjeta claramente operable, aun
    // antes de que la botonera navegue por primera vez. Es solo para pintar;
    // el estado real (_selectedOrderId) lo fija _onButton.
    final highlightId = effectiveSelection(
        active.map((o) => o.order.id).toList(), _selectedOrderId);

    // ScaffoldMessenger PROPIO: sin esto, los avisos de la botonera
    // (_toast/SnackBar) suben al ScaffoldMessenger raíz de MaterialApp y se
    // ven flotando sobre el POS/Admin aunque la pestaña Cocina·KDS no esté
    // visible (KdsScreen vive siempre montado dentro del IndexedStack de
    // _Root). Con su propio ScaffoldMessenger, los avisos quedan confinados a
    // esta pantalla y, al no pintarse las pestañas no-seleccionadas del
    // IndexedStack, no aparecen en ningún otro lado.
    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        backgroundColor: LaTerciaColors.kdsBg,
        body: Column(
          children: [
            _buildHeader(businessName, active.length),
            // Barra PERMANENTE (no un aviso que desaparece, no solo un borde en
            // la tarjeta): siempre visible mientras la botonera está activa, para
            // que sea imposible no notar cuál pedido está seleccionado.
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

  /// Barra fija bajo el header con la selección actual de la botonera —
  /// deliberadamente NO es un SnackBar (desaparece) ni depende de fijarse en
  /// el borde de una tarjeta entre muchas: siempre está ahí, siempre legible.
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

  /// Cuadrícula de tarjetas con scroll continuo (2026-07-20) — ver
  /// [KdsOrderGrid] para el detalle del rediseño. Poda las GlobalKeys y los
  /// ScrollController de órdenes que ya no están activas (higiene, para no
  /// acumularlos indefinidamente en un turno largo — los controllers, a
  /// diferencia de las keys, hay que liberarlos explícitamente) y delega el
  /// layout al widget.
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
      // 2026-07-20: controller propio para que Anterior/Siguiente puedan
      // desplazarla desde la botonera (`_scrollAllDay`) — sin mouse ni
      // touch, es la única forma de bajar esta lista.
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

/// Cuadrícula de tarjetas de órdenes con SCROLL CONTINUO (2026-07-20).
///
/// Antes las tarjetas se repartían en páginas de tamaño fijo y "Siguiente"
/// saltaba de golpe a un lienzo completamente distinto — con 6-7 pedidos
/// activos, las órdenes 5+ quedaban invisibles en "otra pantalla" hasta
/// hacer clic (reporte del dueño en sitio, café abierto). Ahora TODAS las
/// órdenes activas conviven en el mismo lienzo desplazable — avanzar es
/// desplazarse, no saltar.
///
/// Extraído como widget propio (en vez de un método de `_KdsScreenState`)
/// para poder probarlo sin depender del resto de `KdsScreen` (audio, sockets
/// de la botonera, timers de reloj/auto-scroll).
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
  // Controller del scroll de items DENTRO de cada tarjeta — opcional (si no
  // se pasa, cada OrderCardKds gestiona el suyo internamente). KdsScreen lo
  // pasa para poder desplazar la tarjeta seleccionada desde la botonera
  // (2026-07-20, ver `KdsScreen._scrollSelectedCard`).
  final ScrollController Function(int orderId)? itemsControllerFor;
  final VoidCallback? onSoundPlay;

  // Un poco más grandes que la versión paginada (320×452 → 340×480): menos
  // necesidad de hacer scroll dentro de la tarjeta en órdenes con varios
  // productos (pedido explícito del dueño, 2026-07-20).
  static const cardW = 340.0, cardH = 480.0, gap = 16.0, pad = 20.0;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      // Key propia: cada OrderCardKds trae además su propio Scrollbar interno
      // para su lista de items (2026-07-20), así que `find.byType(Scrollbar)`
      // ya no basta para identificar el de la cuadrícula en los tests.
      key: const Key('kds-grid-scrollbar'),
      controller: controller,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(pad),
        child: Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final o in orders)
              SizedBox(
                key: cardKeyFor(o.order.id),
                width: cardW,
                height: cardH,
                child: SelectableOrderCard(
                  selected: o.order.id == highlightId,
                  child: OrderCardKds(
                    key: ValueKey(o.order.id),
                    orderWithItems: o,
                    onSoundPlay: onSoundPlay,
                    itemsScrollController: itemsControllerFor?.call(o.order.id),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Envuelve una tarjeta del KDS con un anillo visible cuando está seleccionada
/// (cursor de la botonera, 3.5). Necesita padding propio: la tarjeta interior
/// ya pinta su borde y su fondo hasta el borde, así que sin ese hueco el
/// anillo exterior queda completamente tapado y no se ve — el bug reportado
/// era justo este.
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
