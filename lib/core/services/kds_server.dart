import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_with_items.dart';
import '../utils/app_logger.dart';
import 'kds_link.dart';

/// Un único servidor por proceso POS. Solo se usa en el proceso POS (el KDS
/// separado usa [KdsClient]).
final kdsServerProvider = Provider<KdsServer>((ref) {
  final server = KdsServer();
  ref.onDispose(server.stop);
  return server;
});

/// FASE 5.1 — Servidor WebSocket local que corre en el proceso POS (el único
/// dueño de la BD). Empuja los pedidos activos a las ventanas KDS conectadas y
/// ejecuta los comandos que estas mandan a través de los callbacks.
///
/// Bind a 127.0.0.1 con puerto efímero (se publica en el archivo de endpoint) y
/// un token aleatorio por sesión para que solo el KDS local pueda conectarse.
class KdsServer {
  HttpServer? _server;
  String? _token;
  final Set<WebSocket> _clients = {};
  String? _lastMessage;

  // B2 — límites defensivos: los comandos son diminutos y las cocinas pocas.
  static const _maxClients = 8;
  static const _maxCommandBytes = 4096;

  // Callbacks que el POS conecta a su OrdersNotifier (dueño de la BD).
  Future<void> Function(int orderId)? onMarkReady;
  Future<void> Function(int orderId, String status)? onUpdateStatus;
  Future<void> Function()? onRecall;

  bool get isRunning => _server != null;

  /// Solo para tests (en producción el KDS descubre el endpoint por archivo).
  @visibleForTesting
  int? get port => _server?.port;
  @visibleForTesting
  String? get token => _token;

  Future<void> start() async {
    if (_server != null) return;
    _token = _generateToken();
    // Puerto 0 = el SO asigna uno libre; lo publicamos en el endpoint file.
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    try {
      await writeKdsEndpoint(server.port, _token!);
    } catch (e, st) {
      // Best-effort: sin el archivo el KDS no se auto-conecta, pero el servidor
      // sigue vivo (y en tests no hay path_provider).
      appLogger.warn('No se pudo publicar el endpoint KDS.', e, st);
    }
    appLogger.info('Servidor KDS WS en 127.0.0.1:${server.port}');
    server.listen(_handleRequest, onError: (e, st) {
      appLogger.warn('Error en el servidor KDS WS.', e, st as StackTrace?);
    });
  }

  Future<void> _handleRequest(HttpRequest req) async {
    if (!WebSocketTransformer.isUpgradeRequest(req) ||
        req.uri.path != kdsWsPath) {
      req.response.statusCode = HttpStatus.notFound;
      await req.response.close();
      return;
    }
    if (req.uri.queryParameters['token'] != _token) {
      req.response.statusCode = HttpStatus.forbidden;
      await req.response.close();
      return;
    }
    if (_clients.length >= _maxClients) {
      req.response.statusCode = HttpStatus.serviceUnavailable;
      await req.response.close();
      return;
    }
    try {
      final ws = await WebSocketTransformer.upgrade(req);
      _clients.add(ws);
      // Snapshot inmediato al conectar, para no esperar al próximo broadcast.
      if (_lastMessage != null) ws.add(_lastMessage);
      ws.listen(
        (data) => _onMessage(data),
        onDone: () => _clients.remove(ws),
        onError: (_) => _clients.remove(ws),
        cancelOnError: true,
      );
    } catch (e, st) {
      appLogger.warn('No se pudo aceptar la conexión KDS.', e, st);
    }
  }

  /// Empuja el snapshot actual a todas las cocinas conectadas. Si el contenido
  /// es idéntico al último enviado (M3), no reenvía —el POS emite en cada tick
  /// de 2 s aunque nada cambie— pero conserva el snapshot para clientes nuevos.
  void broadcast(List<OrderWithItems> orders, bool canRecall) {
    final msg = encodeOrdersMessage(orders, canRecall);
    if (msg == _lastMessage) return;
    _lastMessage = msg;
    for (final ws in _clients.toList()) {
      try {
        ws.add(msg);
      } catch (_) {
        _clients.remove(ws);
      }
    }
  }

  Future<void> _onMessage(dynamic data) async {
    try {
      // B2 — ignora payloads no-string o anormalmente grandes (los comandos
      // legítimos son de decenas de bytes).
      if (data is! String || data.length > _maxCommandBytes) return;
      final m = jsonDecode(data) as Map<String, dynamic>;
      if (m['type'] != 'cmd') return;
      switch (m['cmd']) {
        case 'markReady':
          await onMarkReady?.call(m['orderId'] as int);
          break;
        case 'updateStatus':
          await onUpdateStatus?.call(
              m['orderId'] as int, m['status'] as String);
          break;
        case 'recall':
          await onRecall?.call();
          break;
      }
    } catch (e, st) {
      appLogger.warn('Comando KDS inválido, ignorado.', e, st);
    }
  }

  Future<void> stop() async {
    for (final ws in _clients.toList()) {
      try {
        await ws.close();
      } catch (_) {}
    }
    _clients.clear();
    await _server?.close(force: true);
    _server = null;
  }

  static String _generateToken() {
    final r = Random.secure();
    return List.generate(24, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
