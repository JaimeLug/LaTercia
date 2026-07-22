import '../database/database.dart';
import '../models/order_with_items.dart' show CartItem;

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

/// Si un descuento puede ofrecerse para la orden actual. `docs/precios-e-iva.md`;
/// la ventana de día/hora es de `docs/promociones.md`.
bool isDiscountEligible(Discount d, double subtotal, DateTime now) {
  if (!d.active) return false;
  if (d.validFrom != null && now.isBefore(d.validFrom!)) return false;
  if (d.validUntil != null && now.isAfter(d.validUntil!)) return false;
  if (subtotal < d.minOrderAmount) return false;
  if (!_matchesDayOfWeek(d.daysOfWeek, now)) return false;
  if (!_matchesTimeWindow(d.startTime, d.endTime, now)) return false;
  return true;
}

// ─── Promociones programadas (docs/promociones.md) ───────────────────────────

bool _matchesDayOfWeek(String? csv, DateTime now) {
  final s = csv?.trim();
  if (s == null || s.isEmpty) return true; // sin restricción = todos los días
  final days = s.split(',').map((e) => int.tryParse(e.trim())).whereType<int>();
  return days.contains(now.weekday); // DateTime.weekday: 1=lun..7=dom
}

bool _matchesTimeWindow(String? start, String? end, DateTime now) {
  final s = (start ?? '').trim();
  final e = (end ?? '').trim();
  if (s.isEmpty || e.isEmpty) return true; // falta uno de los dos = sin ventana
  final sMin = _minutesOfDay(s);
  final eMin = _minutesOfDay(e);
  if (sMin == null || eMin == null) {
    return false; // dato mal formado: falla cerrado
  }
  final nowMin = now.hour * 60 + now.minute;
  if (sMin <= eMin) return nowMin >= sMin && nowMin <= eMin;
  return nowMin >= sMin || nowMin <= eMin; // cruza medianoche (ej. 22:00–02:00)
}

int? _minutesOfDay(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) return null;
  return h * 60 + m;
}

/// `true` si [d] tiene alguna restricción de día/hora — distingue una
/// promoción programada (happy hour, que se auto-aplica en el POS) de un
/// descuento manual de mostrador. `docs/promociones.md`.
bool isScheduledDiscount(Discount d) {
  final hasDays = (d.daysOfWeek ?? '').trim().isNotEmpty;
  final hasTime = (d.startTime ?? '').trim().isNotEmpty &&
      (d.endTime ?? '').trim().isNotEmpty;
  return hasDays || hasTime;
}

/// Una línea del carrito relevante para calcular una promoción: precio
/// unitario, cantidad y el nombre de su producto (para el alcance).
/// `docs/promociones.md`.
typedef PromoLine = ({double unitPrice, int quantity, String? productName});

/// Filtra [lines] al `productScope` de [d] — mismo criterio CSV
/// case-insensitive que usaba el alcance por categoría (vacío = todas).
List<PromoLine> _linesInScope(Discount d, List<PromoLine> lines) {
  final scope = (d.productScope ?? '').trim();
  if (scope.isEmpty) return lines;
  final names = scope.split(',').map((s) => s.trim().toLowerCase()).toSet();
  return lines
      .where((l) => names.contains((l.productName ?? '').trim().toLowerCase()))
      .toList();
}

/// Monto de descuento de [d] sobre el carrito [lines], respetando su alcance
/// de producto. Si `type == '2x1'`, por cada línea en alcance cada 2 unidades
/// dejan 1 gratis (redondeo hacia abajo); si no, aplica `discountAmountFor`
/// sobre el subtotal de las líneas en alcance (con alcance vacío, es el
/// subtotal completo — 100% compatible con el comportamiento de antes).
/// `docs/promociones.md`.
double discountAmountForCart(Discount d, List<PromoLine> lines) {
  final scoped = _linesInScope(d, lines);
  if (d.type == '2x1') {
    return scoped.fold(0.0, (sum, l) => sum + (l.quantity ~/ 2) * l.unitPrice);
  }
  final scopedSubtotal =
      scoped.fold(0.0, (sum, l) => sum + l.unitPrice * l.quantity);
  return discountAmountFor(d, scopedSubtotal);
}

// ─── Combos (docs/combos.md) ──────────────────────────────────────────────

/// Reparte el precio fijo de un combo entre sus [components], proporcional al
/// precio normal de cada uno (× su cantidad) — la suma de los precios
/// devueltos (× cantidad) da exactamente [comboPrice]. Si la suma de precios
/// normales es 0, reparte en partes iguales (evita dividir entre cero).
/// Devuelve un precio POR UNIDAD, alineado 1:1 con [components].
/// `docs/combos.md`.
List<double> proratedComboPrices(
  double comboPrice,
  List<({double basePrice, int quantity})> components,
) {
  if (components.isEmpty) return const [];
  final totalRegular =
      components.fold(0.0, (s, c) => s + c.basePrice * c.quantity);
  if (totalRegular <= 0) {
    final equalShare = comboPrice / components.length;
    return List.filled(components.length, equalShare);
  }
  final factor = comboPrice / totalRegular;
  return [for (final c in components) c.basePrice * factor];
}

// ─── Fidelización (docs/fidelizacion.md) ──────────────────────────────────

/// `true` si el cliente ya junta lo suficiente para canjear, según la
/// mecánica activa (`loyaltyType`: 'sellos' | 'puntos' | 'ninguno').
/// `docs/fidelizacion.md`.
bool loyaltyRewardAvailable({
  required String loyaltyType,
  required int stamps,
  required int stampsRequired,
  required int points,
  required int pointsRequired,
}) {
  if (loyaltyType == 'sellos') {
    return stampsRequired > 0 && stamps >= stampsRequired;
  }
  if (loyaltyType == 'puntos') {
    return pointsRequired > 0 && points >= pointsRequired;
  }
  return false;
}

/// Precio del producto [product] en el carrito [lines] — lo que se hace
/// gratis al canjear. 0 si el carrito no tiene ese producto (no hay nada que
/// regalar todavía). `docs/fidelizacion.md`.
double loyaltyRewardAmount(List<PromoLine> lines, String product) {
  final p = product.trim().toLowerCase();
  final scoped =
      lines.where((l) => (l.productName ?? '').trim().toLowerCase() == p);
  if (scoped.isEmpty) return 0;
  return scoped.map((l) => l.unitPrice).reduce((a, b) => a > b ? a : b);
}

// ─── División de cuenta (docs/division-cuenta.md) ─────────────────────────

/// Reparte [total] en [parts] montos que SUMAN exactamente el total a los
/// centavos (el sobrante de redondeo va a las primeras partes). Trabaja en
/// centavos enteros para no arrastrar error de punto flotante.
/// `docs/division-cuenta.md`.
List<double> splitEvenly(double total, int parts) {
  if (parts <= 0) return const [];
  final totalCents = (total * 100).round();
  final baseCents = totalCents ~/ parts;
  final remainder = totalCents % parts;
  return [
    for (var i = 0; i < parts; i++) (baseCents + (i < remainder ? 1 : 0)) / 100,
  ];
}

/// Agrupa [cart] en "unidades" asignables para dividir por artículo: una
/// línea normal es su propia unidad; TODAS las líneas de un mismo combo se
/// agrupan en una sola unidad — un combo no se reparte entre personas (un
/// precio prorrateado por persona no corresponde a "lo que cada quien
/// pidió", feedback de sitio 2026-07-22). Cada elemento devuelto es la lista
/// de índices de [cart] que esa unidad agrupa, en el orden de aparición.
/// `docs/division-cuenta.md`.
List<List<int>> groupCartUnitsForSplit(List<CartItem> cart) {
  final units = <List<int>>[];
  final seenCombo = <String>{};
  for (var i = 0; i < cart.length; i++) {
    final comboId = cart[i].comboInstanceId;
    if (comboId == null) {
      units.add([i]);
    } else if (seenCombo.add(comboId)) {
      units.add([
        for (var j = 0; j < cart.length; j++)
          if (cart[j].comboInstanceId == comboId) j,
      ]);
    }
  }
  return units;
}
