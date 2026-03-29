import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../expense/domain/entities/expense.dart';
import '../../../expense/presentation/screens/add_edit_expense_screen.dart';
import '../../../expense/presentation/widgets/image_preview_widget.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/income_providers.dart';

class IncomeListScreen extends ConsumerWidget {
  const IncomeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomesAsync = ref.watch(sortedIncomeProvider);
    final incomeStatsAsync = ref.watch(incomeStatsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Income'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AddEditExpenseScreen(),
          ),
        ),
        tooltip: 'Add Income',
        child: const Icon(Icons.arrow_downward_rounded),
      ),
      body: incomesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (incomes) => incomeStatsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (stats) => RefreshIndicator(
            onRefresh: () => ref.refresh(sortedIncomeProvider.future),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Income Summary Cards
                  _IncomeStatsCard(stats: stats, colorScheme: cs),
                  const SizedBox(height: 24),

                  // Income List
                  if (incomes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.attach_money_rounded,
                              size: 64,
                              color: cs.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No income recorded',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start adding your income sources',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AddEditExpenseScreen(),
                                ),
                              ),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add Income'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    Text(
                      'Income Records (${incomes.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: incomes.length,
                      itemBuilder: (context, index) => _IncomeCard(
                        income: incomes[index],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                AddEditExpenseScreen(existingExpense: incomes[index]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IncomeStatsCard extends StatelessWidget {
  const _IncomeStatsCard({
    required this.stats,
    required this.colorScheme,
  });

  final IncomeStats stats;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Monthly Income Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.trending_up_rounded,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This Month',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            CurrencyFormatter.format(stats.monthlyIncome),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: stats.averageMonthlyIncome > 0
                      ? (stats.monthlyIncome / stats.averageMonthlyIncome).clamp(0.0, 1.0)
                      : 0,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  'Avg: ${CurrencyFormatter.format(stats.averageMonthlyIncome)}/month',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Total and Count Stats
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Income',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(stats.totalIncome),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Entries',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stats.monthlyIncomeCount}/${stats.incomeCount}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IncomeCard extends StatelessWidget {
  const _IncomeCard({
    required this.income,
    this.onTap,
  });

  final Expense income;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Category, Amount, Date
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      income.category.icon,
                      color: cs.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          income.category.label,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM dd, yyyy').format(income.date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Amount
                  Text(
                    '+ ${CurrencyFormatter.format(income.amount)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                  ),
                ],
              ),

              // Note and Receipt indicators
              if (income.note != null || income.receiptPath != null) ...[
                const SizedBox(height: 12),
                if (income.note != null) ...[
                  Text(
                    income.note!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (income.receiptPath != null) ...[
                  if (income.note != null) const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => showImagePreview(context, income.receiptPath!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_outlined,
                            size: 16,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'View Receipt',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
