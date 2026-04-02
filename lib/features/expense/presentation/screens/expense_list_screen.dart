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
import '../../../search/presentation/screens/transaction_search_screen.dart';
import 'budget_templates_screen.dart';

enum ExpenseMenuAction { categoryBudgets, setBudget, budgetTemplates }

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
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TransactionSearchScreen()),
            ),
            tooltip: 'Search All Transactions',
          ),
          PopupMenuButton<ExpenseMenuAction>(
            onSelected: (action) {
              if (action == ExpenseMenuAction.categoryBudgets) {
                showDialog(
                  context: context,
                  builder: (_) => const CategoryBudgetDialog(),
                );
              } else if (action == ExpenseMenuAction.setBudget) {
                _showBudgetDialog(context, ref, budgetLimit);
              } else if (action == ExpenseMenuAction.budgetTemplates) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BudgetTemplatesScreen()),
                );
              }
            },
            itemBuilder: (context) => [
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
              const PopupMenuItem(
                value: ExpenseMenuAction.budgetTemplates,
                child: ListTile(
                  leading: Icon(Icons.account_balance_wallet_rounded),
                  title: Text('Budget Templates'),
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
