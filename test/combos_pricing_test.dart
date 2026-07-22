import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/utils/pricing.dart';

/// Reparto del precio de un combo entre sus componentes. Ver docs/combos.md.
void main() {
  group('proratedComboPrices', () {
    test(
        'reparte proporcional al precio normal — la suma da el precio del combo',
        () {
      // Café ($35) + Pan ($20) = $55 normal; combo cuesta $45.
      final prices = proratedComboPrices(45, const [
        (basePrice: 35.0, quantity: 1),
        (basePrice: 20.0, quantity: 1),
      ]);
      expect(prices, hasLength(2));
      // factor = 45/55; café = 35*factor, pan = 20*factor.
      expect(prices[0], closeTo(28.6364, 0.001));
      expect(prices[1], closeTo(16.3636, 0.001));
      final sum = prices[0] * 1 + prices[1] * 1;
      expect(sum, closeTo(45, 0.001));
    });

    test('respeta la cantidad de cada componente en el prorrateo', () {
      // 2 cafés ($35 c/u) + 1 pan ($20) = $90 normal; combo cuesta $72 (80%).
      final prices = proratedComboPrices(72, const [
        (basePrice: 35.0, quantity: 2),
        (basePrice: 20.0, quantity: 1),
      ]);
      final sum = prices[0] * 2 + prices[1] * 1;
      expect(sum, closeTo(72, 0.001));
      // factor = 0.8 exacto.
      expect(prices[0], closeTo(28, 0.001));
      expect(prices[1], closeTo(16, 0.001));
    });

    test('lista vacía: sin componentes', () {
      expect(proratedComboPrices(50, const []), isEmpty);
    });

    test('precios normales en 0: reparte en partes iguales (evita div/0)', () {
      final prices = proratedComboPrices(30, const [
        (basePrice: 0.0, quantity: 1),
        (basePrice: 0.0, quantity: 1),
      ]);
      expect(prices, [15, 15]);
    });

    test('un solo componente: se queda con todo el precio del combo', () {
      final prices =
          proratedComboPrices(25, const [(basePrice: 30.0, quantity: 1)]);
      expect(prices.single, closeTo(25, 0.001));
    });
  });
}
