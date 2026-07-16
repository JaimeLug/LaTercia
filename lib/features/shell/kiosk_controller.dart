import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/providers/settings_provider.dart';

/// FASE 6.2/6.4 — Modo kiosko. Envuelve el contenido del POS y aplica/retira el
/// estado de ventana según el flag `modo_kiosko` (reactivo, para que apagarlo en
/// Configuración libere la ventana sin tener que matar el proceso):
/// - ON: pantalla completa + `setPreventClose` (el cierre lo ignora
///   [onWindowClose]; la estación se administra por systemd/`Restart=always`).
/// - OFF: ventana normal, cierre permitido.
///
/// El escape seguro es apagar el flag en Configuración → la ventana se libera al
/// instante. Solo corre en el proceso POS (el KDS ya va a pantalla completa).
class KioskController extends ConsumerStatefulWidget {
  final Widget child;
  const KioskController({super.key, required this.child});

  @override
  ConsumerState<KioskController> createState() => _KioskControllerState();
}

class _KioskControllerState extends ConsumerState<KioskController>
    with WindowListener {
  bool _kiosk = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _apply(bool kiosk) async {
    if (kiosk == _kiosk) return;
    _kiosk = kiosk;
    try {
      await windowManager.setPreventClose(kiosk);
      await windowManager.setFullScreen(kiosk);
    } catch (_) {/* window_manager no disponible en algunos entornos */}
  }

  @override
  void onWindowClose() async {
    // En kiosko, ignora el intento de cierre (la ventana no debe poder cerrarse
    // desde la UI). Fuera de kiosko, cierra normalmente.
    if (!_kiosk) {
      await windowManager.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    final kiosk =
        ref.watch(settingsProvider).valueOrNull?['modo_kiosko'] == 'true';
    // Aplica fuera del build para no tocar la ventana durante el layout.
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply(kiosk));
    return widget.child;
  }
}
