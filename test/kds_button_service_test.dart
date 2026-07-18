import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/services/kds_button_service.dart';

/// FASE 3.5 — Botonera física (ESP32 por WiFi/WebSocket). El firmware ya
/// validado en hardware manda strings de texto plano; estos tests cubren el
/// parseo y el servidor sin necesitar el ESP32 real.
void main() {
  group('KdsButtonService — round-trip con cliente real', () {
    late KdsButtonService service;
    const testPort = 18080; // puerto alto, poco probable que choque

    setUp(() async {
      service = KdsButtonService();
      await service.start(port: testPort);
    });
    tearDown(() => service.dispose());

    Future<WebSocket> connectAsEsp32() =>
        WebSocket.connect('ws://127.0.0.1:$testPort');

    test('cada string del firmware produce el KdsButton correcto (mapeo '
        'literal)', () async {
      final ws = await connectAsEsp32();
      final events = <KdsButton>[];
      final sub = service.botonPresionado.listen(events.add);

      const secuencia = [
        'ANTERIOR', 'SIGUIENTE', 'PREP', 'LISTO', 'RECALL', 'TIEMPO'
      ];
      for (final s in secuencia) {
        ws.add(s);
        await Future<void>.delayed(const Duration(milliseconds: 30));
      }

      expect(events, [
        KdsButton.anterior,
        KdsButton.siguiente,
        KdsButton.prep,
        KdsButton.listo,
        KdsButton.recall,
        KdsButton.tiempo,
      ]);

      await sub.cancel();
      await ws.close();
    });

    test('mensajes desconocidos se ignoran sin romper el stream', () async {
      final ws = await connectAsEsp32();
      final events = <KdsButton>[];
      final sub = service.botonPresionado.listen(events.add);

      ws.add('BASURA');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      // minúsculas también deben parsear (case-insensitive).
      ws.add('listo');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(events, [KdsButton.listo]);
      await sub.cancel();
      await ws.close();
    });

    test('conectado refleja el estado del socket del ESP32', () async {
      expect(service.conectado, isFalse);
      final ws = await connectAsEsp32();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(service.conectado, isTrue);
      await ws.close();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(service.conectado, isFalse);
    });
  });

  group('parseKdsButton — mapeo literal (sin intercambios)', () {
    test('cada string produce el KdsButton del mismo nombre', () {
      expect(parseKdsButton('ANTERIOR'), KdsButton.anterior);
      expect(parseKdsButton('SIGUIENTE'), KdsButton.siguiente);
      expect(parseKdsButton('PREP'), KdsButton.prep);
      expect(parseKdsButton('LISTO'), KdsButton.listo);
      expect(parseKdsButton('RECALL'), KdsButton.recall);
      expect(parseKdsButton('TIEMPO'), KdsButton.tiempo);
    });
  });

  group('start() en puerto ocupado no lanza (best-effort)', () {
    test('el segundo start() en el mismo puerto queda en silencio', () async {
      const port = 18081;
      final a = KdsButtonService();
      await a.start(port: port);
      expect(a.isRunning, isTrue);

      final b = KdsButtonService();
      await b.start(port: port); // no debe lanzar
      expect(b.isRunning, isFalse,
          reason: 'el puerto ya está tomado por "a"');

      await a.dispose();
      await b.dispose();
    });
  });
}
