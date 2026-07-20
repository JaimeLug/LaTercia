import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/utils/pricing.dart';

Discount _discount({
  String type = 'fixed',
  double value = 0,
  double minOrderAmount = 0,
  bool active = true,
  DateTime? validFrom,
  DateTime? validUntil,
}) {
  return Discount(
    id: 1,
    name: 'Test',
    type: type,
    value: value,
    minOrderAmount: minOrderAmount,
    active: active,
    validFrom: validFrom,
    validUntil: validUntil,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('discountAmountFor (I2)', () {
    test('sin descuento es 0', () {
      expect(discountAmountFor(null, 100), 0);
    });

    test('porcentaje', () {
      expect(
          discountAmountFor(_discount(type: 'percentage', value: 15), 200), 30);
    });

    test('fijo', () {
      expect(discountAmountFor(_discount(type: 'fixed', value: 50), 200), 50);
    });

    test('un descuento fijo mayor que el subtotal se limita al subtotal', () {
      expect(discountAmountFor(_discount(type: 'fixed', value: 500), 120), 120);
    });
  });

  group('computeOrderTotals (I2)', () {
    test('impuesto se aplica sobre el monto ya descontado', () {
      final t = computeOrderTotals(
        subtotal: 100,
        discount: _discount(type: 'percentage', value: 10), // -10
        taxRate: 16, // 16% de 90
      );
      expect(t.discount, 10);
      expect(t.tax, closeTo(14.4, 1e-9));
      expect(t.total, closeTo(104.4, 1e-9));
    });

    test('el total nunca es negativo aunque el descuento exceda el subtotal',
        () {
      final t = computeOrderTotals(
        subtotal: 80,
        discount: _discount(type: 'fixed', value: 999),
      );
      expect(t.discount, 80);
      expect(t.total, 0);
    });

    test('sin descuento ni impuesto, total == subtotal', () {
      final t = computeOrderTotals(subtotal: 42.5);
      expect(t.total, 42.5);
    });
  });

  group('computeTaxedTotals — IVA por producto (4.5)', () {
    TaxLine line(double total, {double rate = 0, bool included = true}) =>
        TaxLine(lineTotal: total, taxRate: rate, taxIncluded: included);

    test('IVA incluido: el precio ya trae el impuesto, el total no cambia', () {
      final t =
          computeTaxedTotals(lines: [line(116, rate: 16, included: true)]);
      expect(t.subtotal, 116);
      expect(t.tax, closeTo(16, 1e-9));
      expect(t.total, closeTo(116, 1e-9));
    });

    test('IVA añadido: el impuesto se suma encima', () {
      final t =
          computeTaxedTotals(lines: [line(100, rate: 16, included: false)]);
      expect(t.subtotal, 100);
      expect(t.tax, closeTo(16, 1e-9));
      expect(t.total, closeTo(116, 1e-9));
    });

    test('tasa 0 (cafetería por defecto): total == subtotal, sin IVA', () {
      final t = computeTaxedTotals(lines: [line(50), line(42.5)]);
      expect(t.tax, 0);
      expect(t.total, 92.5);
    });

    test('líneas mixtas incluido + añadido en la misma orden', () {
      final t = computeTaxedTotals(lines: [
        line(116, rate: 16, included: true), // paga 116, IVA 16
        line(100, rate: 16, included: false), // paga 116, IVA 16
      ]);
      expect(t.subtotal, 216);
      expect(t.tax, closeTo(32, 1e-9));
      expect(t.total, closeTo(232, 1e-9));
    });

    test('descuento se prorratea y el IVA incluido se recalcula sobre lo neto',
        () {
      final t = computeTaxedTotals(
        lines: [line(116, rate: 16, included: true)],
        discount: _discount(type: 'percentage', value: 10), // -11.6
      );
      expect(t.discount, closeTo(11.6, 1e-9));
      expect(t.tax, closeTo(14.4, 1e-9)); // 16 * 0.9
      expect(t.total, closeTo(104.4, 1e-9));
    });

    test('el total nunca es negativo', () {
      final t = computeTaxedTotals(
        lines: [line(80, rate: 16, included: false)],
        discount: _discount(type: 'fixed', value: 999),
      );
      expect(t.total, 0);
    });
  });

  group('tasa/modo efectivo por producto (4.5)', () {
    test('sin override usa el default global', () {
      expect(effectiveTaxRate(null, 16), 16);
      expect(effectiveTaxIncluded(null, true), isTrue);
    });
    test('el override del producto manda', () {
      expect(effectiveTaxRate(8, 16), 8);
      expect(effectiveTaxIncluded(false, true), isFalse);
    });
    test('tasa negativa se trata como 0', () {
      expect(effectiveTaxRate(-5, 16), 0);
    });
  });

  group('isDiscountEligible (I1)', () {
    final now = DateTime(2026, 6, 30, 12);

    test('descuento inactivo no aplica', () {
      expect(isDiscountEligible(_discount(active: false), 100, now), isFalse);
    });

    test('antes de validFrom no aplica', () {
      expect(
        isDiscountEligible(
            _discount(validFrom: DateTime(2026, 7, 1)), 100, now),
        isFalse,
      );
    });

    test('después de validUntil no aplica', () {
      expect(
        isDiscountEligible(
            _discount(validUntil: DateTime(2026, 6, 29)), 100, now),
        isFalse,
      );
    });

    test('subtotal por debajo del mínimo no aplica', () {
      expect(
        isDiscountEligible(_discount(minOrderAmount: 150), 100, now),
        isFalse,
      );
    });

    test('cumple todas las condiciones → aplica', () {
      expect(
        isDiscountEligible(
          _discount(
            minOrderAmount: 50,
            validFrom: DateTime(2026, 6, 1),
            validUntil: DateTime(2026, 12, 31),
          ),
          100,
          now,
        ),
        isTrue,
      );
    });
  });
}
