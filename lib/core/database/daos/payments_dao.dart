import 'package:drift/drift.dart';
import '../database.dart';

part 'payments_dao.g.dart';

@DriftAccessor(tables: [Payments])
class PaymentsDao extends DatabaseAccessor<AppDatabase>
    with _$PaymentsDaoMixin {
  PaymentsDao(super.db);

  Future<int> insertPayment(PaymentsCompanion payment) =>
      into(payments).insert(payment);

  Future<List<Payment>> getPaymentsForOrder(int orderId) =>
      (select(payments)..where((p) => p.orderId.equals(orderId))).get();

  Future<List<Payment>> getPaymentsByDateRange(
          DateTime from, DateTime to) =>
      (select(payments)
            ..where((p) => p.createdAt.isBetweenValues(from, to)))
          .get();

  Future<List<Payment>> getPaymentsForShift(int shiftId) =>
      (select(payments)..where((p) => p.shiftId.equals(shiftId))).get();
}
