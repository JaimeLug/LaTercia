import 'package:drift/drift.dart';
import '../database.dart';

part 'purchases_dao.g.dart';

class PurchaseItemDraft {
  final int ingredientId;
  final double quantity;
  final double unitCost;
  const PurchaseItemDraft({
    required this.ingredientId,
    required this.quantity,
    required this.unitCost,
  });
}

/// Cabecera de compra + nombre del proveedor (o null si no se asignó uno),
/// para pintar la lista sin una segunda consulta por fila.
typedef PurchaseWithSupplier = ({IngredientPurchase purchase, String? supplierName});

/// Línea de compra + nombre/unidad del insumo, para el detalle de una compra.
typedef PurchaseItemWithIngredient = ({
  IngredientPurchaseItem item,
  String ingredientName,
  String unit,
});

@DriftAccessor(
    tables: [IngredientPurchases, IngredientPurchaseItems, Ingredients, Suppliers, IngredientMovements])
class PurchasesDao extends DatabaseAccessor<AppDatabase>
    with _$PurchasesDaoMixin {
  PurchasesDao(super.db);

  /// Crea una compra (cabecera + N líneas) en una transacción: incrementa el
  /// stock de cada insumo, registra el movimiento y actualiza su último
  /// costo unitario conocido.
  Future<int> createPurchase({
    int? supplierId,
    required int employeeId,
    String? note,
    required List<PurchaseItemDraft> items,
  }) {
    return transaction(() async {
      final totalCost =
          items.fold<double>(0, (sum, i) => sum + i.quantity * i.unitCost);
      final purchaseId = await into(ingredientPurchases).insert(
        IngredientPurchasesCompanion.insert(
          supplierId: Value(supplierId),
          employeeId: employeeId,
          totalCost: Value(totalCost),
          note: Value(note),
        ),
      );

      for (final item in items) {
        await into(ingredientPurchaseItems).insert(
          IngredientPurchaseItemsCompanion.insert(
            purchaseId: purchaseId,
            ingredientId: item.ingredientId,
            quantity: item.quantity,
            unitCost: item.unitCost,
          ),
        );

        final ingredient = await (select(ingredients)
              ..where((i) => i.id.equals(item.ingredientId)))
            .getSingleOrNull();
        if (ingredient == null) continue;

        await (update(ingredients)..where((i) => i.id.equals(item.ingredientId)))
            .write(IngredientsCompanion(
          stockQuantity: Value(ingredient.stockQuantity + item.quantity),
          lastUnitCost: Value(item.unitCost),
        ));

        await into(ingredientMovements).insert(
          IngredientMovementsCompanion.insert(
            ingredientId: item.ingredientId,
            delta: item.quantity,
            reason: 'compra',
            purchaseId: Value(purchaseId),
          ),
        );
      }

      return purchaseId;
    });
  }

  Future<List<PurchaseWithSupplier>> getAllPurchases() async {
    final query = select(ingredientPurchases).join([
      leftOuterJoin(
          suppliers, suppliers.id.equalsExp(ingredientPurchases.supplierId)),
    ])
      ..orderBy([OrderingTerm.desc(ingredientPurchases.createdAt)]);
    final rows = await query.get();
    return rows
        .map((row) => (
              purchase: row.readTable(ingredientPurchases),
              supplierName: row.readTableOrNull(suppliers)?.name,
            ))
        .toList();
  }

  Future<List<PurchaseItemWithIngredient>> getPurchaseItems(
      int purchaseId) async {
    final query = select(ingredientPurchaseItems).join([
      innerJoin(ingredients,
          ingredients.id.equalsExp(ingredientPurchaseItems.ingredientId)),
    ])
      ..where(ingredientPurchaseItems.purchaseId.equals(purchaseId));
    final rows = await query.get();
    return rows
        .map((row) => (
              item: row.readTable(ingredientPurchaseItems),
              ingredientName: row.readTable(ingredients).name,
              unit: row.readTable(ingredients).unit,
            ))
        .toList();
  }
}
