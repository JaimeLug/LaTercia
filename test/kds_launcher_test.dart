import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/services/display_service.dart';
import 'package:latercia/features/kds/kds_launcher.dart';

/// El KDS se abre a pantalla completa y sin barra de título; si cae en el
/// monitor del POS lo tapa sin forma de cerrarlo (bloqueo reportado en sitio).
/// Por eso el selector nunca debe ofrecer el monitor principal.
void main() {
  const primary = MonitorInfo(
    id: 'DP-1',
    systemName: 'DP-1',
    width: 1920,
    height: 1080,
    x: 0,
    y: 0,
    isPrimary: true,
  );
  const secondary = MonitorInfo(
    id: 'HDMI-1',
    systemName: 'HDMI-1',
    width: 1920,
    height: 1080,
    x: 1920,
    y: 0,
    isPrimary: false,
  );

  test('el monitor principal (POS) NO es destino del KDS', () {
    final targets = kdsTargetMonitors([primary, secondary]);
    expect(targets.map((m) => m.id), ['HDMI-1']);
    expect(targets.any((m) => m.isPrimary), isFalse,
        reason: 'ofrecer la pantalla del POS la taparía sin poder cerrarla');
  });

  test('con un solo monitor (el principal) no hay destinos', () {
    expect(kdsTargetMonitors([primary]), isEmpty);
  });
}
