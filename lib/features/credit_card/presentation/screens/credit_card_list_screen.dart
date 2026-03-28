import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../expense/presentation/providers/expense_providers.dart';
import '../../../expense/presentation/widgets/expense_card.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../expense/presentation/screens/add_edit_expense_screen.dart';

class CreditCardListScreen extends ConsumerWidget {
  const CreditCardListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unpaidSpends = ref.watch(unpaidCreditCardSpendsProvider);
    final totalBill = ref.watch(totalUnpaidCreditCardProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Credit Cards')),
      body: Column(
        children: [
          // Total Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: cs.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Outstanding Bill', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(CurrencyFormatter.format(totalBill), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: unpaidSpends.isEmpty ? null : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Pay Credit Card Bill'),
                          content: Text('Settle ${unpaidSpends.length} expenses totaling ${CurrencyFormatter.format(totalBill)}? This will register a single cash expense covering this entire amount.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Pay Bill')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        ref.read(expensesProvider.notifier).settleCreditCardBill(unpaidSpends, DateTime.now());
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credit card bill successfully paid!')));
                      }
                    },
                    icon: const Icon(Icons.payment_rounded),
                    label: const Text('Pay Full Bill'),
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: unpaidSpends.isEmpty
                ? const Center(child: Text('No outstanding credit card spends.'))
                : RefreshIndicator(
                    onRefresh: () => ref.refresh(expensesProvider.future),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: unpaidSpends.length,
                      itemBuilder: (context, index) {
                        final expense = unpaidSpends[index];
                        return ExpenseCard(
                          expense: expense,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => AddEditExpenseScreen(existingExpense: expense)),
                          ),
                          onDelete: () => ref.read(expensesProvider.notifier).deleteExpense(expense.id),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
