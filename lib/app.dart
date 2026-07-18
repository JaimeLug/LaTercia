import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'core/models/order_with_items.dart';
import 'core/providers/orders_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/services/backup_service.dart';
import 'core/services/kds_button_service.dart';
import 'core/services/kds_server.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/admin_shell.dart';
import 'features/auth/auto_lock_wrapper.dart';
import 'features/auth/pin_gate.dart';
import 'features/kds/kds_launcher.dart';
import 'features/shell/kiosk_controller.dart';
import 'features/kds/kds_screen.dart';
import 'features/pos/pos_screen.dart';
import 'features/shell/shift/shift_gate.dart';
import 'features/shell/top_nav_bar.dart';
import 'features/shell/welcome_screen.dart';

class LaTerciaApp extends ConsumerWidget {
  const LaTerciaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    final theme = settingsAsync.when(
      data: (s) => buildTheme(
        s['primary_color'] ?? '#C1560F',
        s['secondary_color'] ?? '#F1AA3F',
      ),
      loading: () => buildTheme('#C1560F', '#F1AA3F'),
      error: (_, __) => buildTheme('#C1560F', '#F1AA3F'),
    );

    return MaterialApp(
      title: 'La Tercia POS',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const KioskController(child: _MainLayout()),
    );
  }
}

class _MainLayout extends StatelessWidget {
  const _MainLayout();

  @override
  Widget build(BuildContext context) {
    // Identify once (any employee) before entering the app. AutoLockWrapper
    // sits inside the PIN gate so it can watch/clear the session once one
    // exists; it never mounts in the KDS process (kds_app.dart has no
    // PinGate).
    return const PinGate(
      adminOnly: false,
      child: AutoLockWrapper(child: _Root()),
    );
  }
}

/// Manages the flow after login: Welcome landing → chosen module (with the
/// persistent top navigation bar). The top-bar logo returns to Welcome.
class _Root extends ConsumerStatefulWidget {
  const _Root();

  @override
  ConsumerState<_Root> createState() => _RootState();
}

class _RootState extends ConsumerState<_Root> {
  bool _inModule = false;
  int _tab = 0; // 0 = POS, 1 = KDS (embedded), 2 = Admin
  ProviderSubscription<List<OrderWithItems>>? _ordersSub;
  StreamSubscription<KdsButton>? _botonForwardSub;

  @override
  void initState() {
    super.initState();
    // Backup diario best-effort al entrar al POS (5.2). Solo el proceso POS
    // llega aquí; el KDS usa kds_app.dart y no monta _Root.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(backupServiceProvider).autoBackupIfDue();
    });
    _startKdsServer();
  }

  @override
  void dispose() {
    _ordersSub?.close();
    _botonForwardSub?.cancel();
    super.dispose();
  }

  /// FASE 5.1 — Arranca el servidor WS (dueño de la BD) y empuja los pedidos
  /// activos a las ventanas KDS conectadas. Los comandos que estas mandan se
  /// ejecutan contra el OrdersNotifier local (que escribe la BD).
  void _startKdsServer() {
    final server = ref.read(kdsServerProvider);
    final notifier = ref.read(ordersProvider.notifier);
    server.onMarkReady = notifier.markReady;
    server.onUpdateStatus = notifier.updateStatus;
    server.onRecall = () async {
      await notifier.recallLastReady();
    };
    server.start();
    // Cada cambio del estado local (incluye el poll de 2s) se retransmite.
    // Guardamos la suscripción para cerrarla en dispose (M2).
    _ordersSub = ref.listenManual(
      ordersProvider,
      (prev, next) => server.broadcast(next, notifier.canRecall),
      fireImmediately: true,
    );
    // Reenvía cada botón de la botonera física (que solo este proceso puede
    // recibir del ESP32, dueño del puerto 8080) a cualquier ventana KDS
    // separada conectada — sin esto, esa ventana se queda sorda a la botonera.
    _botonForwardSub = ref
        .read(kdsButtonServiceProvider)
        .botonPresionado
        .listen(server.broadcastBoton);
  }

  final _screens = const [
    ShiftGate(child: PosScreen()),
    KdsScreen(),
    AdminShell(),
  ];

  void _openModule(int tab) => setState(() {
        _inModule = true;
        _tab = tab;
      });

  Future<void> _onKdsTab() async {
    final embed = await showKdsScreenPicker(context);
    if (embed && mounted) setState(() => _tab = 1);
  }

  @override
  Widget build(BuildContext context) {
    if (!_inModule) {
      return WelcomeScreen(onOpen: _openModule);
    }

    return Scaffold(
      body: Column(
        children: [
          TopNavBar(
            currentTab: _tab,
            onLogo: () => setState(() => _inModule = false),
            onPos: () => setState(() => _tab = 0),
            onKds: _onKdsTab,
            onAdmin: () => setState(() => _tab = 2),
          ),
          Expanded(
            child: IndexedStack(index: _tab, children: _screens),
          ),
        ],
      ),
    );
  }
}
