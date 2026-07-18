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
  int _page = 0; // página actual de tarjetas
  int _pageCount = 1; // calculado en build; lo usa el auto-rotate

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
        backgroundColor:
            warn ? LaTerciaColors.gold : LaTerciaColors.kdsPanel,
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
            o.order.status == 'pendiente' ||
            o.order.status == 'en_preparacion')
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
        if (_allDay) {
          _toast('Cambia a vista Tarjetas (botón TIEMPO) para navegar',
              warn: true);
          return;
        }
        if (ids.isEmpty) {
          _toast('Sin pedidos activos para navegar', warn: true);
          return;
        }
        final idx = current == null ? -1 : ids.indexOf(current);
        final nextIdx = btn == KdsButton.siguiente
            ? (idx + 1) % ids.length
            : (idx - 1 + ids.length) % ids.length;
        final newId = ids[nextIdx];
        setState(() => _selectedOrderId = newId);
        final num = active.firstWhere((o) => o.order.id == newId).order.orderNumber;
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
          setState(() => _selectedOrderId = current);
          _toast('👨‍🍳 En preparación: $num');
        } else {
          _playOrderDone();
          notifier.markReady(current);
          // Encadena a la siguiente tarjeta (cadencia de bump bar) en vez de
          // exigir otra navegación manual tras cada "listo".
          setState(() => _selectedOrderId = nextAfterReady(ids, current));
          _toast('✅ Listo: $num');
        }
        return;
    }
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
    final highlightId =
        effectiveSelection(active.map((o) => o.order.id).toList(), _selectedOrderId);

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
                    : _buildPaginatedGrid(active, highlightId),
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
      label =
          'Botonera → Seleccionada: $num  (${idx + 1} de ${active.length})';
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

  /// Tarjetas paginadas de tamaño fijo: nunca se encogen (legibilidad a 2 m).
  /// Lo que no cabe en la pantalla pasa a la siguiente página (5.3).
  Widget _buildPaginatedGrid(List<OrderWithItems> active, int? highlightId) {
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
                        child: _SelectableCard(
                          selected: o.order.id == highlightId,
                          child: OrderCardKds(
                            key: ValueKey(o.order.id),
                            orderWithItems: o,
                            onSoundPlay: _playOrderDone,
                          ),
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

/// Envuelve una tarjeta del KDS con un anillo visible cuando está seleccionada
/// (cursor de la botonera, 3.5). Necesita padding propio: la tarjeta interior
/// ya pinta su borde y su fondo hasta el borde, así que sin ese hueco el
/// anillo exterior queda completamente tapado y no se ve — el bug reportado
/// era justo este.
class _SelectableCard extends StatelessWidget {
  final bool selected;
  final Widget child;
  const _SelectableCard({required this.selected, required this.child});

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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      icon: const Icon(Icons.undo, size: 18),
      label: const Text('Recall',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
    );
  }
}
