import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/services/display_service.dart';

/// Parser de `xrandr --query` para la sección de Monitores. Ver
/// docs/monitores.md.
void main() {
  // Salida típica de `xrandr --query` con dos monitores conectados y uno
  // desconectado (recortada en los modos, que v1 no usa).
  const salida = '''
Screen 0: minimum 320 x 200, current 3840 x 1080, maximum 16384 x 16384
DP-1 connected primary 1920x1080+0+0 (normal left inverted right x axis y axis) 527mm x 296mm
   1920x1080     60.00*+  59.94    50.00
   1680x1050     59.95
HDMI-1 connected 1920x1080+1920+0 (normal left inverted right x axis y axis) 521mm x 293mm
   1920x1080     60.00*+
DP-2 disconnected (normal left inverted right x axis y axis)
VGA-1 disconnected (normal left inverted right x axis y axis)
''';

  test('parsea solo los conectados, con conector, resolución y posición', () {
    final monitors = parseXrandr(salida);

    expect(monitors, hasLength(2)); // los desconectados no entran
    expect(monitors.map((m) => m.id), ['DP-1', 'HDMI-1']);

    final dp1 = monitors[0];
    expect(dp1.isPrimary, isTrue);
    expect(dp1.resolution, '1920×1080');
    expect(dp1.x, 0);
    expect(dp1.y, 0);

    final hdmi = monitors[1];
    expect(hdmi.isPrimary, isFalse);
    expect(hdmi.x, 1920); // segundo monitor a la derecha
    expect(hdmi.y, 0);
  });

  test('captura los modos (resoluciones) disponibles de cada monitor', () {
    final monitors = parseXrandr(salida);
    // DP-1 lista 1920x1080 y 1680x1050 (sin duplicar); el modo actual queda.
    expect(monitors[0].modes, containsAll(['1920x1080', '1680x1050']));
    expect(monitors[0].currentMode, '1920x1080');
    // HDMI-1 solo trae 1920x1080 en la salida de ejemplo.
    expect(monitors[1].modes, ['1920x1080']);
  });

  test('salida vacía o sin conectados no revienta', () {
    expect(parseXrandr(''), isEmpty);
    expect(parseXrandr('DP-1 disconnected (normal)'), isEmpty);
  });

  group('nombres amigables', () {
    test('decodifica el JSON guardado', () {
      final n = DisplayService.nombresGuardados('{"DP-2":"Cocina pared"}');
      expect(n['DP-2'], 'Cocina pared');
    });

    test('null / vacío / corrupto → mapa vacío', () {
      expect(DisplayService.nombresGuardados(null), isEmpty);
      expect(DisplayService.nombresGuardados(''), isEmpty);
      expect(DisplayService.nombresGuardados('no es json'), isEmpty);
    });

    test('ida y vuelta encode/decode', () {
      const nombres = {'DP-1': 'POS', 'HDMI-1': 'Cocina'};
      final raw = DisplayService.encodeNombres(nombres);
      expect(DisplayService.nombresGuardados(raw), nombres);
    });
  });

  group('resoluciones guardadas', () {
    test('ida y vuelta encode/decode', () {
      const res = {'HDMI-1': '1920x1080'};
      final raw = DisplayService.encodeResoluciones(res);
      expect(DisplayService.resolucionesGuardadas(raw), res);
    });

    test('null / corrupto → vacío', () {
      expect(DisplayService.resolucionesGuardadas(null), isEmpty);
      expect(DisplayService.resolucionesGuardadas('x'), isEmpty);
    });
  });
}
