import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/utils/kds_selection.dart';

/// Cubre el bug reportado por el usuario probando la botonera física: "PREP
/// y LISTO solo sirven una vez" — causado por que la selección se perdía
/// (quedaba null o apuntando a una orden ya no activa) y esos botones se
/// volvían no-op silencioso hasta la siguiente navegación manual.
void main() {
  group('effectiveSelection', () {
    test('sin órdenes activas, no hay selección', () {
      expect(effectiveSelection([], 5), isNull);
    });

    test('sin selección previa, cae en la primera activa', () {
      expect(effectiveSelection([10, 20, 30], null), 10);
    });

    test('la selección sigue vigente si sigue activa', () {
      expect(effectiveSelection([10, 20, 30], 20), 20);
    });

    test(
        'si la seleccionada ya no está activa (el bug reportado), cae en la '
        'primera en vez de quedar en null para siempre', () {
      expect(effectiveSelection([10, 20, 30], 99), 10);
    });
  });

  group('nextAfterReady', () {
    test('avanza a la siguiente de la lista (cadencia de bump bar)', () {
      expect(nextAfterReady([10, 20, 30], 10), 20);
    });

    test('si se marca lista la del medio, la siguiente ocupa su lugar', () {
      expect(nextAfterReady([10, 20, 30], 20), 30);
    });

    test('si se marca lista la última, envuelve a la primera', () {
      expect(nextAfterReady([10, 20, 30], 30), 10);
    });

    test('si era la única activa, no queda ninguna selección', () {
      expect(nextAfterReady([10], 10), isNull);
    });

    test('un id que no estaba en la lista no rompe nada', () {
      expect(nextAfterReady([10, 20], 99), isNull);
    });
  });
}
