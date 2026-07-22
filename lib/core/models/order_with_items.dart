import '../database/database.dart';

class OrderWithItems {
  final Order order;
  final List<OrderItem> items;

  const OrderWithItems({required this.order, required this.items});
}

class CartItem {
  final Product product;
  final List<Modifier> modifiers;
  // FASE 8 — ids de [modifiers] que el cajero marcó como "incluidos" (gratis)
  // para esta línea — ej. el topping que ya viene incluido en el precio del
  // producto. No hay validación de cuántos le tocan a cada producto: el
  // cajero decide, el sistema solo deja de cobrar el priceDelta de esos ids.
  final Set<int> includedModifierIds;
  int quantity;
  String? note;
  // Combos (docs/combos.md): las líneas de una misma compra de combo
  // comparten [comboInstanceId] (para agruparlas en el carrito/ticket y
  // quitarlas juntas); [comboName] es solo para mostrar. Null = no es combo.
  final String? comboInstanceId;
  final String? comboName;

  CartItem({
    required this.product,
    this.modifiers = const [],
    this.includedModifierIds = const {},
    this.quantity = 1,
    this.note,
    this.comboInstanceId,
    this.comboName,
  });

  double get unitPrice =>
      product.price +
      modifiers
          .where((m) => !includedModifierIds.contains(m.id))
          .fold(0.0, (sum, m) => sum + m.priceDelta);

  double get lineTotal => unitPrice * quantity;
}
