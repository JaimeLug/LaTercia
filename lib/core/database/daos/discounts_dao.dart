import 'package:drift/drift.dart';
import '../database.dart';

part 'discounts_dao.g.dart';

@DriftAccessor(tables: [Discounts])
class DiscountsDao extends DatabaseAccessor<AppDatabase>
    with _$DiscountsDaoMixin {
  DiscountsDao(super.db);

  Future<List<Discount>> getAllDiscounts() => select(discounts).get();

  Stream<List<Discount>> watchAllDiscounts() => select(discounts).watch();

  Future<List<Discount>> getActiveDiscounts() =>
      (select(discounts)..where((d) => d.active.equals(true))).get();

  Future<int> insertDiscount(DiscountsCompanion discount) =>
      into(discounts).insert(discount);

  Future<bool> updateDiscount(DiscountsCompanion discount) =>
      update(discounts).replace(discount);

  Future<void> toggleActive(int id, bool active) =>
      (update(discounts)..where((d) => d.id.equals(id)))
          .write(DiscountsCompanion(active: Value(active)));

  Future<int> deleteDiscount(int id) =>
      (delete(discounts)..where((d) => d.id.equals(id))).go();
}
