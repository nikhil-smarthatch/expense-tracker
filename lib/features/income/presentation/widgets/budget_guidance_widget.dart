import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/smart_insights_providers.dart';

/// Widget showing budget guidance and completion prediction
class BudgetGuidanceWidget extends ConsumerWidget {
  const BudgetGuidanceWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAsync = ref.watch(dailyBudgetProvider);
    final weeklyAsync = ref.watch(weeklyBudgetProvider);
    final monthlyAsync = ref.watch(monthlyBudgetProvider);
    final completionAsync = ref.watch(completionDateProvider);
    final cs = Theme.of(context).colorScheme;

    return dailyAsync.when(
      loading: () => _buildLoadingState(cs),
      error: (_, __) => const SizedBox.shrink(),
      data: (daily) => weeklyAsync.when(
        loading: () => _buildLoadingState(cs),
        error: (_, __) => const SizedBox.shrink(),
        data: (weekly) => monthlyAsync.when(
          loading: () => _buildLoadingState(cs),
          error: (_, __) => const SizedBox.shrink(),
          data: (monthly) {
            // Check if we have valid budget data
            if (daily <= 0 && weekly <= 0 && monthly <= 0) {
              return _buildEmptyState(cs);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Budget Guidance Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Savings Target',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        _buildBudgetRow(
                          context,
                          cs,
                          'Daily',
                          daily,
                          Icons.calendar_today_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildBudgetRow(
                          context,
                          cs,
                          'Weekly',
                          weekly,
                          Icons.calendar_view_week_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildBudgetRow(
                          context,
                          cs,
                          'Monthly',
                          monthly,
                          Icons.calendar_month_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Completion Prediction
                completionAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (completionDate) {
                    if (completionDate == null) return const SizedBox.shrink();
                    return _buildCompletionCard(context, cs, completionDate);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBudgetRow(
    BuildContext context,
    ColorScheme cs,
    String label,
    double amount,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                CurrencyFormatter.format(amount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionCard(
    BuildContext context,
    ColorScheme cs,
    DateTime completionDate,
  ) {
    final now = DateTime.now();
    final monthsUntil = (completionDate.year - now.year) * 12 +
        (completionDate.month - now.month) +
        (completionDate.day >= now.day ? 0 : -1);

    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flag_rounded,
                  color: cs.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Estimated Completion',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              monthsUntil <= 1 ? 'This month' : '$monthsUntil months from now',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              completionDate.toString().split(' ')[0],
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.primary.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 48,
                color: cs.outline,
              ),
              const SizedBox(height: 12),
              Text(
                'Set a deadline on your goal to see savings targets',
                style: TextStyle(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
