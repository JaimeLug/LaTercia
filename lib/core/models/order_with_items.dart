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

  CartItem({
    required this.product,
    this.modifiers = const [],
    this.includedModifierIds = const {},
    this.quantity = 1,
    this.note,
  });

  double get unitPrice => product.price +
      modifiers
          .where((m) => !includedModifierIds.contains(m.id))
          .fold(0.0, (sum, m) => sum + m.priceDelta);

  double get lineTotal => unitPrice * quantity;
}
