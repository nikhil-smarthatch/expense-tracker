import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/expense_providers.dart';
import '../../../../core/utils/app_date_utils.dart';

/// Month navigation widget: ← March 2025 →
class MonthlyFilterWidget extends ConsumerWidget {
  const MonthlyFilterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final isCurrentMonth = AppDateUtils.isSameMonth(selectedMonth, DateTime.now());
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () =>
                ref.read(selectedMonthProvider.notifier).previousMonth(),
            tooltip: 'Previous month',
            visualDensity: VisualDensity.compact,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              AppDateUtils.formatMonthYear(selectedMonth),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: isCurrentMonth
                ? null
                : () =>
                    ref.read(selectedMonthProvider.notifier).nextMonth(),
            tooltip: 'Next month',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
