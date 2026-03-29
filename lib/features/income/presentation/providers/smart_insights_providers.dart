import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/spending_analyzer.dart';
import '../../domain/entities/savings_goal.dart';
import '../../../expense/presentation/providers/expense_providers.dart';
import 'savings_goal_providers.dart';

// ==================== Spending Analysis ====================

/// Get spending breakdown by category for current month
final spendingByCategoryProvider =
    FutureProvider<Map<String, double>>((ref) async {
  final expenses = await ref.watch(expensesProvider.future);
  return SpendingAnalyzer.getSpendingByCategory(expenses);
});

/// Get total monthly spending
final monthlySpendingProvider = FutureProvider<double>((ref) async {
  final expenses = await ref.watch(expensesProvider.future);
  return SpendingAnalyzer.getMonthlySpending(expenses);
});

/// Get total monthly income
final monthlyIncomeProvider = FutureProvider<double>((ref) async {
  final expenses = await ref.watch(expensesProvider.future);
  return SpendingAnalyzer.getMonthlyIncome(expenses);
});

/// Get available monthly savings
final availableSavingsProvider = FutureProvider<double>((ref) async {
  final expenses = await ref.watch(expensesProvider.future);
  return SpendingAnalyzer.getAvailableSavings(expenses);
});

// ==================== Smart Suggestions ====================

/// Generate saving suggestions for a specific goal
final savingSuggestionsProvider =
    FutureProvider.family<List<SavingSuggestion>, String>((ref, goalId) async {
  try {
    final expenses = await ref.watch(expensesProvider.future);
    final goal = await ref.watch(savingsGoalProvider(goalId).future);

    if (goal == null) return [];

    // Calculate how much more savings is needed monthly
    final available = SpendingAnalyzer.getAvailableSavings(expenses);
    final required = goal.requiredMonthlySavings ?? 0.0;
    final deficit = (required - available).clamp(0.0, double.infinity);

    return SpendingAnalyzer.generateSavingSuggestions(
      expenses,
      goal,
      savingsTarget: deficit,
    );
  } catch (e) {
    return [];
  }
});

/// Get all suggestions for primary goal
final primaryGoalSuggestionsProvider =
    FutureProvider<List<SavingSuggestion>>((ref) async {
  try {
    final primaryGoal = await ref.watch(primarySavingsGoalProvider.future);
    if (primaryGoal == null) return [];

    return ref.watch(savingSuggestionsProvider(primaryGoal.id).future);
  } catch (e) {
    return [];
  }
});

// ==================== Budget Guidance ====================

/// Get daily budget needed for primary goal
final dailyBudgetProvider = FutureProvider<double>((ref) async {
  try {
    final primaryGoal = await ref.watch(primarySavingsGoalProvider.future);
    if (primaryGoal == null || primaryGoal.deadline == null) return 0.0;

    return SpendingAnalyzer.getDailyBudgetForGoal(
      primaryGoal,
      primaryGoal.deadline!,
    );
  } catch (e) {
    return 0.0;
  }
});

/// Get weekly budget needed for primary goal
final weeklyBudgetProvider = FutureProvider<double>((ref) async {
  try {
    final primaryGoal = await ref.watch(primarySavingsGoalProvider.future);
    if (primaryGoal == null || primaryGoal.deadline == null) return 0.0;

    return SpendingAnalyzer.getWeeklyBudgetForGoal(
      primaryGoal,
      primaryGoal.deadline!,
    );
  } catch (e) {
    return 0.0;
  }
});

/// Get monthly budget needed for primary goal
final monthlyBudgetProvider = FutureProvider<double>((ref) async {
  try {
    final primaryGoal = await ref.watch(primarySavingsGoalProvider.future);
    if (primaryGoal == null || primaryGoal.deadline == null) return 0.0;

    return SpendingAnalyzer.getMonthlyBudgetForGoal(
      primaryGoal,
      primaryGoal.deadline!,
    );
  } catch (e) {
    return 0.0;
  }
});

/// Budget guidance for a specific goal
final budgetGuidanceProvider =
    FutureProvider.family<BudgetGuidance?, String>((ref, goalId) async {
  try {
    final goal = await ref.watch(savingsGoalProvider(goalId).future);
    if (goal == null || goal.deadline == null) return null;

    return BudgetGuidance(
      goalId: goalId,
      dailyBudget: SpendingAnalyzer.getDailyBudgetForGoal(goal, goal.deadline!),
      weeklyBudget:
          SpendingAnalyzer.getWeeklyBudgetForGoal(goal, goal.deadline!),
      monthlyBudget:
          SpendingAnalyzer.getMonthlyBudgetForGoal(goal, goal.deadline!),
    );
  } catch (e) {
    return null;
  }
});

// ==================== Goal Completion Prediction ====================

/// Predict when primary goal will be completed
final completionDateProvider = FutureProvider<DateTime?>((ref) async {
  try {
    final primaryGoal = await ref.watch(primarySavingsGoalProvider.future);
    if (primaryGoal == null) return null;

    final available = await ref.watch(availableSavingsProvider.future);
    return SpendingAnalyzer.predictCompletionDate(primaryGoal, available);
  } catch (e) {
    return null;
  }
});

/// Predict completion for a specific goal
final completionPredictionProvider =
    FutureProvider.family<CompletionPrediction?, String>((ref, goalId) async {
  try {
    final goal = await ref.watch(savingsGoalProvider(goalId).future);
    if (goal == null) return null;

    final available = await ref.watch(availableSavingsProvider.future);
    final predictedDate =
        SpendingAnalyzer.predictCompletionDate(goal, available);

    if (predictedDate == null) return null;

    final isAchievable =
        goal.deadline == null || predictedDate.isBefore(goal.deadline!);

    return CompletionPrediction(
      goalId: goalId,
      predictedDate: predictedDate,
      isAchievable: isAchievable,
      monthsUntilCompletion: _monthsUntil(DateTime.now(), predictedDate),
      monthsUntilDeadline: goal.deadline != null
          ? _monthsUntil(DateTime.now(), goal.deadline!)
          : null,
    );
  } catch (e) {
    return null;
  }
});

/// Completion status for all active goals
final allGoalsCompletionPredictionProvider =
    FutureProvider<List<CompletionPrediction>>((ref) async {
  try {
    final goals = await ref.watch(activeSavingsGoalsProvider.future);
    final predictions = <CompletionPrediction>[];

    for (final goal in goals) {
      final prediction =
          await ref.watch(completionPredictionProvider(goal.id).future);
      if (prediction != null) {
        predictions.add(prediction);
      }
    }

    return predictions;
  } catch (e) {
    return [];
  }
});

// ==================== Helper Models ====================

/// Budget guidance data
class BudgetGuidance {
  const BudgetGuidance({
    required this.goalId,
    required this.dailyBudget,
    required this.weeklyBudget,
    required this.monthlyBudget,
  });

  final String goalId;
  final double dailyBudget;
  final double weeklyBudget;
  final double monthlyBudget;

  @override
  String toString() =>
      'BudgetGuidance(Daily: ₹${dailyBudget.toStringAsFixed(0)}, Weekly: ₹${weeklyBudget.toStringAsFixed(0)}, Monthly: ₹${monthlyBudget.toStringAsFixed(0)})';
}

/// Goal completion prediction
class CompletionPrediction {
  const CompletionPrediction({
    required this.goalId,
    required this.predictedDate,
    required this.isAchievable,
    required this.monthsUntilCompletion,
    this.monthsUntilDeadline,
  });

  final String goalId;
  final DateTime predictedDate;
  final bool isAchievable;
  final int monthsUntilCompletion;
  final int? monthsUntilDeadline;

  int? get monthsEarlyOrLate {
    if (monthsUntilDeadline == null) return null;
    return monthsUntilCompletion - monthsUntilDeadline!;
  }

  bool get isOnTime => isAchievable;
  bool get isLate => !isAchievable && monthsUntilDeadline != null;

  @override
  String toString() =>
      'CompletionPrediction($predictedDate, Achievable: $isAchievable, Months: $monthsUntilCompletion)';
}

int _monthsUntil(DateTime from, DateTime to) {
  return (to.year - from.year) * 12 +
      (to.month - from.month) +
      (to.day >= from.day ? 0 : -1);
}
