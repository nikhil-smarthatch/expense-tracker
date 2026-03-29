import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/smart_insights_providers.dart';

/// Widget showing spending breakdown by category
class SpendingBreakdownWidget extends ConsumerWidget {
  const SpendingBreakdownWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spendingAsync = ref.watch(spendingByCategoryProvider);
    final monthlySpendingAsync = ref.watch(monthlySpendingProvider);
    final cs = Theme.of(context).colorScheme;

    return spendingAsync.when(
      loading: () => _buildLoadingState(cs),
      error: (_, __) => const SizedBox.shrink(),
      data: (spending) => monthlySpendingAsync.when(
        loading: () => _buildLoadingState(cs),
        error: (_, __) => const SizedBox.shrink(),
        data: (totalSpending) {
          if (spending.isEmpty || totalSpending <= 0) {
            return _buildEmptyState(cs);
          }

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Spending By Category',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This month: ${CurrencyFormatter.format(totalSpending)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),

                  // Spending bars
                  ..._buildSpendingBars(
                    spending,
                    totalSpending,
                    cs,
                    context,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSpendingBars(
    Map<String, double> spending,
    double totalSpending,
    ColorScheme cs,
    BuildContext context,
  ) {
    // Sort by spending amount (highest first)
    final sorted = spending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(6) // Show top 6 categories
        .map((entry) {
      final category = entry.key;
      final amount = entry.value;
      final percentage = (amount / totalSpending * 100).clamp(0, 100);

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    category,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(amount),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Container(
                  height: 6,
                  width:
                      MediaQuery.of(context).size.width * (percentage / 100) -
                          32,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category, cs),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildLoadingState(ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 20,
              width: 150,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
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
                Icons.pie_chart_outline_rounded,
                size: 48,
                color: cs.outline,
              ),
              const SizedBox(height: 12),
              Text(
                'No spending data',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category, ColorScheme cs) {
    final colors = [
      cs.primary,
      cs.secondary,
      cs.tertiary,
      Color.lerp(cs.primary, cs.secondary, 0.5)!,
      Color.lerp(cs.secondary, cs.tertiary, 0.5)!,
      Color.lerp(cs.primary, cs.tertiary, 0.5)!,
    ];

    final hash = category.hashCode.abs();
    return colors[hash % colors.length];
  }
}
