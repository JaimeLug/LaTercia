import 'package:drift/drift.dart';
import '../database.dart';

part 'reports_dao.g.dart';

@DriftAccessor(tables: [Orders, OrderItems, Payments, Employees])
class ReportsDao extends DatabaseAccessor<AppDatabase> with _$ReportsDaoMixin {
  ReportsDao(super.db);

  Future<double> getTotalRevenueForRange(DateTime from, DateTime to) async {
    final paidOrders = await (select(orders)
          ..where((o) =>
              o.paymentStatus.equals('pagado') &
              o.createdAt.isBetweenValues(from, to)))
        .get();
    return paidOrders.fold<double>(0.0, (sum, o) => sum + o.total);
  }

  Future<int> getOrderCountForRange(DateTime from, DateTime to) async {
    final result = await (select(orders)
          ..where((o) =>
              o.paymentStatus.equals('pagado') &
              o.createdAt.isBetweenValues(from, to)))
        .get();
    return result.length;
  }

  Future<Map<String, double>> getDailyRevenueLast7Days() async {
    final result = <String, double>{};
    for (int i = 6; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i));
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));
      final rev = await getTotalRevenueForRange(start, end);
      final label = '${day.day}/${day.month}';
      result[label] = rev;
    }
    return result;
  }

  Future<Map<String, int>> getTopProductsToday() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    // Single JOIN query instead of one order-items query per paid order.
    final query = select(orderItems).join([
      innerJoin(orders, orders.id.equalsExp(orderItems.orderId)),
    ])
      ..where(orders.paymentStatus.equals('pagado') &
          orders.createdAt.isBetweenValues(start, end));

    final rows = await query.get();

    final productQty = <String, int>{};
    for (final row in rows) {
      final item = row.readTable(orderItems);
      productQty[item.productName] =
          (productQty[item.productName] ?? 0) + item.quantity;
    }
    final sorted = productQty.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(20));
  }

  Future<Map<String, double>> getSalesByCategory(
      DateTime from, DateTime to) async {
    // This is simplified — in a full impl you'd join with products/categories
    final query = select(orderItems).join([
      innerJoin(orders, orders.id.equalsExp(orderItems.orderId)),
    ])
      ..where(orders.paymentStatus.equals('pagado') &
          orders.createdAt.isBetweenValues(from, to));

    final rows = await query.get();

    final result = <String, double>{};
    for (final row in rows) {
      final item = row.readTable(orderItems);
      result['Otros'] = (result['Otros'] ?? 0) + item.unitPrice * item.quantity;
    }
    return result;
  }

  Future<Map<String, double>> getSalesByEmployee(
      DateTime from, DateTime to) async {
    final paidOrders = await (select(orders)
          ..where((o) =>
              o.paymentStatus.equals('pagado') &
              o.createdAt.isBetweenValues(from, to)))
        .get();

    final result = <String, double>{};
    final allEmployees = await select(employees).get();
    final empMap = {for (final e in allEmployees) e.id: e.name};

    for (final order in paidOrders) {
      final name = empMap[order.employeeId] ?? 'Desconocido';
      result[name] = (result[name] ?? 0) + order.total;
    }
    return result;
  }

  Future<Map<String, double>> getSalesByPaymentMethod(
      DateTime from, DateTime to) async {
    final allPayments = await (select(payments)
          ..where((p) => p.createdAt.isBetweenValues(from, to)))
        .get();
    final result = <String, double>{};
    for (final p in allPayments) {
      result[p.method] = (result[p.method] ?? 0) + p.amountTendered;
    }
    return result;
  }
}
