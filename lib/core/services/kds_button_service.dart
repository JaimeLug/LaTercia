import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/app_logger.dart';
import 'kds_server.dart' show kdsServerProvider;

// Botonera física de cocina (ESP32 por WiFi/WebSocket, puerto 8080, texto
// plano). Servidor aparte del enlace POS↔KDS. `docs/kds-conexion.md` §Botonera.
enum KdsButton { anterior, siguiente, prep, listo, recall, tiempo }

/// El literal exacto que manda el firmware por cada botón — mismo orden que
/// el array `pinesBotones`/`nombresBotones` del sketch, para que el panel de
/// prueba de Configuración pueda mostrar los 6 botones en el mismo orden
/// físico de la caja.
const kdsButtonOrder = [
  KdsButton.anterior,
  KdsButton.siguiente,
  KdsButton.prep,
  KdsButton.listo,
  KdsButton.recall,
  KdsButton.tiempo,
];

String kdsButtonLabel(KdsButton b) => switch (b) {
      KdsButton.anterior => 'ANTERIOR',
      KdsButton.siguiente => 'SIGUIENTE',
      KdsButton.prep => 'PREP',
      KdsButton.listo => 'LISTO',
      KdsButton.recall => 'RECALL',
      KdsButton.tiempo => 'TIEMPO',
    };

/// Parsea el string plano del firmware a un [KdsButton] (mapeo literal). No
/// tocar el mapeo sin confirmar el cableado con Admin → Botonera.
/// `docs/kds-conexion.md` §"Mapeo de botones".
KdsButton? parseKdsButton(String raw) {
  final upper = raw.trim().toUpperCase();
  for (final b in kdsButtonOrder) {
    if (kdsButtonLabel(b) == upper) return b;
  }
  return null;
}

class KdsButtonService {
  KdsButtonService();

  int? port;
  HttpServer? _server;
  WebSocket? _clientSocket;
  final _controller = StreamController<KdsButton>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<KdsButton> get botonPresionado => _controller.stream;

  /// Emite `true`/`false` cada vez que el ESP32 se conecta o desconecta —
  /// para que Configuración pueda mostrar el estado en vivo sin encuestar.
  Stream<bool> get connectionChanged => _connectionController.stream;

  /// Emite CADA string recibido del ESP32, reconocido o no — diagnóstico para
  /// confirmar si un botón físico realmente llega a la app (útil para separar
  /// un problema de cableado/soldadura de uno de la app: si el mensaje nunca
  /// aparece aquí, el problema está antes de llegar al software).
  final _rawController = StreamController<String>.broadcast();
  Stream<String> get mensajeCrudo => _rawController.stream;

  bool get conectado => _clientSocket != null;
  bool get isRunning => _server != null;

  // Anti-rebote mecánico (ventana de 180 ms). docs/kds-conexion.md §Botonera.
  KdsButton? _lastButton;
  DateTime? _lastButtonAt;
  static const _debounceWindow = Duration(milliseconds: 180);

  /// Best-effort: si el puerto ya está tomado, queda en silencio sin lanzar.
  /// [port] configurable (default 8080; cambiarlo exige reflashear el ESP32).
  /// `docs/kds-conexion.md`.
  Future<void> start({int port = 8080}) async {
    if (_server != null) return;
    this.port = port;
    try {
      final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _server = server;
      appLogger.info('Servidor de botonera (ESP32) escuchando en :$port');
      server.listen(_handleRequest, onError: (e, st) {
        appLogger.warn(
            'Error en el servidor de la botonera.', e, st as StackTrace?);
      });
    } catch (e, st) {
      appLogger.warn(
          'No se pudo levantar el servidor de la botonera en :$port '
          '(puerto ya en uso por otra ventana KDS, probablemente).',
          e,
          st);
    }
  }

  /// Detiene el servidor — usado cuando se apaga el flag `botonera_activa`
  /// desde Configuración sin tener que cerrar la app.
  Future<void> stop() async {
    await _clientSocket?.close();
    _clientSocket = null;
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
      return;
    }
    try {
      final socket = await WebSocketTransformer.upgrade(request);
      _clientSocket = socket;
      appLogger.info('Botonera (ESP32) conectada.');
      _connectionController.add(true);
      socket.listen(
        (message) {
          if (message is String) {
            // El stream crudo recibe TODO (rebote incluido): es el diagnóstico
            // de hardware de Admin → Botonera. docs/kds-conexion.md.
            _rawController.add(message);
            final boton = parseKdsButton(message);
            if (boton == null) return;

            final now = DateTime.now();
            final isBounce = boton == _lastButton &&
                _lastButtonAt != null &&
                now.difference(_lastButtonAt!) < _debounceWindow;
            _lastButton = boton;
            _lastButtonAt = now;
            if (!isBounce) _controller.add(boton);
          }
        },
        onDone: () {
          _clientSocket = null;
          appLogger.info('Botonera (ESP32) desconectada.');
          _connectionController.add(false);
        },
        onError: (_) {
          _clientSocket = null;
          _connectionController.add(false);
        },
      );
    } catch (e, st) {
      appLogger.warn('No se pudo aceptar la conexión de la botonera.', e, st);
    }
  }

  Future<void> dispose() async {
    await _clientSocket?.close();
    await _server?.close(force: true);
    await _controller.close();
    await _connectionController.close();
    await _rawController.close();
  }
}

final kdsButtonServiceProvider = Provider<KdsButtonService>((ref) {
  final service = KdsButtonService();
  ref.onDispose(service.dispose);
  return service;
});

/// Stream de botones que el KDS realmente escucha. En el KDS embebido apunta al
/// servicio local pero se **silencia** si hay una ventana KDS separada conectada
/// (evita el doble proceso que rompía RECALL); en la ventana separada, `main.dart`
/// lo sobreescribe con el stream que [KdsClient] recibe retransmitido del POS.
/// `docs/kds-conexion.md` §"El bug de RECALL".
final kdsButtonStreamProvider = Provider<Stream<KdsButton>>((ref) {
  final service = ref.watch(kdsButtonServiceProvider);
  final server = ref.watch(kdsServerProvider);
  return service.botonPresionado.where((_) => !server.hasClients);
});
