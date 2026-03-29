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
                      final formKey = GlobalKey<FormState>();
                      final controller = TextEditingController(text: totalBill.toStringAsFixed(2));
                      
                      final paymentRaw = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            title: const Text('Pay Credit Card Bill'),
                            content: Form(
                              key: formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Enter the amount you are paying today. We will systematically settle your oldest purchases first.'),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: controller,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Payment Amount',
                                      prefixText: '₹ ',
                                    ),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) return 'Amount is required';
                                      final p = double.tryParse(val);
                                      if (p == null) return 'Invalid number';
                                      if (p <= 0) return 'Must be greater than 0';
                                      if (p > totalBill + 0.01) return 'Cannot exceed total bill (${CurrencyFormatter.format(totalBill)})';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
                              FilledButton(
                                onPressed: () {
                                  if (formKey.currentState!.validate()) {
                                    Navigator.of(ctx).pop(controller.text);
                                  }
                                },
                                child: const Text('Pay Bill'),
                              ),
                            ],
                          );
                        },
                      );
                      
                      if (paymentRaw != null && paymentRaw.isNotEmpty) {
                        final parsed = double.tryParse(paymentRaw.trim());
                        if (parsed != null && parsed > 0) {
                          ref.read(expensesProvider.notifier).settleCreditCardBill(unpaidSpends, DateTime.now(), paymentAmount: parsed);
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Paid ${CurrencyFormatter.format(parsed)} successfully!')));
                        }
                      }
                    },
                    icon: const Icon(Icons.payment_rounded),
                    label: const Text('Pay Bill'),
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
