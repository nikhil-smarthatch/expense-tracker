import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/reminder.dart';
import '../providers/expense_providers.dart';
import '../../../loan/presentation/providers/loan_providers.dart';

/// Generates reminders based on current financial state
final remindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = <Reminder>[];
  final now = DateTime.now();

  // 1. Budget warning reminders
  final budgetUsage = ref.watch(budgetUsageProvider);
  if (budgetUsage >= 0.9 && budgetUsage < 1.0) {
    reminders.add(Reminder(
      id: 'budget_warning_${now.millisecondsSinceEpoch}',
      title: 'Budget Alert: Approaching Limit',
      message:
          'You\'ve used ${(budgetUsage * 100).toStringAsFixed(0)}% of your monthly budget.',
      type: ReminderType.budgetWarning,
      dateTime: now,
    ));
  } else if (budgetUsage >= 1.0) {
    reminders.add(Reminder(
      id: 'budget_exceeded_${now.millisecondsSinceEpoch}',
      title: '⚠️ Budget Exceeded',
      message:
          'Your spending has exceeded the monthly budget by ${((budgetUsage - 1.0) * 100).toStringAsFixed(0)}%.',
      type: ReminderType.budgetWarning,
      dateTime: now,
    ));
  }

  // 2. Category budget warnings
  final categoryUsage = ref.watch(categoryBudgetUsageProvider);
  for (final entry in categoryUsage.entries) {
    if (entry.value >= 0.9 && entry.value < 1.0) {
      reminders.add(Reminder(
        id: 'cat_budget_${entry.key.name}',
        title: '${entry.key.label} Budget Alert',
        message:
            'You\'ve used ${(entry.value * 100).toStringAsFixed(0)}% of ${entry.key.label} budget.',
        type: ReminderType.budgetWarning,
        dateTime: now,
      ));
    }
  }

  // 3. Unpaid loan reminders
  final loansAsync = ref.watch(loansProvider);
  loansAsync.whenData((loans) {
    for (final loan in loans.where((l) => !l.isSettled)) {
      reminders.add(Reminder(
        id: 'loan_${loan.id}',
        title: 'Outstanding Loan: ${loan.personName}',
        message:
            '${loan.type.label}: ₹${loan.remainingAmount.toStringAsFixed(0)} remaining',
        type: ReminderType.bill,
        dateTime: now,
        relatedId: loan.id,
      ));
    }
  });

  return reminders;
});

/// Filters reminders by type
final remindersByTypeProvider =
    Provider.family<List<Reminder>, ReminderType>((ref, type) {
  final all = ref.watch(remindersProvider);
  return all.where((r) => r.type == type).toList();
});

/// Count of active reminders by type
final reminderCountProvider = Provider<Map<ReminderType, int>>((ref) {
  final all = ref.watch(remindersProvider);
  final counts = <ReminderType, int>{};

  for (final type in ReminderType.values) {
    counts[type] = all.where((r) => r.type == type && r.isActive).length;
  }

  return counts;
});

/// Total active reminders count
final totalReminderCountProvider = Provider<int>((ref) {
  final reminders = ref.watch(remindersProvider);
  return reminders.where((r) => r.isActive).length;
});

/// Urgent reminders (budget exceeded, unpaid bills)
final urgentRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(remindersProvider);
  return reminders
      .where((r) =>
          r.isActive &&
          (r.type == ReminderType.budgetWarning || r.type == ReminderType.bill))
      .toList();
});
