import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/utils/pricing.dart';

/// splitEvenly — división de cuenta en partes iguales. Ver
/// docs/division-cuenta.md.
void main() {
  test('reparte exacto cuando divide parejo', () {
    expect(splitEvenly(90, 3), [30, 30, 30]);
  });

  test('el sobrante de redondeo va a las primeras partes', () {
    final shares = splitEvenly(100, 3);
    expect(shares, [33.34, 33.33, 33.33]);
    expect(shares.reduce((a, b) => a + b), closeTo(100, 0.001));
  });

  test('la suma SIEMPRE da exacto el total, sin importar cuántas partes', () {
    for (final parts in [2, 3, 4, 5, 6, 7, 9, 11]) {
      final shares = splitEvenly(173.45, parts);
      final sum = shares.fold(0.0, (a, b) => a + b);
      expect(sum, closeTo(173.45, 0.001), reason: 'parts=$parts');
      expect(shares, hasLength(parts));
    }
  });

  test('parts <= 0: lista vacía', () {
    expect(splitEvenly(100, 0), isEmpty);
    expect(splitEvenly(100, -1), isEmpty);
  });

  test('total 0: todas las partes en 0', () {
    expect(splitEvenly(0, 4), [0, 0, 0, 0]);
  });
}
