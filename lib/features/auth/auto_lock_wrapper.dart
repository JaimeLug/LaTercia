import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/session_provider.dart';
import '../../core/providers/settings_provider.dart';

/// Re-locks the session (sets `sessionProvider` to null, which makes
/// `PinGate` ask for a PIN again) after `auto_lock_min` minutes of
/// inactivity. `'0'` disables it.
///
/// Activity is detected globally via a [Listener] (pointer down/move/signal)
/// *and* keyboard events (`HardwareKeyboard`), so typing an amount without
/// moving the mouse doesn't expire the session mid-entry.
///
/// Does not touch the KDS process (`kds_app.dart` has no `PinGate`/session —
/// this widget is never mounted there).
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
    // Only arm the timer if there's an active session to expire.
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
    // Re-arm whenever settings or the session change (e.g. login just
    // happened, or auto_lock_min was edited in Settings).
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
