import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_datasource.dart';

/// Concrete implementation of [ExpenseRepository] using local Hive storage.
class ExpenseRepositoryImpl implements ExpenseRepository {
  const ExpenseRepositoryImpl(this._datasource);

  final ExpenseLocalDatasource _datasource;

  @override
  Future<List<Expense>> getAllExpenses() async {
    final models = _datasource.getAll();
    final expenses = models.map((m) => m.toEntity()).toList();
    // Sort by date descending (newest first)
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  @override
  Future<List<Expense>> getExpensesByMonth(int month, int year) async {
    final all = await getAllExpenses();
    return all
        .where((e) => e.date.month == month && e.date.year == year)
        .toList();
  }

  @override
  Future<void> addExpense(Expense expense) =>
      _datasource.saveEntity(expense);

  @override
  Future<void> updateExpense(Expense expense) =>
      _datasource.saveEntity(expense);

  @override
  Future<void> deleteExpense(String id) => _datasource.delete(id);

  @override
  Future<void> clearAll() => _datasource.clear();
}
