import 'package:flutter/material.dart';
import '../../domain/entities/savings_goal.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Goal progress card widget
class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({
    super.key,
    required this.goal,
    this.onTap,
    this.showDeadline = true,
  });

  final SavingsGoal goal;
  final VoidCallback? onTap;
  final bool showDeadline;

  Color _getStatusColor(BuildContext context, SavingsGoal goal) {
    final cs = Theme.of(context).colorScheme;
    if (goal.isCompleted) return Colors.green;
    return cs.primary;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = _getStatusColor(context, goal);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title and Amount
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          goal.category,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  // Priority badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(context, goal.priority),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      goal.priority.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${goal.progressPercentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        '${CurrencyFormatter.format(goal.currentAmount)} / ${CurrencyFormatter.format(goal.targetAmount)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (goal.progressPercentage / 100).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Status and deadline info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status or completion
                  if (goal.isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '✓ Completed',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    )
                  else if (goal.remainingAmount > 0)
                    Text(
                      'Remaining: ${CurrencyFormatter.format(goal.remainingAmount)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    )
                  else
                    const SizedBox.shrink(),

                  // Deadline info
                  if (showDeadline &&
                      goal.deadline != null &&
                      !goal.isCompleted)
                    Text(
                      goal.remainingMonths != null && goal.remainingMonths! > 0
                          ? '${goal.remainingMonths} months left'
                          : 'Deadline passed',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: goal.remainingMonths != null &&
                                    goal.remainingMonths! < 3
                                ? Colors.orange
                                : cs.onSurfaceVariant,
                          ),
                    )
                  else if (showDeadline &&
                      goal.deadline == null &&
                      !goal.isCompleted)
                    Text(
                      'No deadline',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(BuildContext context, String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}

/// Compact goal progress widget for dashboard
class CompactGoalProgressWidget extends StatelessWidget {
  const CompactGoalProgressWidget({
    super.key,
    required this.goal,
    this.onTap,
  });

  final SavingsGoal goal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goal.title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (goal.progressPercentage / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: cs.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${goal.progressPercentage.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  CurrencyFormatter.format(goal.currentAmount),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
