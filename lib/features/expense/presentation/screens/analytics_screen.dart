import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analytics_providers.dart';
import '../../../../core/utils/currency_formatter.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trend = ref.watch(monthlyTrendProvider);
    final momChange = ref.watch(monthOverMonthChangeProvider);
    final average = ref.watch(averageMonthlySpendingProvider);
    final highest = ref.watch(highestSpendingMonthProvider);
    final lowest = ref.watch(lowestSpendingMonthProvider);
    final insights = ref.watch(spendingInsightsProvider);
    final distribution = ref.watch(categoryDistributionProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monthly Trend Summary
            if (trend.isNotEmpty) ...[
              const _SectionTitle(title: 'Monthly Overview'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Average Monthly Spend',
                                  style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(average),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: momChange >= 0
                                  ? cs.errorContainer
                                  : Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${momChange >= 0 ? '+' : ''}${(momChange * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: momChange >= 0 ? cs.error : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Highest Month',
                                  style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 4),
                              Text(
                                highest != null
                                    ? CurrencyFormatter.format(
                                        highest.totalExpense)
                                    : '₹0',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (highest != null)
                                Text(
                                  '${highest.month}/${highest.year}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Lowest Month',
                                  style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 4),
                              Text(
                                lowest != null
                                    ? CurrencyFormatter.format(
                                        lowest.totalExpense)
                                    : '₹0',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (lowest != null)
                                Text(
                                  '${lowest.month}/${lowest.year}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],


            // Category Distribution
            if (distribution.isNotEmpty) ...[
              const _SectionTitle(title: 'Category Distribution'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: distribution.entries.map((entry) {
                      final category = entry.key;
                      final percentage = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 30,
                              child: Icon(
                                category.icon,
                                color: category.color,
                                size: 18,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(category.label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: percentage / 100,
                                      backgroundColor:
                                          cs.surfaceContainerHighest,
                                      color:
                                          category.color.withValues(alpha: 0.7),
                                      minHeight: 4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Insights
            if (insights.isNotEmpty) ...[
              const _SectionTitle(title: 'Insights'),
              const SizedBox(height: 8),
              ...insights.map((insight) {
                final iconColor = insight.type == InsightType.warning
                    ? cs.error
                    : insight.type == InsightType.positive
                        ? Colors.green
                        : cs.secondary;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    color: insight.type == InsightType.warning
                        ? cs.errorContainer.withValues(alpha: 0.5)
                        : insight.type == InsightType.positive
                            ? Colors.green.withValues(alpha: 0.1)
                            : cs.secondaryContainer.withValues(alpha: 0.5),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              insight.type == InsightType.warning
                                  ? Icons.warning_rounded
                                  : insight.type == InsightType.positive
                                      ? Icons.trending_down_rounded
                                      : Icons.info_rounded,
                              color: iconColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  insight.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  insight.description,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],

            if (insights.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'No data available yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
