import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/models/order_with_items.dart';

/// FASE 8 — modificador "incluido" (gratis) por línea de carrito: el cajero
/// marca manualmente cuál va incluido; su `priceDelta` no debe cobrarse en
/// esa línea, pero si el mismo modificador se agrega en otra línea sin
/// marcarlo, ahí sí debe cobrarse (el flag es por-CartItem, no por-Modifier).
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<Product> product(double price) async {
    final cats = await db.categoriesDao.getAllCategories();
    final id = await db.productsDao.insertProduct(
      ProductsCompanion.insert(name: 'Waffle', price: price, categoryId: cats.first.id),
    );
    return (await db.productsDao.getAllProducts()).firstWhere((p) => p.id == id);
  }

  Future<Modifier> modifier(String name, double priceDelta) async {
    final id = await db.modifiersDao.insertModifier(
      ModifiersCompanion.insert(name: name, priceDelta: Value(priceDelta)),
    );
    return (await db.modifiersDao.getAllModifiers()).firstWhere((m) => m.id == id);
  }

  test('sin modificadores incluidos, unitPrice suma todos los priceDelta',
      () async {
    final p = await product(60);
    final nutella = await modifier('Nutella', 10);
    final item = CartItem(product: p, modifiers: [nutella]);

    expect(item.unitPrice, 70);
  });

  test('un modificador marcado incluido no se cobra', () async {
    final p = await product(60);
    final nutella = await modifier('Nutella', 10);
    final item = CartItem(
      product: p,
      modifiers: [nutella],
      includedModifierIds: {nutella.id},
    );

    expect(item.unitPrice, 60, reason: 'el topping incluido es gratis');
  });

  test('con varios modificadores, solo se salta el marcado incluido',
      () async {
    final p = await product(60);
    final nutella = await modifier('Nutella', 10);
    final lechera = await modifier('Lechera', 10);
    final item = CartItem(
      product: p,
      modifiers: [nutella, lechera],
      includedModifierIds: {nutella.id},
    );

    expect(item.unitPrice, 70, reason: '60 base + 10 de Lechera (extra)');
  });

  test('el mismo modificador se cobra en una línea distinta sin marcar',
      () async {
    final p = await product(60);
    final nutella = await modifier('Nutella', 10);
    final incluida = CartItem(
      product: p,
      modifiers: [nutella],
      includedModifierIds: {nutella.id},
    );
    final cobrada = CartItem(product: p, modifiers: [nutella]);

    expect(incluida.unitPrice, 60);
    expect(cobrada.unitPrice, 70);
  });

  test('lineTotal multiplica el unitPrice ya sin el incluido', () async {
    final p = await product(60);
    final nutella = await modifier('Nutella', 10);
    final item = CartItem(
      product: p,
      modifiers: [nutella],
      includedModifierIds: {nutella.id},
      quantity: 3,
    );

    expect(item.lineTotal, 180);
  });
}
