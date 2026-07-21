import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/features/kds/kds_launcher.dart';
import 'package:screen_retriever/screen_retriever.dart';

/// El KDS se abre a pantalla completa y sin barra de título; si cae en el
/// monitor del POS lo tapa sin forma de cerrarlo (bloqueo reportado en sitio).
/// Por eso el selector nunca debe ofrecer el monitor principal.
void main() {
  const primary = Display(
    id: '0',
    size: Size(1920, 1080),
    visiblePosition: Offset(0, 0),
    visibleSize: Size(1920, 1080),
  );
  const secondary = Display(
    id: '1',
    size: Size(1280, 720),
    visiblePosition: Offset(1920, 0),
    visibleSize: Size(1280, 720),
  );

  test('el monitor principal (POS) NO es destino del KDS', () {
    expect(kdsDisplayIsPrimary(primary), isTrue);
    expect(kdsDisplayIsPrimary(secondary), isFalse);

    final targets = kdsTargetDisplays([primary, secondary]);
    expect(targets, [secondary]);
    expect(targets.contains(primary), isFalse,
        reason: 'ofrecer la pantalla del POS la taparía sin poder cerrarla');
  });

  test('con un solo monitor (el principal) no hay destinos', () {
    expect(kdsTargetDisplays([primary]), isEmpty);
  });
}
