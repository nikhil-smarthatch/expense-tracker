import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/loan.dart';
import '../../domain/entities/loan_type.dart';
import '../providers/loan_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/app_date_utils.dart';

class LoanDetailScreen extends ConsumerStatefulWidget {
  const LoanDetailScreen({super.key, required this.loan});
  final Loan loan;
  @override
  ConsumerState<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends ConsumerState<LoanDetailScreen> {
  late Loan _currentLoan;

  @override
  void initState() {
    super.initState();
    _currentLoan = widget.loan;
  }

  @override
  Widget build(BuildContext context) {
    // Listen to loansProvider to keep _currentLoan updated
    ref.listen<AsyncValue<List<Loan>>>(loansProvider, (prev, next) {
      if (next.hasValue) {
        final match = next.value!.where((l) => l.id == _currentLoan.id).toList();
        if (match.isNotEmpty) {
          setState(() => _currentLoan = match.first);
        }
      }
    });

    final repaymentsAsync = ref.watch(repaymentsProvider(_currentLoan.id));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Details'),
        actions: [
          if (!_currentLoan.isSettled)
            IconButton(
              icon: const Icon(Icons.check_circle_outline_rounded),
              tooltip: 'Mark as Settled',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Mark as Settled'),
                    content: const Text('Are you sure you want to mark this record as settled? The remaining balance will be set to zero.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Yes')),
                    ],
                  ),
                );
                if (confirm == true) {
                  final updated = _currentLoan.copyWith(remainingAmount: 0, isSettled: true);
                  ref.read(loansProvider.notifier).updateLoan(updated);
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Record'),
                  content: const Text('Delete this record completely?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                    FilledButton(style: FilledButton.styleFrom(backgroundColor: cs.error), onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                ref.read(loansProvider.notifier).deleteLoan(_currentLoan.id);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: _currentLoan.isSettled ? cs.surfaceContainerHighest : cs.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(_currentLoan.personName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        _currentLoan.type == LoanType.borrow ? 'You borrowed' : 'You lent',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _MetricInfo('Total', _currentLoan.totalAmount),
                          Container(width: 1, height: 40, color: cs.onSurface.withValues(alpha: 0.2)),
                          _MetricInfo('Remaining', _currentLoan.remainingAmount, color: _currentLoan.isSettled ? null : (_currentLoan.remainingAmount > 0 ? cs.primary : Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text('Repayment History', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          repaymentsAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            data: (repayments) {
              if (repayments.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No repayments made yet.')),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final r = repayments[index];
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.green.withValues(alpha: 0.2), child: const Icon(Icons.payment_rounded, color: Colors.green)),
                      title: Text(CurrencyFormatter.format(r.amount), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text(AppDateUtils.formatShortDate(r.date)),
                    );
                  },
                  childCount: repayments.length,
                ),
              );
            },
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      floatingActionButton: _currentLoan.isSettled ? null : FloatingActionButton.extended(
        heroTag: 'loan_repayment_fab_${_currentLoan.id}',
        onPressed: () => _showAddRepaymentDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Repayment'),
        shape: const StadiumBorder(),
      ),
    );
  }

  void _showAddRepaymentDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Repayment'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹ '),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Required';
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) return 'Invalid amount';
                  if (parsed > _currentLoan.remainingAmount) return 'Exceeds remaining \u{20B9}${_currentLoan.remainingAmount.toStringAsFixed(0)}';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final val = double.parse(controller.text.trim());
                ref.read(loansProvider.notifier).addRepayment(_currentLoan.id, val, DateTime.now());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add Payment'),
          ),
        ],
      ),
    );
  }
}

class _MetricInfo extends StatelessWidget {
  const _MetricInfo(this.label, this.amount, {this.color});
  final String label;
  final double amount;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(amount),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
