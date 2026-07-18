import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/order_with_items.dart';
import '../utils/app_logger.dart';
import 'kds_button_service.dart' show KdsButton, parseKdsButton;
import 'kds_link.dart';

/// FASE 5.1 — Cliente WebSocket que corre en la ventana KDS separada. Se conecta
/// al servidor del proceso POS (leyendo el endpoint file), recibe los pedidos
/// empujados y manda comandos de vuelta. Reconecta con backoff (1→2→4→10 s).
///
/// Mientras está conectado, el `OrdersNotifier` del KDS deja de leer la BD y su
/// estado lo dicta [onSnapshot]. Si la conexión cae, [onConnectionChanged]
/// avisa y el notifier vuelve al polling de BD (fallback).
class KdsClient {
  WebSocket? _ws;
  bool _connected = false;
  bool _stopped = false;
  int _backoffSeconds = 1;
  Timer? _reconnectTimer;

  void Function(List<OrderWithItems> orders, bool canRecall)? onSnapshot;
  void Function(bool connected)? onConnectionChanged;

  /// Botones de la botonera física reenviados por el POS (dueño real del
  /// socket del ESP32) — así la ventana KDS separada también los recibe.
  final _botonController = StreamController<KdsButton>.broadcast();
  Stream<KdsButton> get botonPresionado => _botonController.stream;

  bool get isConnected => _connected;

  void start() {
    _stopped = false;
    _connect();
  }

  Future<void> _connect() async {
    if (_stopped) return;
    final ep = await readKdsEndpoint();
    if (ep == null) {
      _scheduleReconnect();
      return;
    }
    try {
      final ws = await WebSocket.connect(
          'ws://127.0.0.1:${ep.port}$kdsWsPath?token=${ep.token}');
      if (_stopped) {
        await ws.close();
        return;
      }
      _ws = ws;
      _connected = true;
      _backoffSeconds = 1;
      onConnectionChanged?.call(true);
      ws.listen(
        _onData,
        onDone: _onDisconnect,
        onError: (_) => _onDisconnect(),
        cancelOnError: true,
      );
    } catch (e) {
      _scheduleReconnect();
    }
  }

  void _onData(dynamic data) {
    try {
      final m = jsonDecode(data as String) as Map<String, dynamic>;
      if (m['type'] == 'orders') {
        onSnapshot?.call(decodeOrders(m), m['canRecall'] == true);
      } else if (m['type'] == 'boton') {
        final btn = parseKdsButton((m['boton'] as String?) ?? '');
        if (btn != null) _botonController.add(btn);
      }
    } catch (e, st) {
      appLogger.warn('Mensaje KDS inválido del servidor.', e, st);
    }
  }

  void _onDisconnect() {
    if (!_connected) return;
    _connected = false;
    _ws = null;
    onConnectionChanged?.call(false);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_stopped) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _backoffSeconds), _connect);
    _backoffSeconds = (_backoffSeconds * 2).clamp(1, 10);
  }

  /// Manda un comando de la cocina al POS (no-op si no hay conexión; el POS es
  /// quien escribe en la BD).
  void send(String cmd, {int? orderId, String? status}) {
    try {
      _ws?.add(encodeCommand(cmd, orderId: orderId, status: status));
    } catch (_) {/* la reconexión reintenta */}
  }

  Future<void> stop() async {
    _stopped = true;
    _connected = false;
    _reconnectTimer?.cancel();
    try {
      await _ws?.close();
    } catch (_) {}
    _ws = null;
  }

  Future<void> dispose() async {
    await stop();
    await _botonController.close();
  }
}
