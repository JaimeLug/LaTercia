import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/models/order_with_items.dart';
import 'package:latercia/core/utils/pricing.dart';

/// groupCartUnitsForSplit — división de cuenta por artículo: un combo no se
/// reparte entre personas, sus líneas siempre viajan juntas como UNA unidad
/// asignable (feedback de sitio 2026-07-22: prorratear un combo entre dos
/// personas daba montos confusos que no correspondían a "lo que cada quien
/// pidió"). Ver docs/division-cuenta.md.
void main() {
  late AppDatabase db;
  late Product cafe;
  late Product pan;
  late Product frappe;
  late Product smoothie;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final catId = await db.categoriesDao.insertCategory(
        CategoriesCompanion.insert(name: 'c', color: '#000', icon: 'i'));
    Future<Product> product(String name, double price) async {
      final id = await db.productsDao.insertProduct(ProductsCompanion.insert(
          name: name, price: price, categoryId: catId));
      return (await db.productsDao.getProductById(id))!;
    }

    cafe = await product('Café', 35);
    pan = await product('Pan', 20);
    frappe = await product('Frappé de Café', 60);
    smoothie = await product('Smoothie de Fresa', 58);
  });
  tearDown(() => db.close());

  test('líneas normales (sin combo): cada una es su propia unidad', () {
    final cart = [
      CartItem(product: cafe, quantity: 1),
      CartItem(product: pan, quantity: 1),
    ];
    expect(groupCartUnitsForSplit(cart), [
      [0],
      [1],
    ]);
  });

  test('un combo de 2 componentes se agrupa en UNA sola unidad', () {
    final cart = [
      CartItem(
          product: frappe,
          quantity: 1,
          comboInstanceId: 'combo-1',
          comboName: 'Combo 1'),
      CartItem(
          product: smoothie,
          quantity: 1,
          comboInstanceId: 'combo-1',
          comboName: 'Combo 1'),
    ];
    expect(groupCartUnitsForSplit(cart), [
      [0, 1],
    ]);
  });

  test(
      'combo + línea normal mezclados: el combo se agrupa, lo demás queda '
      'suelto, y se conserva el orden de aparición', () {
    final cart = [
      CartItem(product: cafe, quantity: 1), // 0: suelto
      CartItem(
          product: frappe,
          quantity: 1,
          comboInstanceId: 'combo-1',
          comboName: 'Combo 1'), // 1: combo
      CartItem(product: pan, quantity: 1), // 2: suelto
      CartItem(
          product: smoothie,
          quantity: 1,
          comboInstanceId: 'combo-1',
          comboName: 'Combo 1'), // 3: combo (mismo id que el 1)
    ];
    expect(groupCartUnitsForSplit(cart), [
      [0],
      [1, 3],
      [2],
    ]);
  });

  test('dos combos distintos en el carrito: cada uno es su propia unidad', () {
    final cart = [
      CartItem(
          product: frappe,
          quantity: 1,
          comboInstanceId: 'combo-1',
          comboName: 'Combo 1'),
      CartItem(
          product: cafe,
          quantity: 1,
          comboInstanceId: 'combo-2',
          comboName: 'Combo 2'),
      CartItem(
          product: smoothie,
          quantity: 1,
          comboInstanceId: 'combo-1',
          comboName: 'Combo 1'),
      CartItem(
          product: pan,
          quantity: 1,
          comboInstanceId: 'combo-2',
          comboName: 'Combo 2'),
    ];
    expect(groupCartUnitsForSplit(cart), [
      [0, 2],
      [1, 3],
    ]);
  });

  test('carrito vacío: sin unidades', () {
    expect(groupCartUnitsForSplit(const []), isEmpty);
  });
}
