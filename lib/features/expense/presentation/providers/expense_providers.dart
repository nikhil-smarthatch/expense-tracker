import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../data/datasources/expense_local_datasource.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../../loan/presentation/providers/loan_providers.dart';

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
    bool isIncome = false,
    String? receiptPath,
    bool isCreditCard = false,
  }) async {
    final expense = Expense(
      id: const Uuid().v4(),
      amount: amount,
      category: category,
      date: date,
      note: note?.trim().isEmpty ?? true ? null : note?.trim(),
      isIncome: isIncome,
      receiptPath: receiptPath,
      isCreditCard: isCreditCard,
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

  /// Settles all provided unmatched credit card spends into one master bill
  Future<void> settleCreditCardBill(List<Expense> spends, DateTime date) async {
    double total = 0.0;
    for (final e in spends) {
      if (!e.isCreditCardSettled) {
        total += e.amount;
        final updated = e.copyWith(isCreditCardSettled: true);
        await ref.read(expenseRepositoryProvider).updateExpense(updated);
      }
    }
    if (total > 0) {
      final billExpense = Expense(
        id: const Uuid().v4(),
        amount: total,
        category: ExpenseCategory.bills,
        date: date,
        note: 'Credit Card Bill Payment',
        isIncome: false,
        isCreditCard: false,
      );
      await ref.read(expenseRepositoryProvider).addExpense(billExpense);
    }
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

/// Expenses filtered to the currently selected month (excludes Credit Card spends).
final filteredExpensesProvider = Provider<AsyncValue<List<Expense>>>((ref) {
  final expensesAsync = ref.watch(expensesProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  return expensesAsync.whenData((expenses) => expenses
      .where((e) =>
          !e.isCreditCard &&
          e.date.month == selectedMonth.month &&
          e.date.year == selectedMonth.year)
      .toList());
});

/// Total income in the selected month.
final monthlyIncomeProvider = Provider<double>((ref) {
  final filtered = ref.watch(filteredExpensesProvider);
  return filtered.maybeWhen(
    data: (transactions) =>
        transactions.where((e) => e.isIncome).fold(0.0, (sum, e) => sum + e.amount),
    orElse: () => 0.0,
  );
});

/// Total expense in the selected month.
final monthlyExpenseProvider = Provider<double>((ref) {
  final filtered = ref.watch(filteredExpensesProvider);
  return filtered.maybeWhen(
    data: (transactions) =>
        transactions.where((e) => !e.isIncome).fold(0.0, (sum, e) => sum + e.amount),
    orElse: () => 0.0,
  );
});

/// Net balance (Income + Borrowed - Expense - Lent).
final netBalanceProvider = Provider<double>((ref) {
  final income = ref.watch(monthlyIncomeProvider);
  final expense = ref.watch(monthlyExpenseProvider);
  final borrowed = ref.watch(totalBorrowedProvider);
  final lent = ref.watch(totalLentProvider);
  return income + borrowed - expense - lent;
});

/// Category-wise totals map for the selected month (Expenses only).
final categoryBreakdownProvider =
    Provider<Map<ExpenseCategory, double>>((ref) {
  final filtered = ref.watch(filteredExpensesProvider);
  return filtered.maybeWhen(
    data: (transactions) {
      final map = <ExpenseCategory, double>{};
      for (final e in transactions.where((t) => !t.isIncome)) {
        map[e.category] = (map[e.category] ?? 0.0) + e.amount;
      }
      return map;
    },
    orElse: () => {},
  );
});

/// Highest spending category in the selected month (Expenses only).
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
    data: (transactions) {
      final dailyTotals = List<double>.filled(daysInMonth, 0.0);
      for (final e in transactions.where((t) => !t.isIncome)) {
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
    data: (expenses) => expenses.where((e) => !e.isCreditCard).take(5).toList(),
    orElse: () => [],
  );
});

// ─────────────────────────────────────────────
// Credit Card Providers
// ─────────────────────────────────────────────

/// All unpaid credit card spends across all time
final unpaidCreditCardSpendsProvider = Provider<List<Expense>>((ref) {
  final expensesAsync = ref.watch(expensesProvider);
  return expensesAsync.maybeWhen(
    data: (expenses) =>
        expenses.where((e) => e.isCreditCard && !e.isCreditCardSettled).toList(),
    orElse: () => [],
  );
});

/// Total outstanding credit card bill
final totalUnpaidCreditCardProvider = Provider<double>((ref) {
  final unpaid = ref.watch(unpaidCreditCardSpendsProvider);
  return unpaid.fold(0.0, (sum, e) => sum + e.amount);
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

class BudgetNotifier extends Notifier<double> {
  late Box<double> _box;
  late String _monthKey;

  @override
  double build() {
    _box = Hive.box<double>(AppConstants.hiveBudgetBox);
    final selectedMonth = ref.watch(selectedMonthProvider);
    // Use formatMonthYear as a unique string key per month (e.g., "March 2026")
    _monthKey = AppDateUtils.formatMonthYear(selectedMonth);

    return _box.get(_monthKey, defaultValue: AppConstants.defaultBudgetLimit) ??
        AppConstants.defaultBudgetLimit;
  }

  void setBudget(double amount) {
    _box.put(_monthKey, amount);
    state = amount;
  }
}

final budgetLimitProvider = NotifierProvider<BudgetNotifier, double>(BudgetNotifier.new);

/// Percentage of budget used this month (0.0 – 1.0+)
final budgetUsageProvider = Provider<double>((ref) {
  final expense = ref.watch(monthlyExpenseProvider);
  final budget = ref.watch(budgetLimitProvider);
  if (budget <= 0) return 0;
  return expense / budget;
});
