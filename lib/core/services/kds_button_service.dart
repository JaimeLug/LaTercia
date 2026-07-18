import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/app_logger.dart';
import 'kds_server.dart' show kdsServerProvider;

/// FASE 3.5 — Botonera física de cocina (ESP32 por WiFi/WebSocket).
///
/// El ESP32 es **cliente**: se conecta él solo a este servidor (protocolo de
/// texto plano, sin token — así quedó grabado el firmware ya probado en
/// hardware real) y manda un string por cada botón presionado. Puerto fijo
/// 8080 para que coincida con el firmware sin tener que reflashearlo.
///
/// Deliberadamente un servidor **aparte** del WebSocket POS↔KDS de la Fase 5.1
/// (ese usa JSON+token en un puerto efímero para sincronizar el estado de la
/// BD entre procesos) — la botonera es solo un mando de una vía, sin relación
/// con ese protocolo.
///
/// Solo el primer proceso que llegue a bindear el puerto recibe los eventos —
/// si el KDS está embebido en el POS Y además hay una ventana KDS separada
/// abierta, la segunda simplemente no logra bindear y esta clase lo absorbe
/// como best-effort (log, sin crashear): el hardware siempre le habla a una
/// única "cocina" a la vez, que es justo el comportamiento esperado.
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

/// Parsea el string plano que manda el firmware a un [KdsButton] — público
/// para reusarse tanto en el KDS real como en el panel de prueba de
/// Configuración, sin duplicar la lista de nombres válidos en dos lugares.
///
/// Mapeo literal (string == nombre del botón). Hubo un intento de "corregir"
/// un supuesto intercambio LISTO/TIEMMPO en el cableado, pero causó una
/// regresión (TIEMPO y la navegación dejaron de funcionar) — se revirtió.
/// Si el cableado real tiene algo cruzado, hay que confirmarlo con el panel
/// de prueba (Admin → Botonera: qué casilla se ilumina al presionar cada
/// botón físico) antes de volver a tocar este mapeo.
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

  // Auditoría 2026-07-17 — rebote mecánico: un botón físico puede mandar
  // varios mensajes idénticos en milisegundos. Sin esto, cada rebote
  // disparaba sonido/toast/escritura a BD por separado, y —desde el reenvío
  // cross-proceso (3.5)— se reenviaba duplicado a la ventana KDS separada.
  KdsButton? _lastButton;
  DateTime? _lastButtonAt;
  static const _debounceWindow = Duration(milliseconds: 180);

  /// Best-effort: si el puerto ya está tomado (otra ventana KDS ya lo tiene),
  /// queda en silencio sin recibir eventos — nunca lanza hacia el caller.
  /// [port] es configurable desde Configuración (default 8080, el que trae
  /// grabado el firmware); cambiarlo aquí exige reflashear el ESP32 también.
  Future<void> start({int port = 8080}) async {
    if (_server != null) return;
    this.port = port;
    try {
      final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _server = server;
      appLogger.info('Servidor de botonera (ESP32) escuchando en :$port');
      server.listen(_handleRequest, onError: (e, st) {
        appLogger.warn('Error en el servidor de la botonera.', e, st as StackTrace?);
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
            // El stream crudo SIEMPRE recibe todo, rebote incluido — es el
            // diagnóstico de hardware (Admin → Botonera) y no debe ocultar
            // nada de lo que realmente llegó del ESP32.
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

/// El stream de botones que el KDS realmente escucha — indirección para que
/// funcione igual en las dos formas de mostrar la Cocina:
/// - **KDS embebido** (misma pestaña del proceso POS): el ESP32 solo puede
///   hablarle a UN proceso (single-writer natural del puerto 8080, siempre
///   gana el POS porque arranca primero) — aquí el default apunta al
///   [kdsButtonServiceProvider] local, que sí tiene el socket real, PERO se
///   silencia mientras haya una ventana KDS separada conectada
///   ([KdsServer.hasClients]): si no, el mismo botón físico se procesaba DOS
///   veces (una vez aquí, invisible, y otra reenviado a la ventana externa),
///   lo que rompía RECALL — el segundo `markReady` volvía a leer el pedido ya
///   en 'listo' y sobre-escribía el estado previo guardado para deshacer, así
///   que recall terminaba revirtiendo 'listo' → 'listo' (nada visible).
/// - **Ventana KDS separada** (otro proceso del SO): su propio
///   [KdsButtonService] JAMÁS logra bindear el puerto (ya lo tiene el POS), así
///   que sin esto se queda sordo. `main.dart` sobreescribe este provider con
///   el stream reenviado por [KdsClient] sobre el WS de sincronización de la
///   Fase 5.1 — el POS retransmite cada botón que le llega del ESP32 real.
final kdsButtonStreamProvider = Provider<Stream<KdsButton>>((ref) {
  final service = ref.watch(kdsButtonServiceProvider);
  final server = ref.watch(kdsServerProvider);
  return service.botonPresionado.where((_) => !server.hasClients);
});
