import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reminder_providers.dart';
import '../../domain/entities/reminder.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  String _getTypeLabel(ReminderType type) {
    switch (type) {
      case ReminderType.bill:
        return 'Bill Reminders';
      case ReminderType.budgetWarning:
        return 'Budget Alerts';
      case ReminderType.savingsGoal:
        return 'Savings Goals';
      case ReminderType.recurring:
        return 'Recurring Items';
    }
  }

  IconData _getTypeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.bill:
        return Icons.receipt_outlined;
      case ReminderType.budgetWarning:
        return Icons.warning_rounded;
      case ReminderType.savingsGoal:
        return Icons.savings_outlined;
      case ReminderType.recurring:
        return Icons.repeat_outlined;
    }
  }

  Color _getTypeColor(ReminderType type, ColorScheme cs) {
    switch (type) {
      case ReminderType.bill:
        return cs.primary;
      case ReminderType.budgetWarning:
        return cs.error;
      case ReminderType.savingsGoal:
        return Colors.green;
      case ReminderType.recurring:
        return cs.secondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersProvider);
    final cs = Theme.of(context).colorScheme;

    if (reminders.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  size: 80, color: Colors.green.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                'All Caught Up!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'No active reminders',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    // Group reminders by type
    final groupedReminders = <ReminderType, List<Reminder>>{};
    for (final reminder in reminders.where((r) => r.isActive)) {
      groupedReminders.putIfAbsent(reminder.type, () => []);
      groupedReminders[reminder.type]!.add(reminder);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: groupedReminders.entries.map((entry) {
          final type = entry.key;
          final typeReminders = entry.value;
          final typeColor = _getTypeColor(type, cs);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      Icon(_getTypeIcon(type), color: typeColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _getTypeLabel(type),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                            ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${typeReminders.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: typeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...typeReminders.map((reminder) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: typeColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reminder.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        reminder.message,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
