import '../database/database.dart';

/// Pure order-total arithmetic, extracted from the POS widget so it can be
/// unit-tested in isolation (see test/pricing_test.dart).

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

/// Discount amount for a given subtotal, clamped to `[0, subtotal]`. A fixed
/// discount larger than the order can therefore never push the total (or the
/// change due) negative.
double discountAmountFor(Discount? discount, double subtotal) {
  if (discount == null) return 0;
  final raw = discount.type == 'percentage'
      ? subtotal * discount.value / 100
      : discount.value;
  return raw.clamp(0.0, subtotal);
}

/// Computes subtotal/discount/tax/total. Tax is applied on the discounted
/// amount. The total is clamped to be non-negative.
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

// ─── FASE 4.5 — Impuesto por producto ────────────────────────────────────────

/// Una línea del carrito reducida a lo que el cálculo de impuestos necesita:
/// su importe mostrado ([lineTotal]), su tasa efectiva ([taxRate], ya resuelta
/// contra el default global) y si ese precio ya trae el IVA dentro
/// ([taxIncluded]) o se le añade encima.
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

/// Tasa de IVA efectiva de un producto: la suya si la definió, si no el default
/// global. Nunca negativa.
double effectiveTaxRate(double? productRate, double globalRate) {
  final r = productRate ?? globalRate;
  return r < 0 ? 0 : r;
}

/// Modo de IVA efectivo de un producto: el suyo si lo definió, si no el global.
bool effectiveTaxIncluded(bool? productIncluded, bool globalIncluded) =>
    productIncluded ?? globalIncluded;

/// Totales de una orden con IVA calculado **por línea**, soportando tasas
/// distintas por producto y precios con IVA incluido o añadido en la misma
/// orden.
///
/// Semántica:
/// - [OrderTotals.subtotal] = suma de los precios mostrados de las líneas,
///   ANTES de descuento (para la fila "Subtotal" del POS). Para líneas con IVA
///   incluido ese precio ya trae el impuesto dentro.
/// - El descuento se calcula sobre ese subtotal mostrado y se prorratea entre
///   las líneas.
/// - [OrderTotals.tax] = IVA total desglosado (el "hacia atrás" de las líneas
///   con IVA incluido + el añadido de las que no) — es la cifra para el ticket
///   y los reportes fiscales.
/// - [OrderTotals.total] = lo que el cliente realmente paga. Para IVA incluido
///   NO se suma el IVA (ya está dentro del precio); para IVA añadido sí.
///
/// Nota: con líneas mixtas (unas con IVA incluido y otras añadido) la identidad
/// ingenua `subtotal - descuento + iva == total` no se cumple —es inherente al
/// IVA incluido—; [total] es siempre la cifra autoritativa.
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

/// Si el IVA de una orden ya está embebido en el total (IVA incluido) en vez de
/// sumarse encima (IVA añadido). Se infiere de los totales guardados —sin
/// columna extra—: si sumar el IVA al subtotal-descuento excede el total, es
/// que el total no creció por el IVA ⇒ estaba incluido.
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

/// Whether a discount may be offered for the current order: it must be active,
/// inside its validity window, and the subtotal must meet its minimum. These
/// rules are configured in admin but were previously ignored at checkout.
bool isDiscountEligible(Discount d, double subtotal, DateTime now) {
  if (!d.active) return false;
  if (d.validFrom != null && now.isBefore(d.validFrom!)) return false;
  if (d.validUntil != null && now.isAfter(d.validUntil!)) return false;
  if (subtotal < d.minOrderAmount) return false;
  return true;
}
