import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/session_provider.dart';
import '../../core/providers/settings_provider.dart';

/// Re-bloquea la sesión (vuelve a pedir PIN) tras `auto_lock_min` minutos de
/// inactividad (`'0'` lo desactiva). Detecta actividad de puntero **y** teclado
/// (para no expirar mientras se teclea un monto). No aplica en el proceso KDS.
class AutoLockWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const AutoLockWrapper({super.key, required this.child});

  @override
  ConsumerState<AutoLockWrapper> createState() => _AutoLockWrapperState();
}

class _AutoLockWrapperState extends ConsumerState<AutoLockWrapper> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resetTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    super.dispose();
  }

  bool _onKeyEvent(KeyEvent event) {
    _resetTimer();
    return false; // don't consume the event
  }

  void _resetTimer() {
    _timer?.cancel();
    final settings = ref.read(settingsProvider).valueOrNull ?? {};
    final minutes = int.tryParse(settings['auto_lock_min'] ?? '5') ?? 5;
    if (minutes <= 0) return;
    // Solo arma el timer si hay una sesión activa que expirar.
    if (ref.read(sessionProvider) == null) return;
    _timer = Timer(Duration(minutes: minutes), _lock);
  }

  void _lock() {
    if (ref.read(sessionProvider) != null) {
      ref.read(sessionProvider.notifier).state = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-arma el timer cuando cambian settings o sesión (login, o edición de
    // auto_lock_min).
    ref.listen(settingsProvider, (_, __) => _resetTimer());
    ref.listen(sessionProvider, (_, next) {
      if (next != null) _resetTimer();
    });

    return Listener(
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      onPointerSignal: (_) => _resetTimer(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
