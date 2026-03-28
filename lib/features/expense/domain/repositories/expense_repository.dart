import '../entities/expense.dart';

/// Abstract repository contract for expense data operations.
/// The data layer provides the concrete implementation.
abstract interface class ExpenseRepository {
  /// Returns all expenses sorted by date descending.
  Future<List<Expense>> getAllExpenses();

  /// Returns expenses for the given [month] and [year].
  Future<List<Expense>> getExpensesByMonth(int month, int year);

  /// Persists a new expense.
  Future<void> addExpense(Expense expense);

  /// Updates an existing expense identified by [expense.id].
  Future<void> updateExpense(Expense expense);

  /// Removes the expense with the given [id].
  Future<void> deleteExpense(String id);

  /// Removes all expenses. Useful for testing or full reset.
  Future<void> clearAll();
}
