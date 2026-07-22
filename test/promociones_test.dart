import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/utils/pricing.dart';

/// Promociones programadas: ventana de día/hora, 2x1 y alcance por categoría.
/// Ver docs/promociones.md.
Discount _discount({
  String type = 'percentage',
  double value = 0,
  double minOrderAmount = 0,
  bool active = true,
  DateTime? validFrom,
  DateTime? validUntil,
  String? daysOfWeek,
  String? startTime,
  String? endTime,
  String? categoryScope,
}) {
  return Discount(
    id: 1,
    name: 'Promo',
    type: type,
    value: value,
    minOrderAmount: minOrderAmount,
    active: active,
    validFrom: validFrom,
    validUntil: validUntil,
    daysOfWeek: daysOfWeek,
    startTime: startTime,
    endTime: endTime,
    categoryScope: categoryScope,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('isDiscountEligible — día de la semana', () {
    // 2026-07-21 es martes (weekday=2); 2026-07-25 es sábado (weekday=6).
    final martes = DateTime(2026, 7, 21, 12);
    final sabado = DateTime(2026, 7, 25, 12);

    test('sin daysOfWeek: elegible cualquier día', () {
      final d = _discount();
      expect(isDiscountEligible(d, 100, martes), isTrue);
      expect(isDiscountEligible(d, 100, sabado), isTrue);
    });

    test('lun-vie (1-5): elegible martes, NO sábado', () {
      final d = _discount(daysOfWeek: '1,2,3,4,5');
      expect(isDiscountEligible(d, 100, martes), isTrue);
      expect(isDiscountEligible(d, 100, sabado), isFalse);
    });
  });

  group('isDiscountEligible — ventana de hora', () {
    test('sin ventana: elegible a cualquier hora', () {
      final d = _discount();
      expect(isDiscountEligible(d, 100, DateTime(2026, 7, 21, 3)), isTrue);
    });

    test('happy hour 15:00-17:00: elegible adentro, no afuera', () {
      final d = _discount(startTime: '15:00', endTime: '17:00');
      expect(isDiscountEligible(d, 100, DateTime(2026, 7, 21, 16)), isTrue);
      expect(isDiscountEligible(d, 100, DateTime(2026, 7, 21, 15)), isTrue);
      expect(isDiscountEligible(d, 100, DateTime(2026, 7, 21, 17)), isTrue);
      expect(
          isDiscountEligible(d, 100, DateTime(2026, 7, 21, 14, 59)), isFalse);
      expect(isDiscountEligible(d, 100, DateTime(2026, 7, 21, 17, 1)), isFalse);
    });

    test('ventana que cruza medianoche 22:00-02:00', () {
      final d = _discount(startTime: '22:00', endTime: '02:00');
      expect(isDiscountEligible(d, 100, DateTime(2026, 7, 21, 23)), isTrue);
      expect(isDiscountEligible(d, 100, DateTime(2026, 7, 21, 1)), isTrue);
      expect(isDiscountEligible(d, 100, DateTime(2026, 7, 21, 12)), isFalse);
    });

    test('falta uno de los dos (solo startTime): sin restricción', () {
      final d = _discount(startTime: '15:00');
      expect(isDiscountEligible(d, 100, DateTime(2026, 7, 21, 3)), isTrue);
    });

    test('hora mal formada: falla cerrado (no elegible)', () {
      final d = _discount(startTime: '25:99', endTime: '17:00');
      expect(isDiscountEligible(d, 100, DateTime(2026, 7, 21, 16)), isFalse);
    });
  });

  group('isScheduledDiscount', () {
    test('sin días ni hora: no programada', () {
      expect(isScheduledDiscount(_discount()), isFalse);
    });
    test('con días: programada', () {
      expect(isScheduledDiscount(_discount(daysOfWeek: '1,2')), isTrue);
    });
    test('con ventana de hora completa: programada', () {
      expect(
          isScheduledDiscount(_discount(startTime: '15:00', endTime: '17:00')),
          isTrue);
    });
    test('con solo un lado de la hora: NO cuenta como programada', () {
      expect(isScheduledDiscount(_discount(startTime: '15:00')), isFalse);
    });
  });

  group('discountAmountForCart', () {
    const cafe =
        (unitPrice: 35.0, quantity: 3, categoryName: 'Bebidas calientes');
    const pan = (unitPrice: 20.0, quantity: 2, categoryName: 'Panadería');

    test('porcentaje sin alcance: igual que discountAmountFor de siempre', () {
      final d = _discount(type: 'percentage', value: 10);
      final lines = [cafe, pan];
      final subtotal = lines.fold(0.0, (s, l) => s + l.unitPrice * l.quantity);
      expect(discountAmountForCart(d, lines),
          closeTo(discountAmountFor(d, subtotal), 0.001));
    });

    test('porcentaje CON alcance: solo cuenta el subtotal de esa categoría',
        () {
      final d = _discount(
          type: 'percentage', value: 10, categoryScope: 'Bebidas calientes');
      // Solo café (3×35=105); pan queda fuera.
      expect(discountAmountForCart(d, [cafe, pan]), closeTo(10.5, 0.001));
    });

    test('2x1 sin alcance: cada línea, cada 2 unidades 1 gratis', () {
      final d = _discount(type: '2x1');
      // café: 3 unidades → 1 gratis (35); pan: 2 unidades → 1 gratis (20).
      expect(discountAmountForCart(d, [cafe, pan]), closeTo(55, 0.001));
    });

    test('2x1 con alcance de categoría: solo esa línea cuenta', () {
      final d = _discount(type: '2x1', categoryScope: 'Panadería');
      // Solo pan: 2 unidades → 1 gratis (20). Café queda fuera.
      expect(discountAmountForCart(d, [cafe, pan]), closeTo(20, 0.001));
    });

    test('2x1 con cantidad impar: redondea hacia abajo', () {
      final d = _discount(type: '2x1');
      const linea = (unitPrice: 10.0, quantity: 5, categoryName: 'Bebidas');
      // 5 ~/ 2 = 2 gratis.
      expect(discountAmountForCart(d, [linea]), closeTo(20, 0.001));
    });

    test('alcance case-insensitive y con varias categorías (CSV)', () {
      final d =
          _discount(type: 'fixed', value: 5, categoryScope: 'panadería,otros');
      expect(discountAmountForCart(d, [pan]), closeTo(5, 0.001));
    });

    test('alcance que no matchea ninguna línea: descuento 0', () {
      final d =
          _discount(type: 'percentage', value: 50, categoryScope: 'Postres');
      expect(discountAmountForCart(d, [cafe, pan]), 0);
    });
  });
}
