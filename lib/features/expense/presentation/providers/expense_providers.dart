import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../data/datasources/expense_local_datasource.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/repositories/expense_repository.dart';

// ─────────────────────────────────────────────
// Infrastructure Providers
// ─────────────────────────────────────────────

final expenseLocalDatasourceProvider = Provider<ExpenseLocalDatasource>(
  (_) => ExpenseLocalDatasource(),
);

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepositoryImpl(
    ref.watch(expenseLocalDatasourceProvider),
  ),
);

// ─────────────────────────────────────────────
// Selected Month/Year State
// ─────────────────────────────────────────────

class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void previousMonth() {
    state = DateTime(state.year, state.month - 1);
  }

  void nextMonth() {
    final next = DateTime(state.year, state.month + 1);
    if (next.isBefore(DateTime.now()) ||
        AppDateUtils.isSameMonth(next, DateTime.now())) {
      state = next;
    }
  }

  void setMonth(DateTime date) => state = date;
}

final selectedMonthProvider =
    NotifierProvider<SelectedMonthNotifier, DateTime>(
  SelectedMonthNotifier.new,
);

// ─────────────────────────────────────────────
// Expense List State
// ─────────────────────────────────────────────

class ExpenseNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() =>
      ref.watch(expenseRepositoryProvider).getAllExpenses();

  /// Refreshes the expense list from Hive.
  Future<void> refresh() => update((_) =>
      ref.read(expenseRepositoryProvider).getAllExpenses());

  Future<void> addExpense({
    required double amount,
    required ExpenseCategory category,
    required DateTime date,
    String? note,
  }) async {
    final expense = Expense(
      id: const Uuid().v4(),
      amount: amount,
      category: category,
      date: date,
      note: note?.trim().isEmpty ?? true ? null : note?.trim(),
    );
    await ref.read(expenseRepositoryProvider).addExpense(expense);
    await refresh();
  }

  Future<void> updateExpense(Expense expense) async {
    await ref.read(expenseRepositoryProvider).updateExpense(expense);
    await refresh();
  }

  Future<void> deleteExpense(String id) async {
    await ref.read(expenseRepositoryProvider).deleteExpense(id);
    await refresh();
  }
}

final expensesProvider =
    AsyncNotifierProvider<ExpenseNotifier, List<Expense>>(
  ExpenseNotifier.new,
);

// ─────────────────────────────────────────────
// Derived / Computed Providers
// ─────────────────────────────────────────────

/// Expenses filtered to the currently selected month.
final filteredExpensesProvider = Provider<AsyncValue<List<Expense>>>((ref) {
  final expensesAsync = ref.watch(expensesProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  return expensesAsync.whenData((expenses) => expenses
      .where((e) =>
          e.date.month == selectedMonth.month &&
          e.date.year == selectedMonth.year)
      .toList());
});

/// Total amount spent in the selected month.
final monthlyTotalProvider = Provider<double>((ref) {
  final filtered = ref.watch(filteredExpensesProvider);
  return filtered.maybeWhen(
    data: (expenses) =>
        expenses.fold(0.0, (sum, e) => sum + e.amount),
    orElse: () => 0.0,
  );
});

/// Category-wise totals map for the selected month.
final categoryBreakdownProvider =
    Provider<Map<ExpenseCategory, double>>((ref) {
  final filtered = ref.watch(filteredExpensesProvider);
  return filtered.maybeWhen(
    data: (expenses) {
      final map = <ExpenseCategory, double>{};
      for (final e in expenses) {
        map[e.category] = (map[e.category] ?? 0.0) + e.amount;
      }
      return map;
    },
    orElse: () => {},
  );
});

/// Highest spending category in the selected month.
final highestCategoryProvider = Provider<ExpenseCategory?>((ref) {
  final breakdown = ref.watch(categoryBreakdownProvider);
  if (breakdown.isEmpty) return null;
  return breakdown.entries
      .reduce((a, b) => a.value >= b.value ? a : b)
      .key;
});

/// Daily spending totals for the selected month (used in bar chart).
/// Returns a list of 28-31 entries (one per day).
final dailyTrendProvider = Provider<List<double>>((ref) {
  final filtered = ref.watch(filteredExpensesProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  final daysInMonth =
      DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

  return filtered.maybeWhen(
    data: (expenses) {
      final dailyTotals = List<double>.filled(daysInMonth, 0.0);
      for (final e in expenses) {
        dailyTotals[e.date.day - 1] += e.amount;
      }
      return dailyTotals;
    },
    orElse: () => List<double>.filled(daysInMonth, 0.0),
  );
});

/// Last N recent expenses across all months.
final recentExpensesProvider = Provider<List<Expense>>((ref) {
  final expensesAsync = ref.watch(expensesProvider);
  return expensesAsync.maybeWhen(
    data: (expenses) => expenses.take(5).toList(),
    orElse: () => [],
  );
});

// ─────────────────────────────────────────────
// Search
// ─────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = Provider<List<Expense>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  if (query.isEmpty) return [];
  final expensesAsync = ref.watch(expensesProvider);
  return expensesAsync.maybeWhen(
    data: (expenses) => expenses.where((e) {
      final noteMatch = e.note?.toLowerCase().contains(query) ?? false;
      final categoryMatch = e.category.label.toLowerCase().contains(query);
      return noteMatch || categoryMatch;
    }).toList(),
    orElse: () => [],
  );
});

// ─────────────────────────────────────────────
// Budget
// ─────────────────────────────────────────────

final budgetLimitProvider = StateProvider<double>((ref) => 30000.0);

/// Percentage of budget used this month (0.0 – 1.0+)
final budgetUsageProvider = Provider<double>((ref) {
  final total = ref.watch(monthlyTotalProvider);
  final budget = ref.watch(budgetLimitProvider);
  if (budget <= 0) return 0;
  return total / budget;
});
