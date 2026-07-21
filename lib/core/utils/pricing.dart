import '../database/database.dart';

/// Aritmética pura de totales de una orden. Reglas: `docs/precios-e-iva.md`.

class OrderTotals {
  final double subtotal;
  final double discount;
  final double tax;
  final double total;

  const OrderTotals({
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
  });
}

/// `docs/precios-e-iva.md` §Descuentos.
double discountAmountFor(Discount? discount, double subtotal) {
  if (discount == null) return 0;
  final raw = discount.type == 'percentage'
      ? subtotal * discount.value / 100
      : discount.value;
  return raw.clamp(0.0, subtotal);
}

/// Totales con una sola tasa global. `docs/precios-e-iva.md`.
OrderTotals computeOrderTotals({
  required double subtotal,
  Discount? discount,
  double taxRate = 0,
}) {
  final d = discountAmountFor(discount, subtotal);
  final tax = (subtotal - d) * taxRate / 100;
  final total = subtotal - d + tax;
  return OrderTotals(
    subtotal: subtotal,
    discount: d,
    tax: tax,
    total: total < 0 ? 0 : total,
  );
}

// ─── Impuesto por producto (docs/precios-e-iva.md) ───────────────────────────

/// Una línea del carrito para el cálculo de IVA. `docs/precios-e-iva.md`.
class TaxLine {
  final double lineTotal;
  final double taxRate; // porcentaje, p.ej. 16 = 16%
  final bool taxIncluded;

  const TaxLine({
    required this.lineTotal,
    required this.taxRate,
    required this.taxIncluded,
  });
}

/// Tasa de IVA efectiva de un producto (la suya o el default global; nunca
/// negativa). `docs/precios-e-iva.md`.
double effectiveTaxRate(double? productRate, double globalRate) {
  final r = productRate ?? globalRate;
  return r < 0 ? 0 : r;
}

/// Modo de IVA efectivo de un producto (el suyo o el global).
bool effectiveTaxIncluded(bool? productIncluded, bool globalIncluded) =>
    productIncluded ?? globalIncluded;

/// Totales con IVA por línea; con líneas mixtas, [OrderTotals.total] es la
/// cifra autoritativa. `docs/precios-e-iva.md`.
OrderTotals computeTaxedTotals({
  required List<TaxLine> lines,
  Discount? discount,
}) {
  final grossSubtotal = lines.fold(0.0, (s, l) => s + l.lineTotal);
  final d = discountAmountFor(discount, grossSubtotal);
  final factor = grossSubtotal > 0 ? (grossSubtotal - d) / grossSubtotal : 1.0;

  double netAfter = 0; // base gravable tras descuento
  double taxAfter = 0; // IVA total tras descuento
  for (final l in lines) {
    final r = l.taxRate <= 0 ? 0.0 : l.taxRate;
    final net = l.taxIncluded ? l.lineTotal / (1 + r / 100) : l.lineTotal;
    final lineTax = l.taxIncluded ? l.lineTotal - net : net * r / 100;
    netAfter += net * factor;
    taxAfter += lineTax * factor;
  }
  final total = netAfter + taxAfter;
  return OrderTotals(
    subtotal: grossSubtotal,
    discount: d,
    tax: taxAfter,
    total: total < 0 ? 0 : total,
  );
}

/// Infiere, de los totales guardados, si el IVA estaba incluido en el total.
/// `docs/precios-e-iva.md`.
bool taxIsIncludedInTotal({
  required double subtotal,
  required double discount,
  required double tax,
  required double total,
}) {
  if (tax <= 0) return false;
  final asAdded = subtotal - discount + tax;
  return (asAdded - total).abs() > 0.01;
}

/// Si un descuento puede ofrecerse para la orden actual. `docs/precios-e-iva.md`.
bool isDiscountEligible(Discount d, double subtotal, DateTime now) {
  if (!d.active) return false;
  if (d.validFrom != null && now.isBefore(d.validFrom!)) return false;
  if (d.validUntil != null && now.isAfter(d.validUntil!)) return false;
  if (subtotal < d.minOrderAmount) return false;
  return true;
}
