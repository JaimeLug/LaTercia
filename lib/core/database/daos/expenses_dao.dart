import 'package:drift/drift.dart';
import '../database.dart';

part 'expenses_dao.g.dart';

@DriftAccessor(tables: [Expenses])
class ExpensesDao extends DatabaseAccessor<AppDatabase>
    with _$ExpensesDaoMixin {
  ExpensesDao(super.db);

  Future<List<Expense>> getAllExpenses() =>
      (select(expenses)..orderBy([(e) => OrderingTerm.desc(e.date)])).get();

  Future<List<Expense>> getExpensesByDateRange(DateTime from, DateTime to) =>
      (select(expenses)
            ..where((e) => e.date.isBetweenValues(from, to))
            ..orderBy([(e) => OrderingTerm.desc(e.date)]))
          .get();

  Future<double> getMonthlyTotal(int year, int month) async {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    final list = await getExpensesByDateRange(start, end);
    return list.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  Future<int> insertExpense(ExpensesCompanion expense) =>
      into(expenses).insert(expense);

  Future<int> deleteExpense(int id) =>
      (delete(expenses)..where((e) => e.id.equals(id))).go();
}
