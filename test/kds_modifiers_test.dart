import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/utils/kds_modifiers.dart';

void main() {
  group('parseKdsModifiers', () {
    test('nulo o vacío devuelve lista vacía, sin lanzar', () {
      expect(parseKdsModifiers(null), isEmpty);
      expect(parseKdsModifiers(''), isEmpty);
    });

    test('JSON inválido devuelve lista vacía, sin lanzar', () {
      expect(parseKdsModifiers('esto no es json'), isEmpty);
    });

    test('la lista devuelta es MUTABLE (se puede ordenar) — bug real: '
        'devolver const [] revienta al hacer ..sort() en la vista All-day',
        () {
      expect(() => parseKdsModifiers(null).sort(), returnsNormally);
      expect(() => parseKdsModifiers('').sort(), returnsNormally);
      expect(() => parseKdsModifiers('json inválido').sort(), returnsNormally);
    });

    test('parsea nombre e incluido', () {
      final mods = parseKdsModifiers(
          '[{"name":"Extra shot","included":false},'
          '{"name":"Leche de almendra","included":true}]');

      expect(mods, hasLength(2));
      expect(mods[0].name, 'Extra shot');
      expect(mods[0].included, isFalse);
      expect(mods[0].label, 'Extra shot');
      expect(mods[1].included, isTrue);
      expect(mods[1].label, 'Leche de almendra (incluido)');
    });
  });
}
