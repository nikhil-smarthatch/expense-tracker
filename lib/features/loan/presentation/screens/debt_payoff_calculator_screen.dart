import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../loan/domain/entities/loan.dart';
import '../../../loan/domain/usecases/debt_payoff_calculator.dart';
import '../../../loan/presentation/providers/loan_providers.dart';

/// Screen for debt payoff calculator with snowball/avalanche strategies
class DebtPayoffCalculatorScreen extends ConsumerStatefulWidget {
  const DebtPayoffCalculatorScreen({super.key});

  @override
  ConsumerState<DebtPayoffCalculatorScreen> createState() => _DebtPayoffCalculatorScreenState();
}

class _DebtPayoffCalculatorScreenState extends ConsumerState<DebtPayoffCalculatorScreen> {
  final _monthlyPaymentController = TextEditingController();
  final _extraPaymentController = TextEditingController();
  PayoffStrategy _selectedStrategy = PayoffStrategy.avalanche;
  PayoffPlan? _payoffPlan;
  StrategyComparison? _comparison;

  @override
  void dispose() {
    _monthlyPaymentController.dispose();
    _extraPaymentController.dispose();
    super.dispose();
  }

  void _calculatePayoff(List<Loan> loans) {
    final monthlyPayment = double.tryParse(_monthlyPaymentController.text) ?? 0;
    final extraPayment = double.tryParse(_extraPaymentController.text);

    if (monthlyPayment <= 0 || loans.isEmpty) return;

    final plan = DebtPayoffCalculator.calculatePayoffPlan(
      loans: loans.where((l) => !l.isSettled).toList(),
      monthlyPayment: monthlyPayment,
      strategy: _selectedStrategy,
      extraPayment: extraPayment,
    );

    final comparison = DebtPayoffCalculator.compareStrategies(
      loans: loans.where((l) => !l.isSettled).toList(),
      monthlyPayment: monthlyPayment,
      extraPayment: extraPayment,
    );

    setState(() {
      _payoffPlan = plan;
      _comparison = comparison;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loansAsync = ref.watch(loansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Payoff Calculator'),
      ),
      body: loansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (loans) {
          final activeLoans = loans.where((l) => !l.isSettled).toList();
          final totalDebt = activeLoans.fold(0.0, (sum, l) => sum + l.remainingAmount);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Debt Summary Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Total Debt',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.format(totalDebt),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${activeLoans.length} active loans/credit cards',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Input Section
                Text(
                  'Payment Plan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _monthlyPaymentController,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Payment Amount',
                    prefixText: '₹',
                    border: OutlineInputBorder(),
                    hintText: 'How much can you pay monthly?',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calculatePayoff(activeLoans),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _extraPaymentController,
                  decoration: const InputDecoration(
                    labelText: 'Extra Payment (Optional)',
                    prefixText: '₹',
                    border: OutlineInputBorder(),
                    hintText: 'Additional amount to pay each month',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calculatePayoff(activeLoans),
                ),
                const SizedBox(height: 16),
                
                // Strategy Selection
                Text(
                  'Payoff Strategy',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<PayoffStrategy>(
                  segments: const [
                    ButtonSegment(
                      value: PayoffStrategy.avalanche,
                      label: Text('Avalanche'),
                      icon: Icon(Icons.trending_down),
                    ),
                    ButtonSegment(
                      value: PayoffStrategy.snowball,
                      label: Text('Snowball'),
                      icon: Icon(Icons.ac_unit),
                    ),
                  ],
                  selected: {_selectedStrategy},
                  onSelectionChanged: (set) {
                    setState(() {
                      _selectedStrategy = set.first;
                    });
                    _calculatePayoff(activeLoans);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedStrategy == PayoffStrategy.avalanche
                      ? 'Pay highest interest first (saves most money)'
                      : 'Pay smallest balance first (quick wins)',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 24),

                // Results Section
                if (_payoffPlan != null) ...[
                  Text(
                    'Payoff Results',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildResultCard(_payoffPlan!),
                  const SizedBox(height: 16),
                  
                  // Strategy Comparison
                  if (_comparison != null) ...[
                    _buildComparisonCard(_comparison!),
                  ],
                  
                  // Loan Payoff Timeline
                  const SizedBox(height: 24),
                  Text(
                    'Payoff Timeline',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ..._payoffPlan!.loanPayoffs.map((loan) => _buildLoanPayoffCard(loan)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultCard(PayoffPlan plan) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildResultItem(
                    'Payoff Date',
                    '${plan.payoffDate.month}/${plan.payoffDate.year}',
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildResultItem(
                    'Total Months',
                    '${plan.totalMonths}',
                    Icons.schedule,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildResultItem(
                    'Total Paid',
                    CurrencyFormatter.format(plan.totalPaid),
                    Icons.payments,
                  ),
                ),
                Expanded(
                  child: _buildResultItem(
                    'Interest',
                    CurrencyFormatter.format(plan.totalInterest),
                    Icons.money_off,
                    valueColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, String value, IconData icon, {Color? valueColor}) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonCard(StrategyComparison comparison) {
    final savings = comparison.savingsWithAvalanche;
    final isAvalancheBetter = savings > 0;

    return Card(
      color: isAvalancheBetter ? Colors.blue.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Strategy Comparison',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('Avalanche', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${comparison.avalanchePlan.totalMonths} months'),
                      Text(
                        CurrencyFormatter.format(comparison.avalanchePlan.totalInterest),
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.compare_arrows),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Snowball', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${comparison.snowballPlan.totalMonths} months'),
                      Text(
                        CurrencyFormatter.format(comparison.snowballPlan.totalInterest),
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isAvalancheBetter) ...[
              const SizedBox(height: 8),
              Text(
                '💡 Avalanche saves you ${CurrencyFormatter.format(savings)} in interest!',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoanPayoffCard(LoanPayoffDetail loan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: loan.payoffMonth > 0 ? Colors.green.shade100 : Colors.grey.shade200,
          child: Icon(
            loan.payoffMonth > 0 ? Icons.check_circle : Icons.schedule,
            color: loan.payoffMonth > 0 ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(loan.loanName),
        subtitle: Text('Original: ${CurrencyFormatter.format(loan.originalBalance)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              loan.payoffMonth > 0 ? 'Month ${loan.payoffMonth}' : 'Paid Off',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: loan.payoffMonth > 0 ? Colors.blue : Colors.green,
              ),
            ),
            Text(
              'Interest: ${CurrencyFormatter.format(loan.totalInterestPaid)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
