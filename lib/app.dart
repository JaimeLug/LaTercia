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
    // Identificación con PIN antes de entrar (cualquier empleado). El
    // AutoLockWrapper va dentro del gate; no se monta en el proceso KDS.
    return const PinGate(
      adminOnly: false,
      child: AutoLockWrapper(child: _Root()),
    );
  }
}

/// Flujo tras el login: Welcome → módulo elegido (con la barra superior fija).
/// El logo de la barra regresa a Welcome.
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
    // Backup diario best-effort al entrar al POS (solo el proceso POS llega
    // aquí). docs/backups.md.
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

  /// Arranca el servidor WS del POS y conecta sus comandos al OrdersNotifier.
  /// docs/kds-conexion.md.
  void _startKdsServer() {
    final server = ref.read(kdsServerProvider);
    final notifier = ref.read(ordersProvider.notifier);
    server.onMarkReady = notifier.markReady;
    server.onUpdateStatus = notifier.updateStatus;
    server.onRecall = () async {
      await notifier.recallLastReady();
    };
    server.start();
    // Retransmite cada cambio del estado local (incluye el poll de 2s).
    _ordersSub = ref.listenManual(
      ordersProvider,
      (prev, next) => server.broadcast(next, notifier.canRecall),
      fireImmediately: true,
    );
    // Retransmite cada botón físico a las ventanas KDS separadas (solo este
    // proceso lo recibe del ESP32). docs/kds-conexion.md.
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
