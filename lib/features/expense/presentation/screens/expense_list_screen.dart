import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/expense.dart';
import '../providers/expense_providers.dart';
import '../widgets/expense_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/monthly_filter.dart';
import 'add_edit_expense_screen.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../widgets/category_budget_dialog.dart';
import 'reports_screen.dart';

enum ExpenseMenuAction { reports, categoryBudgets, setBudget }

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredExpensesProvider);
    final monthlyTotal = ref.watch(monthlyExpenseProvider);
    final budgetLimit = ref.watch(budgetLimitProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => showSearch(
              context: context,
              delegate: _ExpenseSearchDelegate(ref),
            ),
            tooltip: 'Search',
          ),
          PopupMenuButton<ExpenseMenuAction>(
            onSelected: (action) {
              if (action == ExpenseMenuAction.reports) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReportsScreen()),
                );
              } else if (action == ExpenseMenuAction.categoryBudgets) {
                showDialog(
                  context: context,
                  builder: (_) => const CategoryBudgetDialog(),
                );
              } else if (action == ExpenseMenuAction.setBudget) {
                _showBudgetDialog(context, ref, budgetLimit);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ExpenseMenuAction.reports,
                child: ListTile(
                  leading: Icon(Icons.description_outlined),
                  title: Text('Reports'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: ExpenseMenuAction.categoryBudgets,
                child: ListTile(
                  leading: Icon(Icons.category_outlined),
                  title: Text('Category Budgets'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: ExpenseMenuAction.setBudget,
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Set Monthly Budget'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: filteredAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (expenses) => Column(
          children: [
            // Month selector + monthly total summary
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                border: Border(
                    bottom: BorderSide(
                        color: cs.outline.withValues(alpha: 0.15))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const MonthlyFilterWidget(),
                  Text(
                    CurrencyFormatter.format(monthlyTotal),
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.refresh(expensesProvider.future),
                child: expenses.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: EmptyStateWidget(
                              title: 'No expenses this month',
                              subtitle:
                                  'Tap + to add your first expense for this period',
                              icon: Icons.receipt_long_rounded,
                              action: FilledButton.icon(
                                onPressed: () => _openAddExpense(context),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add Expense'),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddExpense(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddEditExpenseScreen(),
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, WidgetRef ref, double current) {
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

// ────────────────────────────────────────
// Search Delegate
// ────────────────────────────────────────

class _ExpenseSearchDelegate extends SearchDelegate<Expense?> {
  _ExpenseSearchDelegate(this.ref);

  final WidgetRef ref;

  @override
  String get searchFieldLabel => 'Search by note or category...';

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => BackButton(
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(
        child: Text('Type to search expenses...'),
      );
    }

    final allExpensesAsync = ref.watch(expensesProvider);
    return allExpensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (expenses) {
        final q = query.toLowerCase();
        final results = expenses.where((e) {
          final noteMatch = e.note?.toLowerCase().contains(q) ?? false;
          final categoryMatch =
              e.category.label.toLowerCase().contains(q);
          return noteMatch || categoryMatch;
        }).toList();

        if (results.isEmpty) {
          return const EmptyStateWidget(
            title: 'No results found',
            subtitle: 'Try a different search term',
            icon: Icons.search_off_rounded,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final expense = results[index];
            return ExpenseCard(
              expense: expense,
              onTap: () {
                close(context, expense);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      AddEditExpenseScreen(existingExpense: expense),
                ));
              },
            );
          },
        );
      },
    );
  }
}
