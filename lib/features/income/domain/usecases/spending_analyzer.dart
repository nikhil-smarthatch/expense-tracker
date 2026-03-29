import '../../../expense/domain/entities/expense.dart';
import '../entities/savings_goal.dart';

/// Analyzes spending patterns to generate smart insights
class SpendingAnalyzer {
  /// Get spending totals by category for a given time period
  static Map<String, double> getSpendingByCategory(
    List<Expense> expenses, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final start =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    final categorySpendings = <String, double>{};

    for (final expense in expenses) {
      // Only count expenses (not income)
      if (expense.isIncome) continue;

      // Filter by date range
      if (expense.date.isBefore(start) || expense.date.isAfter(end)) continue;

      final categoryKey = expense.category.toString();
      categorySpendings.update(
        categoryKey,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    return categorySpendings;
  }

  /// Calculate top categories where user can save the most
  static List<SavingSuggestion> generateSavingSuggestions(
    List<Expense> expenses,
    SavingsGoal goal, {
    double savingsTarget = 0.0,
  }) {
    final categorySpending = getSpendingByCategory(expenses);
    final suggestions = <SavingSuggestion>[];

    // Sort by spending amount (highest first)
    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate how much to cut from each category
    double totalToSave = savingsTarget;
    for (final entry in sortedCategories) {
      if (totalToSave <= 0) break;

      final category = entry.key;
      final spent = entry.value;

      // Suggest cutting 20-30% from this category (realistic)
      final reducedAmount = (spent * 0.25).clamp(0.0, totalToSave);

      if (reducedAmount > 0) {
        suggestions.add(
          SavingSuggestion(
            category: category,
            currentSpending: spent,
            suggestedCut: reducedAmount,
            percentageReduction: ((reducedAmount / spent) * 100).clamp(0, 100),
            impactOnGoal: goalCompletionDaysReduced(
              monthlyAvailable: reducedAmount,
              goalRemaining: goal.remainingAmount,
            ),
          ),
        );
        totalToSave -= reducedAmount;
      }
    }

    return suggestions;
  }

  /// Calculate total monthly spending
  static double getMonthlySpending(List<Expense> expenses) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    double total = 0.0;
    for (final expense in expenses) {
      if (expense.isIncome) continue;
      if (expense.date.isAfter(startOfMonth) &&
          expense.date.isBefore(endOfMonth.add(const Duration(days: 1)))) {
        total += expense.amount;
      }
    }
    return total;
  }

  /// Calculate monthly income
  static double getMonthlyIncome(List<Expense> expenses) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    double total = 0.0;
    for (final expense in expenses) {
      if (!expense.isIncome) continue;
      if (expense.date.isAfter(startOfMonth) &&
          expense.date.isBefore(endOfMonth.add(const Duration(days: 1)))) {
        total += expense.amount;
      }
    }
    return total;
  }

  /// Calculate available monthly savings
  static double getAvailableSavings(List<Expense> expenses) {
    return (getMonthlyIncome(expenses) - getMonthlySpending(expenses))
        .clamp(0.0, double.infinity);
  }

  /// Predict goal completion date
  static DateTime? predictCompletionDate(
    SavingsGoal goal,
    double monthlyAvailable,
  ) {
    if (monthlyAvailable <= 0 || goal.remainingAmount <= 0) {
      return null;
    }

    final monthsNeeded = (goal.remainingAmount / monthlyAvailable).ceil();
    final now = DateTime.now();
    return DateTime(now.year, now.month + monthsNeeded, now.day);
  }

  /// Calculate how many days earlier goal can be completed
  static int goalCompletionDaysReduced(
      {required double monthlyAvailable, required double goalRemaining}) {
    if (monthlyAvailable <= 0 || goalRemaining <= 0) return 0;
    final daysToComplete = (goalRemaining / (monthlyAvailable / 30)).toInt();
    return daysToComplete;
  }

  /// Calculate daily budget needed to reach goal
  static double getDailyBudgetForGoal(
    SavingsGoal goal,
    DateTime deadline,
  ) {
    final now = DateTime.now();
    if (deadline.isBefore(now)) return 0;

    final daysLeft = deadline.difference(now).inDays;
    if (daysLeft <= 0) return 0;

    return goal.remainingAmount / daysLeft;
  }

  /// Calculate weekly budget needed to reach goal
  static double getWeeklyBudgetForGoal(
    SavingsGoal goal,
    DateTime deadline,
  ) {
    final now = DateTime.now();
    if (deadline.isBefore(now)) return 0;

    final weeksLeft = deadline.difference(now).inDays / 7;
    if (weeksLeft <= 0) return 0;

    return goal.remainingAmount / weeksLeft;
  }

  /// Calculate monthly budget needed to reach goal
  static double getMonthlyBudgetForGoal(
    SavingsGoal goal,
    DateTime deadline,
  ) {
    final now = DateTime.now();
    if (deadline.isBefore(now)) return 0;

    final monthsLeft = ((deadline.year - now.year) * 12 +
        (deadline.month - now.month) +
        (deadline.day >= now.day ? 0 : -1));
    if (monthsLeft <= 0) return 0;

    return goal.remainingAmount / monthsLeft;
  }
}

/// Represents a suggestion to cut spending in a category
class SavingSuggestion {
  const SavingSuggestion({
    required this.category,
    required this.currentSpending,
    required this.suggestedCut,
    required this.percentageReduction,
    required this.impactOnGoal,
  });

  final String category;
  final double currentSpending;
  final double suggestedCut;
  final double percentageReduction;
  final int impactOnGoal; // Days reduced in goal completion

  double get newSpending => currentSpending - suggestedCut;

  @override
  String toString() =>
      'SavingSuggestion($category: Cut ₹${suggestedCut.toStringAsFixed(0)} from ₹${currentSpending.toStringAsFixed(0)})';
}
