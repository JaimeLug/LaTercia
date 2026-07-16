import '../database/database.dart';

class OrderWithItems {
  final Order order;
  final List<OrderItem> items;

  const OrderWithItems({required this.order, required this.items});
}

class CartItem {
  final Product product;
  final List<Modifier> modifiers;
  int quantity;
  String? note;

  CartItem({
    required this.product,
    this.modifiers = const [],
    this.quantity = 1,
    this.note,
  });

  double get unitPrice =>
      product.price + modifiers.fold(0.0, (sum, m) => sum + m.priceDelta);

  double get lineTotal => unitPrice * quantity;
}
