import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/database/daos/purchases_dao.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<int> newIngredient(String name) => db.ingredientsDao.insertIngredient(
      IngredientsCompanion.insert(name: name, unit: 'g'));

  test('createPurchase incrementa stock, registra movimiento y actualiza '
      'el último costo unitario', () async {
    final cafeId = await newIngredient('Café');
    final lecheId = await newIngredient('Leche');
    final supplierId = await db.suppliersDao.insertSupplier(
      SuppliersCompanion.insert(name: 'Distribuidora Central'),
    );

    final purchaseId = await db.purchasesDao.createPurchase(
      supplierId: supplierId,
      employeeId: 1,
      note: 'Reposición semanal',
      items: [
        PurchaseItemDraft(ingredientId: cafeId, quantity: 5000, unitCost: 0.4),
        PurchaseItemDraft(ingredientId: lecheId, quantity: 2000, unitCost: 0.02),
      ],
    );

    final cafe =
        (await db.ingredientsDao.getAllIngredients()).firstWhere((i) => i.id == cafeId);
    final leche =
        (await db.ingredientsDao.getAllIngredients()).firstWhere((i) => i.id == lecheId);
    expect(cafe.stockQuantity, 5000);
    expect(cafe.lastUnitCost, 0.4);
    expect(leche.stockQuantity, 2000);

    final movsCafe = await db.ingredientsDao.getMovementsForIngredient(cafeId);
    expect(movsCafe, hasLength(1));
    expect(movsCafe.first.reason, 'compra');
    expect(movsCafe.first.delta, 5000);
    expect(movsCafe.first.purchaseId, purchaseId);

    final purchases = await db.purchasesDao.getAllPurchases();
    expect(purchases, hasLength(1));
    expect(purchases.first.supplierName, 'Distribuidora Central');
    expect(purchases.first.purchase.totalCost, 5000 * 0.4 + 2000 * 0.02);

    final items = await db.purchasesDao.getPurchaseItems(purchaseId);
    expect(items, hasLength(2));
    expect(items.map((i) => i.ingredientName), containsAll(['Café', 'Leche']));
  });

  test('compra sin proveedor asignado queda con supplierName null', () async {
    final cafeId = await newIngredient('Café');
    final purchaseId = await db.purchasesDao.createPurchase(
      employeeId: 1,
      items: [PurchaseItemDraft(ingredientId: cafeId, quantity: 100, unitCost: 0.5)],
    );

    final purchases = await db.purchasesDao.getAllPurchases();
    final purchase = purchases.firstWhere((p) => p.purchase.id == purchaseId);
    expect(purchase.supplierName, isNull);
  });
}
