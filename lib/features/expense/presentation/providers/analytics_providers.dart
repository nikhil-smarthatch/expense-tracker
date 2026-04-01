import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/expense_category.dart';
import '../providers/expense_providers.dart';

/// Spending data for a specific month
class MonthlySummary {
  final int month;
  final int year;
  final double totalExpense;
  final double totalIncome;
  final double netAmount;

  MonthlySummary({
    required this.month,
    required this.year,
    required this.totalExpense,
    required this.totalIncome,
    required this.netAmount,
  });

  String get monthYear => '$month/$year';

  @override
  String toString() =>
      'MonthlySummary($monthYear: expense=$totalExpense, income=$totalIncome)';
}

/// Spending trend for last 12 months up to selected month
final monthlyTrendProvider = Provider<List<MonthlySummary>>((ref) {
  final expensesAsync = ref.watch(expensesProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);

  return expensesAsync.maybeWhen(
    data: (expenses) {
      final now = selectedMonth;
      final summaries = <MonthlySummary>[];

      // Get data for last 12 months
      for (int i = 11; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i);
        final monthExpenses = expenses.where((e) =>
            e.date.month == date.month &&
            e.date.year == date.year &&
            !e.isIncome);
        final monthIncome = expenses.where((e) =>
            e.date.month == date.month &&
            e.date.year == date.year &&
            e.isIncome);

        final totalExpense =
            monthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
        final totalIncome =
            monthIncome.fold<double>(0, (sum, e) => sum + e.amount);

        summaries.add(MonthlySummary(
          month: date.month,
          year: date.year,
          totalExpense: totalExpense,
          totalIncome: totalIncome,
          netAmount: totalIncome - totalExpense,
        ));
      }

      return summaries;
    },
    orElse: () => [],
  );
});

/// Month-over-month spending change percentage
final monthOverMonthChangeProvider = Provider<double>((ref) {
  final trend = ref.watch(monthlyTrendProvider);
  if (trend.length < 2) return 0.0;

  final currentMonth = trend.last;
  final lastMonth = trend[trend.length - 2];

  if (lastMonth.totalExpense == 0) return 0.0;

  final change = (currentMonth.totalExpense - lastMonth.totalExpense) /
      lastMonth.totalExpense;
  return change;
});

/// Average spending per month (last 12 months)
final averageMonthlySpendingProvider = Provider<double>((ref) {
  final trend = ref.watch(monthlyTrendProvider);
  if (trend.isEmpty) return 0.0;

  final total = trend.fold<double>(0, (sum, m) => sum + m.totalExpense);
  return total / trend.length;
});

/// Highest spending month in last 12 months
final highestSpendingMonthProvider = Provider<MonthlySummary?>((ref) {
  final trend = ref.watch(monthlyTrendProvider);
  if (trend.isEmpty) return null;

  return trend.reduce((a, b) => a.totalExpense >= b.totalExpense ? a : b);
});

/// Lowest spending month in last 12 months
final lowestSpendingMonthProvider = Provider<MonthlySummary?>((ref) {
  final trend = ref.watch(monthlyTrendProvider);
  if (trend.isEmpty) return null;

  return trend.reduce((a, b) => a.totalExpense <= b.totalExpense ? a : b);
});

/// Category spending distribution (percentage of total spending for selected month)
final categoryDistributionProvider =
    Provider<Map<ExpenseCategory, double>>((ref) {
  final expensesAsync = ref.watch(expensesProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);

  return expensesAsync.maybeWhen(
    data: (expenses) {
      final categoryTotals = <ExpenseCategory, double>{};
      double totalSpending = 0.0;

      final monthlyExpenses = expenses.where((e) => 
          !e.isIncome && 
          e.date.month == selectedMonth.month && 
          e.date.year == selectedMonth.year);

      for (final expense in monthlyExpenses) {
        categoryTotals[expense.category] =
            (categoryTotals[expense.category] ?? 0.0) + expense.amount;
        totalSpending += expense.amount;
      }

      if (totalSpending == 0) return {};

      // Convert to percentages
      final distribution = <ExpenseCategory, double>{};
      categoryTotals.forEach((category, amount) {
        distribution[category] = (amount / totalSpending) * 100;
      });

      return distribution;
    },
    orElse: () => {},
  );
});

/// Spending insight/prediction
class SpendingInsight {
  final String title;
  final String description;
  final InsightType type;

  SpendingInsight({
    required this.title,
    required this.description,
    required this.type,
  });
}

enum InsightType { warning, positive, neutral }

/// AI-like insights based on spending patterns
final spendingInsightsProvider = Provider<List<SpendingInsight>>((ref) {
  final insights = <SpendingInsight>[];

  final trend = ref.watch(monthlyTrendProvider);
  final momChange = ref.watch(monthOverMonthChangeProvider);
  final categoryDist = ref.watch(categoryDistributionProvider);
  final average = ref.watch(averageMonthlySpendingProvider);

  // Insight 1: Spending trend
  if (trend.length >= 2) {
    if (momChange > 0.1) {
      insights.add(SpendingInsight(
        title: 'Spending Increased',
        description:
            'Your spending is up ${(momChange * 100).toStringAsFixed(1)}% compared to last month.',
        type: InsightType.warning,
      ));
    } else if (momChange < -0.1) {
      insights.add(SpendingInsight(
        title: 'Great Job! 🎉',
        description:
            'Your spending decreased by ${(-momChange * 100).toStringAsFixed(1)}% compared to last month.',
        type: InsightType.positive,
      ));
    }
  }

  // Insight 2: Highest category
  if (categoryDist.isNotEmpty) {
    final highest =
        categoryDist.entries.reduce((a, b) => a.value >= b.value ? a : b);
    if (highest.value > 40) {
      insights.add(SpendingInsight(
        title: 'High ${highest.key.label} Spending',
        description:
            '${highest.key.label} accounts for ${highest.value.toStringAsFixed(1)}% of your spending.',
        type: InsightType.neutral,
      ));
    }
  }

  // Insight 3: Current spending vs average
  if (trend.isNotEmpty && average > 0) {
    final currentMonthExpense = trend.last.totalExpense;
    final deviation = currentMonthExpense - average;
    if (deviation > average * 0.2) {
      insights.add(SpendingInsight(
        title: 'Above Average Spending',
        description:
            'This month you\'re spending ₹${deviation.toStringAsFixed(0)} more than your average.',
        type: InsightType.warning,
      ));
    }
  }

  return insights;
});
