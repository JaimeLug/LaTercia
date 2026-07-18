import 'package:flutter/material.dart';

/// Catálogo curado de íconos para categorías de producto — reemplaza el
/// input de emoji libre por una selección de Material Icons. Se guarda la
/// CLAVE (ej. "coffee") en `Categories.icon`, nunca el emoji ni el IconData.
const Map<String, IconData> categoryIconCatalog = {
  'coffee': Icons.coffee,
  'local_cafe': Icons.local_cafe,
  'emoji_food_beverage': Icons.emoji_food_beverage,
  'local_drink': Icons.local_drink,
  'icecream': Icons.icecream,
  'liquor': Icons.liquor,
  'local_bar': Icons.local_bar,
  'wine_bar': Icons.wine_bar,
  'sports_bar': Icons.sports_bar,
  'bubble_chart': Icons.bubble_chart,
  'water_drop': Icons.water_drop,
  'blender': Icons.blender,
  'cake': Icons.cake,
  'bakery_dining': Icons.bakery_dining,
  'cookie': Icons.cookie,
  'breakfast_dining': Icons.breakfast_dining,
  'brunch_dining': Icons.brunch_dining,
  'lunch_dining': Icons.lunch_dining,
  'dinner_dining': Icons.dinner_dining,
  'fastfood': Icons.fastfood,
  'local_pizza': Icons.local_pizza,
  'ramen_dining': Icons.ramen_dining,
  'set_meal': Icons.set_meal,
  'rice_bowl': Icons.rice_bowl,
  'tapas': Icons.tapas,
  'kebab_dining': Icons.kebab_dining,
  'egg_alt': Icons.egg_alt,
  'soup_kitchen': Icons.soup_kitchen,
  'restaurant': Icons.restaurant,
  'restaurant_menu': Icons.restaurant_menu,
  'local_dining': Icons.local_dining,
  'outdoor_grill': Icons.outdoor_grill,
  'local_fire_department': Icons.local_fire_department,
  'local_pharmacy': Icons.local_pharmacy,
  'local_shipping': Icons.local_shipping,
  'delivery_dining': Icons.delivery_dining,
  'auto_awesome': Icons.auto_awesome,
  'star': Icons.star,
  'favorite': Icons.favorite,
  'celebration': Icons.celebration,
  'grass': Icons.grass,
  'eco': Icons.eco,
  'nightlife': Icons.nightlife,
  'spa': Icons.spa,
  'inventory_2': Icons.inventory_2,
  'shopping_bag': Icons.shopping_bag,
};

/// [key] es lo guardado en `Categories.icon`. Si coincide con el catálogo se
/// dibuja el ícono correspondiente; si no (valores viejos tipo emoji, o algo
/// escrito a mano antes de esta pantalla), se cae a texto envuelto en
/// `FittedBox` para que NUNCA desborde la tarjeta, sin importar qué tan largo
/// sea el string.
Widget categoryIconWidget(String key, {double size = 24, Color? color}) {
  final data = categoryIconCatalog[key];
  if (data != null) return Icon(data, size: size, color: color);
  return FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(key, style: TextStyle(fontSize: size, color: color)),
  );
}
