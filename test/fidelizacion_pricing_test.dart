import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/utils/pricing.dart';

/// Elegibilidad y monto de la recompensa de fidelización. Ver
/// docs/fidelizacion.md.
void main() {
  group('loyaltyRewardAvailable', () {
    test('sellos: elegible al llegar al umbral', () {
      expect(
          loyaltyRewardAvailable(
              loyaltyType: 'sellos',
              stamps: 10,
              stampsRequired: 10,
              points: 0,
              pointsRequired: 0),
          isTrue);
    });

    test('sellos: NO elegible por debajo del umbral', () {
      expect(
          loyaltyRewardAvailable(
              loyaltyType: 'sellos',
              stamps: 9,
              stampsRequired: 10,
              points: 0,
              pointsRequired: 0),
          isFalse);
    });

    test('puntos: elegible al llegar/pasar el umbral', () {
      expect(
          loyaltyRewardAvailable(
              loyaltyType: 'puntos',
              stamps: 0,
              stampsRequired: 0,
              points: 120,
              pointsRequired: 100),
          isTrue);
    });

    test('puntos: NO elegible por debajo del umbral', () {
      expect(
          loyaltyRewardAvailable(
              loyaltyType: 'puntos',
              stamps: 0,
              stampsRequired: 0,
              points: 80,
              pointsRequired: 100),
          isFalse);
    });

    test('ninguno: nunca elegible aunque los contadores alcancen', () {
      expect(
          loyaltyRewardAvailable(
              loyaltyType: 'ninguno',
              stamps: 99,
              stampsRequired: 1,
              points: 999,
              pointsRequired: 1),
          isFalse);
    });

    test('umbral en 0: nunca elegible (evita canje gratis por config vacía)',
        () {
      expect(
          loyaltyRewardAvailable(
              loyaltyType: 'sellos',
              stamps: 5,
              stampsRequired: 0,
              points: 0,
              pointsRequired: 0),
          isFalse);
    });
  });

  group('loyaltyRewardAmount', () {
    const cafe = (unitPrice: 35.0, quantity: 1, productName: 'Café');
    const cafeGrande =
        (unitPrice: 45.0, quantity: 1, productName: 'Café grande');
    const pan = (unitPrice: 20.0, quantity: 1, productName: 'Pan dulce');

    test('toma el precio del producto elegido', () {
      expect(loyaltyRewardAmount([cafe, cafeGrande, pan], 'Café grande'),
          closeTo(45, 0.001));
    });

    test('sin ese producto en el carrito: 0', () {
      expect(loyaltyRewardAmount([pan], 'Café'), 0);
    });

    test('case-insensitive', () {
      expect(loyaltyRewardAmount([cafe], 'CAFÉ'), closeTo(35, 0.001));
    });

    test('carrito vacío: 0', () {
      expect(loyaltyRewardAmount(const [], 'Café'), 0);
    });
  });
}
