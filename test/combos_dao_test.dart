import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';

/// CombosDao: CRUD de combos y resolución de sus componentes reales para el
/// carrito. Ver docs/combos.md.
void main() {
  late AppDatabase db;
  late int catId;
  late int cafeId;
  late int panId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    catId = await db.categoriesDao.insertCategory(
        CategoriesCompanion.insert(name: 'c', color: '#000', icon: 'i'));
    cafeId = await db.productsDao.insertProduct(ProductsCompanion.insert(
        name: 'Café Americano', price: 35, categoryId: catId));
    panId = await db.productsDao.insertProduct(ProductsCompanion.insert(
        name: 'Pan de elote', price: 20, categoryId: catId));
  });
  tearDown(() => db.close());

  test('insertCombo + replaceComboItems arma el combo con sus componentes',
      () async {
    final comboId = await db.combosDao
        .insertCombo(CombosCompanion.insert(name: 'Desayuno', price: 45));
    await db.combosDao.replaceComboItems(comboId, [
      (productId: cafeId, quantity: 1),
      (productId: panId, quantity: 1),
    ]);

    final components = await db.combosDao.getComboComponents(comboId);
    expect(components, hasLength(2));
    expect(components.map((c) => c.product.name),
        containsAll(['Café Americano', 'Pan de elote']));
    expect(components.every((c) => c.quantity == 1), isTrue);
  });

  test('replaceComboItems reemplaza TODO — no acumula componentes viejos',
      () async {
    final comboId = await db.combosDao
        .insertCombo(CombosCompanion.insert(name: 'Desayuno', price: 45));
    await db.combosDao
        .replaceComboItems(comboId, [(productId: cafeId, quantity: 1)]);
    // Editar el combo: ahora solo pan, cantidad 2.
    await db.combosDao
        .replaceComboItems(comboId, [(productId: panId, quantity: 2)]);

    final components = await db.combosDao.getComboComponents(comboId);
    expect(components, hasLength(1));
    expect(components.single.product.name, 'Pan de elote');
    expect(components.single.quantity, 2);
  });

  test('getActiveCombos excluye los inactivos', () async {
    await db.combosDao
        .insertCombo(CombosCompanion.insert(name: 'Activo', price: 10));
    final inactivoId = await db.combosDao
        .insertCombo(CombosCompanion.insert(name: 'Inactivo', price: 10));
    await db.combosDao.toggleActive(inactivoId, false);

    final active = await db.combosDao.getActiveCombos();
    expect(active.map((c) => c.name), ['Activo']);
  });

  test('deleteCombo borra el combo y sus componentes (sin violar la FK)',
      () async {
    final comboId = await db.combosDao
        .insertCombo(CombosCompanion.insert(name: 'Desayuno', price: 45));
    await db.combosDao
        .replaceComboItems(comboId, [(productId: cafeId, quantity: 1)]);

    await db.combosDao.deleteCombo(comboId);

    expect(await db.combosDao.getAllCombos(), isEmpty);
    expect(await db.combosDao.getComboItems(comboId), isEmpty);
  });
}
