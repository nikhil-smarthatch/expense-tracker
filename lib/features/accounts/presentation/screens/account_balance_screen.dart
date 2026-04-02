import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../expense/presentation/providers/expense_providers.dart';
import '../../../income/presentation/providers/income_providers.dart';
import '../../../loan/presentation/providers/loan_providers.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Account Balance screen showing overall financial health
class AccountBalanceScreen extends ConsumerWidget {
  const AccountBalanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final incomeStatsAsync = ref.watch(incomeStatsProvider);
    final loansAsync = ref.watch(loansProvider);
    final cs = Theme.of(context).colorScheme;

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (expenses) => incomeStatsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (incomeStats) => loansAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (loans) {
            final totalIncome = incomeStats.totalIncome;
            final totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);
            final totalBorrowed = loans.where((l) => l.type.name == 'borrow').fold(0.0, (sum, l) => sum + l.totalAmount);
            final totalLent = loans.where((l) => l.type.name == 'lend').fold(0.0, (sum, l) => sum + l.totalAmount);
            final netBalance = totalIncome - totalExpenses - totalBorrowed + totalLent;

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(expensesProvider);
                ref.invalidate(incomeStatsProvider);
                ref.invalidate(loansProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Balance Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Net Balance',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              CurrencyFormatter.format(netBalance),
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: netBalance >= 0 ? cs.primary : cs.error,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  netBalance >= 0 ? Icons.trending_up : Icons.trending_down,
                                  color: netBalance >= 0 ? cs.primary : cs.error,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  netBalance >= 0 ? 'Positive Balance' : 'Negative Balance',
                                  style: TextStyle(
                                    color: netBalance >= 0 ? cs.primary : cs.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Breakdown Cards
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(Icons.arrow_downward, color: cs.primary),
                                  const SizedBox(height: 8),
                                  Text('Income', style: Theme.of(context).textTheme.labelMedium),
                                  const SizedBox(height: 4),
                                  Text(
                                    CurrencyFormatter.format(totalIncome),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: cs.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(Icons.arrow_upward, color: cs.error),
                                  const SizedBox(height: 8),
                                  Text('Expenses', style: Theme.of(context).textTheme.labelMedium),
                                  const SizedBox(height: 4),
                                  Text(
                                    CurrencyFormatter.format(totalExpenses),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: cs.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Loans Summary
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Loans Summary',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Borrowed', style: Theme.of(context).textTheme.bodySmall),
                                    Text(
                                      CurrencyFormatter.format(totalBorrowed),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: cs.error,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Lent', style: Theme.of(context).textTheme.bodySmall),
                                    Text(
                                      CurrencyFormatter.format(totalLent),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: cs.primary,
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
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
