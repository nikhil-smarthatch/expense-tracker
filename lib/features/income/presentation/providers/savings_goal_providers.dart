import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/savings_goal.dart';
import '../../data/repositories/savings_goal_repository.dart';
import '../../../expense/presentation/providers/expense_providers.dart';

// ==================== Providers ====================

/// Repository provider
final savingsGoalRepositoryProvider = Provider((ref) {
  return SavingsGoalRepository();
});

/// Get all savings goals
final allSavingsGoalsProvider = FutureProvider<List<SavingsGoal>>((ref) async {
  final repository = ref.watch(savingsGoalRepositoryProvider);
  return repository.getAllGoals();
});

/// Get active savings goals (not completed)
final activeSavingsGoalsProvider =
    FutureProvider<List<SavingsGoal>>((ref) async {
  final repository = ref.watch(savingsGoalRepositoryProvider);
  return repository.getActiveGoals();
});

/// Get primary/main savings goal
final primarySavingsGoalProvider = FutureProvider<SavingsGoal?>((ref) async {
  final activeGoals = await ref.watch(activeSavingsGoalsProvider.future);
  if (activeGoals.isEmpty) return null;

  // Return goal with highest priority or earliest deadline
  activeGoals.sort((a, b) {
    final priorityMap = {'high': 0, 'medium': 1, 'low': 2};
    final priorityDiff = (priorityMap[a.priority] ?? 99)
        .compareTo(priorityMap[b.priority] ?? 99);
    if (priorityDiff != 0) return priorityDiff;

    // If same priority, earlier deadline first
    if (a.deadline != null && b.deadline != null) {
      return a.deadline!.compareTo(b.deadline!);
    }
    return 0;
  });

  return activeGoals.firstOrNull;
});

/// Get savings goal by ID
final savingsGoalProvider =
    FutureProvider.family<SavingsGoal?, String>((ref, id) async {
  final repository = ref.watch(savingsGoalRepositoryProvider);
  return repository.getGoalById(id);
});

// ==================== Calculations ====================

/// Calculate available monthly savings (income - expenses)
final monthlyAvailableSavingsProvider = FutureProvider<double>((ref) async {
  try {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final expenses = await ref.watch(expensesProvider.future);

    // Calculate monthly income
    double monthlyIncome = 0.0;
    for (final e in expenses) {
      if (e.isIncome &&
          e.date.isAfter(startOfMonth) &&
          e.date.isBefore(endOfMonth.add(const Duration(days: 1)))) {
        monthlyIncome += e.amount;
      }
    }

    // Calculate monthly expenses
    double monthlyExpenses = 0.0;
    for (final e in expenses) {
      if (!e.isIncome &&
          e.date.isAfter(startOfMonth) &&
          e.date.isBefore(endOfMonth.add(const Duration(days: 1)))) {
        monthlyExpenses += e.amount;
      }
    }

    return (monthlyIncome - monthlyExpenses).clamp(0.0, double.infinity);
  } catch (e) {
    return 0.0;
  }
});

/// Calculate total amount saved across all active goals
final totalSavedProvider = FutureProvider<double>((ref) async {
  final goals = await ref.watch(activeSavingsGoalsProvider.future);
  double total = 0.0;
  for (final goal in goals) {
    total += goal.currentAmount;
  }
  return total;
});

/// Calculate total target amount for all active goals
final totalGoalTargetProvider = FutureProvider<double>((ref) async {
  final goals = await ref.watch(activeSavingsGoalsProvider.future);
  double total = 0.0;
  for (final goal in goals) {
    total += goal.targetAmount;
  }
  return total;
});

/// Calculate overall progress percentage for all goals
final overallGoalProgressProvider = FutureProvider<double>((ref) async {
  final totalTarget = await ref.watch(totalGoalTargetProvider.future);
  if (totalTarget <= 0) return 0.0;

  final totalSaved = await ref.watch(totalSavedProvider.future);
  return ((totalSaved / totalTarget) * 100).clamp(0.0, 100.0);
});

/// Get primary goal status (on track, at risk, behind)
final primaryGoalStatusProvider =
    FutureProvider<(GoalStatus, double?)>((ref) async {
  final primaryGoal = await ref.watch(primarySavingsGoalProvider.future);
  if (primaryGoal == null) return (GoalStatus.noDeadline, null);

  final availableSavings =
      await ref.watch(monthlyAvailableSavingsProvider.future);
  final status = primaryGoal.getStatus(availableSavings);

  // Calculate deficit or surplus
  final required = primaryGoal.requiredMonthlySavings;
  final deficit = required != null
      ? (required - availableSavings).clamp(0.0, double.infinity)
      : null;

  return (status, deficit);
});

/// Notifier for managing savings goals (CRUD operations)
class SavingsGoalNotifier extends StateNotifier<AsyncValue<void>> {
  SavingsGoalNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<void> addGoal({
    required String title,
    required String description,
    required double targetAmount,
    required String category,
    required String priority,
    DateTime? deadline,
  }) async {
    state = const AsyncValue.loading();
    try {
      final goal = SavingsGoal(
        id: const Uuid().v4(),
        title: title,
        description: description,
        targetAmount: targetAmount,
        currentAmount: 0.0,
        category: category,
        priority: priority,
        createdDate: DateTime.now(),
        deadline: deadline,
      );

      final repository = ref.read(savingsGoalRepositoryProvider);
      await repository.addGoal(goal);

      ref.invalidate(allSavingsGoalsProvider);
      ref.invalidate(activeSavingsGoalsProvider);
      ref.invalidate(primarySavingsGoalProvider);

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateGoal(SavingsGoal goal) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(savingsGoalRepositoryProvider);
      await repository.updateGoal(goal);

      ref.invalidate(allSavingsGoalsProvider);
      ref.invalidate(activeSavingsGoalsProvider);
      ref.invalidate(primarySavingsGoalProvider);

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteGoal(String id) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(savingsGoalRepositoryProvider);
      await repository.deleteGoal(id);

      ref.invalidate(allSavingsGoalsProvider);
      ref.invalidate(activeSavingsGoalsProvider);
      ref.invalidate(primarySavingsGoalProvider);

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> completeGoal(String id) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(savingsGoalRepositoryProvider);
      await repository.completeGoal(id);

      ref.invalidate(allSavingsGoalsProvider);
      ref.invalidate(activeSavingsGoalsProvider);
      ref.invalidate(primarySavingsGoalProvider);

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateGoalAmount(String id, double amount) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(savingsGoalRepositoryProvider);
      await repository.updateGoalAmount(id, amount);

      ref.invalidate(allSavingsGoalsProvider);
      ref.invalidate(activeSavingsGoalsProvider);
      ref.invalidate(primarySavingsGoalProvider);

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

/// Notifier provider for CRUD operations
final savingsGoalNotifierProvider =
    StateNotifierProvider<SavingsGoalNotifier, AsyncValue<void>>(
  (ref) => SavingsGoalNotifier(ref),
);
