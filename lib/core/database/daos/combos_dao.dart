import 'package:drift/drift.dart';
import '../database.dart';

part 'combos_dao.g.dart';

/// Un componente de combo ya resuelto con su producto real (para armar el
/// carrito). docs/combos.md.
typedef ComboComponent = ({Product product, int quantity});

@DriftAccessor(tables: [Combos, ComboItems, Products])
class CombosDao extends DatabaseAccessor<AppDatabase> with _$CombosDaoMixin {
  CombosDao(super.db);

  Future<List<Combo>> getAllCombos() => select(combos).get();

  Stream<List<Combo>> watchAllCombos() => select(combos).watch();

  Future<List<Combo>> getActiveCombos() =>
      (select(combos)..where((c) => c.active.equals(true))).get();

  Future<int> insertCombo(CombosCompanion combo) => into(combos).insert(combo);

  Future<bool> updateCombo(CombosCompanion combo) =>
      update(combos).replace(combo);

  Future<void> toggleActive(int id, bool active) =>
      (update(combos)..where((c) => c.id.equals(id)))
          .write(CombosCompanion(active: Value(active)));

  Future<void> deleteCombo(int id) async {
    // Primero los componentes (FK), luego el combo. docs/combos.md.
    await (delete(comboItems)..where((ci) => ci.comboId.equals(id))).go();
    await (delete(combos)..where((c) => c.id.equals(id))).go();
  }

  /// Componentes crudos de [comboId] (sin resolver producto). Para la
  /// pantalla de edición del combo.
  Future<List<ComboItem>> getComboItems(int comboId) =>
      (select(comboItems)..where((ci) => ci.comboId.equals(comboId))).get();

  /// Reemplaza TODOS los componentes de [comboId] por [items] (borra e
  /// inserta) — más simple y seguro que diffear altas/bajas al guardar el
  /// formulario. docs/combos.md.
  Future<void> replaceComboItems(
      int comboId, List<({int productId, int quantity})> items) async {
    await (delete(comboItems)..where((ci) => ci.comboId.equals(comboId))).go();
    for (final it in items) {
      await into(comboItems).insert(ComboItemsCompanion.insert(
        comboId: comboId,
        productId: it.productId,
        quantity: Value(it.quantity),
      ));
    }
  }

  /// Componentes de [comboId] con su [Product] real ya resuelto — lo que
  /// necesita el POS para armar el carrito. Ignora componentes cuyo producto
  /// se haya borrado. docs/combos.md.
  Future<List<ComboComponent>> getComboComponents(int comboId) async {
    final query = select(comboItems).join([
      innerJoin(products, products.id.equalsExp(comboItems.productId)),
    ])
      ..where(comboItems.comboId.equals(comboId));
    final rows = await query.get();
    return [
      for (final row in rows)
        (
          product: row.readTable(products),
          quantity: row.readTable(comboItems).quantity,
        ),
    ];
  }
}
