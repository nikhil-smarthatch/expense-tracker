import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../expense/presentation/providers/expense_providers.dart';
import '../../../expense/presentation/widgets/expense_card.dart';
import '../../../expense/presentation/widgets/empty_state.dart';
import '../../../expense/presentation/widgets/monthly_filter.dart';
import '../widgets/chart_widgets.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../expense/presentation/screens/add_edit_expense_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyTotal = ref.watch(monthlyTotalProvider);
    final categoryBreakdown = ref.watch(categoryBreakdownProvider);
    final dailyTrend = ref.watch(dailyTrendProvider);
    final recentExpenses = ref.watch(recentExpensesProvider);
    final highestCategory = ref.watch(highestCategoryProvider);
    final budgetLimit = ref.watch(budgetLimitProvider);
    final budgetUsage = ref.watch(budgetUsageProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showBudgetDialog(context, ref, budgetLimit),
            tooltip: 'Set Budget',
          ),
        ],
      ),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (_) => RefreshIndicator(
          onRefresh: () => ref.refresh(expensesProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month Filter
                Center(child: const MonthlyFilterWidget()),
                const SizedBox(height: 16),

                // Total Expense Card
                _TotalExpenseCard(
                  total: monthlyTotal,
                  budgetLimit: budgetLimit,
                  budgetUsage: budgetUsage,
                ),
                const SizedBox(height: 16),

                // Highest Category Badge
                if (highestCategory != null)
                  _HighestCategoryCard(category: highestCategory!),
                const SizedBox(height: 16),

                // Category Pie Chart
                if (categoryBreakdown.isNotEmpty) ...[
                  _SectionTitle(title: 'Category Breakdown'),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        height: 200,
                        child: CategoryPieChart(data: categoryBreakdown),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Daily Spending Trend
                if (dailyTrend.any((d) => d > 0)) ...[
                  _SectionTitle(title: 'Daily Spending Trend'),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                      child: SizedBox(
                        height: 180,
                        child: DailyBarChart(dailyTotals: dailyTrend),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Recent Transactions
                _SectionTitle(title: 'Recent Transactions'),
                const SizedBox(height: 8),
                if (recentExpenses.isEmpty)
                  const EmptyStateWidget(
                    title: 'No expenses yet',
                    subtitle: 'Tap + to add your first expense',
                    icon: Icons.add_chart_rounded,
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = recentExpenses[index];
                      return ExpenseCard(
                        expense: expense,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddEditExpenseScreen(
                                existingExpense: expense),
                          ),
                        ),
                        onDelete: () => ref
                            .read(expensesProvider.notifier)
                            .deleteExpense(expense.id),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBudgetDialog(
      BuildContext context, WidgetRef ref, double current) {
    final controller = TextEditingController(text: current.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Budget Amount (₹)',
            prefixText: '₹ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                ref.read(budgetLimitProvider.notifier).setBudget(value);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────

class _TotalExpenseCard extends StatelessWidget {
  const _TotalExpenseCard({
    required this.total,
    required this.budgetLimit,
    required this.budgetUsage,
  });

  final double total;
  final double budgetLimit;
  final double budgetUsage;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOverBudget = budgetUsage >= 1.0;

    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total This Month',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.onPrimaryContainer.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(total),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 12),
            // Budget progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: budgetUsage.clamp(0.0, 1.0),
                backgroundColor: cs.onPrimaryContainer.withOpacity(0.15),
                color: isOverBudget ? cs.error : cs.primary,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isOverBudget
                      ? '⚠️ Over budget!'
                      : '${(budgetUsage * 100).toStringAsFixed(0)}% of budget used',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOverBudget
                            ? cs.error
                            : cs.onPrimaryContainer.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  'Budget: ${CurrencyFormatter.formatCompact(budgetLimit)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onPrimaryContainer.withOpacity(0.7),
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

class _HighestCategoryCard extends StatelessWidget {
  const _HighestCategoryCard({required this.category});

  final dynamic category;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: category.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: category.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, color: category.color, size: 20),
          const SizedBox(width: 8),
          Text(
            '🏆 Highest: ${category.label}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: category.color,
                ),
          ),
        ],
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
