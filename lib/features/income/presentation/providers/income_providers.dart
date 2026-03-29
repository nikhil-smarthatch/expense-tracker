import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../expense/domain/entities/expense.dart';
import '../../../expense/presentation/providers/expense_providers.dart';

/// Get all income transactions
final incomeListProvider = FutureProvider<List<Expense>>((ref) async {
  final expenses = await ref.watch(expensesProvider.future);
  return expenses.where((e) => e.isIncome).toList();
});

/// Get income transactions sorted by date (newest first)
final sortedIncomeProvider = FutureProvider<List<Expense>>((ref) async {
  final incomes = await ref.watch(incomeListProvider.future);
  final sorted = [...incomes];
  sorted.sort((a, b) => b.date.compareTo(a.date));
  return sorted;
});

/// Get monthly income sum
final monthlyIncomeProvider = FutureProvider<double>((ref) async {
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0);

  final incomes = await ref.watch(incomeListProvider.future);
  double total = 0.0;
  for (final e in incomes) {
    if (e.date.isAfter(startOfMonth) &&
        e.date.isBefore(endOfMonth.add(const Duration(days: 1)))) {
      total += e.amount;
    }
  }
  return total;
});

/// Get income by category breakdown
final incomeByCategory = FutureProvider<Map<String, double>>((ref) async {
  final incomes = await ref.watch(incomeListProvider.future);
  final breakdown = <String, double>{};

  for (final income in incomes) {
    final categoryName = income.category.name;
    breakdown[categoryName] = (breakdown[categoryName] ?? 0) + income.amount;
  }

  return breakdown;
});

/// Get average monthly income
final averageMonthlyIncomeProvider = FutureProvider<double>((ref) async {
  final incomes = await ref.watch(incomeListProvider.future);

  if (incomes.isEmpty) return 0.0;

  final now = DateTime.now();
  final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);

  final recentIncomes =
      incomes.where((e) => e.date.isAfter(sixMonthsAgo)).toList();

  if (recentIncomes.isEmpty) return 0.0;

  // Group by month and count unique months
  final months = <String>{};
  for (final income in recentIncomes) {
    final monthKey = '${income.date.year}-${income.date.month}';
    months.add(monthKey);
  }

  final totalIncome = recentIncomes.fold(0.0, (sum, e) => sum + e.amount);
  return months.isNotEmpty ? totalIncome / months.length : 0.0;
});

/// Get income for specific date range
final incomeByDateRangeProvider =
    FutureProvider.family<List<Expense>, (DateTime, DateTime)>(
        (ref, dateRange) async {
  final (startDate, endDate) = dateRange;
  final incomes = await ref.watch(incomeListProvider.future);

  return incomes
      .where((e) =>
          e.date.isAfter(startDate) &&
          e.date.isBefore(endDate.add(const Duration(days: 1))))
      .toList();
});

/// Get income with receipts/attachments
final incomeWithReceiptsProvider = FutureProvider<List<Expense>>((ref) async {
  final incomes = await ref.watch(incomeListProvider.future);
  return incomes
      .where((e) => e.receiptPath != null && e.receiptPath!.isNotEmpty)
      .toList();
});

/// Get income statistics for dashboard
final incomeStatsProvider = FutureProvider<IncomeStats>((ref) async {
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0);

  final allIncomes = await ref.watch(incomeListProvider.future);

  final monthlyTotal = await ref.watch(monthlyIncomeProvider.future);
  final avgMonthly = await ref.watch(averageMonthlyIncomeProvider.future);

  return IncomeStats(
    totalIncome: allIncomes.fold(0.0, (sum, e) => sum + e.amount),
    monthlyIncome: monthlyTotal,
    averageMonthlyIncome: avgMonthly,
    incomeCount: allIncomes.length,
    monthlyIncomeCount: allIncomes
        .where((e) =>
            e.date.isAfter(startOfMonth) &&
            e.date.isBefore(endOfMonth.add(const Duration(days: 1))))
        .length,
  );
});

/// Income statistics model
class IncomeStats {
  final double totalIncome;
  final double monthlyIncome;
  final double averageMonthlyIncome;
  final int incomeCount;
  final int monthlyIncomeCount;

  IncomeStats({
    required this.totalIncome,
    required this.monthlyIncome,
    required this.averageMonthlyIncome,
    required this.incomeCount,
    required this.monthlyIncomeCount,
  });
}
