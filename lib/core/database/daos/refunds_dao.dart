import 'package:drift/drift.dart';
import '../database.dart';

part 'refunds_dao.g.dart';

@DriftAccessor(tables: [Refunds])
class RefundsDao extends DatabaseAccessor<AppDatabase> with _$RefundsDaoMixin {
  RefundsDao(super.db);

  Future<int> insertRefund(RefundsCompanion refund) =>
      into(refunds).insert(refund);

  Future<List<Refund>> getRefundsForOrder(int orderId) =>
      (select(refunds)..where((r) => r.orderId.equals(orderId))).get();

  Future<List<Refund>> getRefundsForShift(int shiftId) =>
      (select(refunds)..where((r) => r.shiftId.equals(shiftId))).get();

  Future<List<Refund>> getRefundsByDateRange(DateTime from, DateTime to) =>
      (select(refunds)..where((r) => r.ts.isBetweenValues(from, to))).get();
}
