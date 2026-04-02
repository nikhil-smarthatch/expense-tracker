import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/usecases/budget_templates.dart';

/// Screen for budget templates and guidance with manual input
class BudgetTemplatesScreen extends ConsumerStatefulWidget {
  const BudgetTemplatesScreen({super.key});

  @override
  ConsumerState<BudgetTemplatesScreen> createState() => _BudgetTemplatesScreenState();
}

class _BudgetTemplatesScreenState extends ConsumerState<BudgetTemplatesScreen> {
  final _incomeController = TextEditingController();
  final _savingsController = TextEditingController();
  final _debtController = TextEditingController();

  double _monthlyIncome = 0;
  double _existingSavings = 0;
  double _debtPayments = 0;

  @override
  void dispose() {
    _incomeController.dispose();
    _savingsController.dispose();
    _debtController.dispose();
    super.dispose();
  }

  void _clearAll() {
    setState(() {
      _incomeController.clear();
      _savingsController.clear();
      _debtController.clear();
      _monthlyIncome = 0;
      _existingSavings = 0;
      _debtPayments = 0;
    });
  }

  void _showAnalysis() {
    if (_monthlyIncome <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your income to see analysis')),
      );
      return;
    }

    final totalCommitted = _debtPayments;
    final availableForBudget = _monthlyIncome - totalCommitted;
    final savingsRate = _monthlyIncome > 0 ? (_existingSavings / _monthlyIncome) * 100 : 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Budget Analysis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly Income: ${CurrencyFormatter.format(_monthlyIncome)}'),
            if (_debtPayments > 0)
              Text('Debt Payments: ${CurrencyFormatter.format(_debtPayments)}'),
            if (_existingSavings > 0)
              Text('Current Savings: ${CurrencyFormatter.format(_existingSavings)} (${savingsRate.toStringAsFixed(1)}% of income)'),
            const SizedBox(height: 16),
            Text('Available for Budget: ${CurrencyFormatter.format(availableForBudget)}'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _monthlyIncome > 0 ? (_debtPayments / _monthlyIncome) : 0,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            const SizedBox(height: 16),
            if (_debtPayments > _monthlyIncome * 0.5)
              const Text(
                '⚠️ Debt payments exceed 50% of income. Consider debt consolidation.',
                style: TextStyle(color: Colors.red),
              )
            else if (_existingSavings < _monthlyIncome * 3)
              const Text(
                '💡 Try to build an emergency fund of 3 months expenses.',
                style: TextStyle(color: Colors.blue),
              )
            else
              const Text(
                '✅ Good financial health! Consider increasing investments.',
                style: TextStyle(color: Colors.green),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear all',
            onPressed: _clearAll,
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'Analysis',
            onPressed: _showAnalysis,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Financial Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    // Monthly Income (Required)
                    TextField(
                      controller: _incomeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Monthly Income (₹) *',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                        hintText: 'Enter your monthly income',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _monthlyIncome = double.tryParse(value) ?? 0;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Existing Savings (Optional)
                    TextField(
                      controller: _savingsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Current Savings (Optional)',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                        hintText: 'Your existing savings amount',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _existingSavings = double.tryParse(value) ?? 0;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Debt Payments (Optional)
                    TextField(
                      controller: _debtController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Monthly Debt Payments (Optional)',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                        hintText: 'EMI, loans, credit card payments',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _debtPayments = double.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Show templates only when income > 0
            if (_monthlyIncome > 0) ...[
              // Summary
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        context,
                        'Income',
                        CurrencyFormatter.format(_monthlyIncome),
                        Colors.green,
                      ),
                      if (_debtPayments > 0)
                        _buildSummaryItem(
                          context,
                          'Debt',
                          CurrencyFormatter.format(_debtPayments),
                          Colors.orange,
                        ),
                      _buildSummaryItem(
                        context,
                        'To Budget',
                        CurrencyFormatter.format(_monthlyIncome - _debtPayments),
                        Colors.blue,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Recommended Template
              Text(
                'Recommended for You',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _buildTemplateCard(
                context,
                BudgetTemplate.getRecommendation(_monthlyIncome),
                _monthlyIncome - _debtPayments,
                isRecommended: true,
              ),

              const SizedBox(height: 24),

              // All Templates
              Text(
                'All Templates',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...BudgetTemplate.allTemplates.map((template) => _buildTemplateCard(
                context,
                template,
                _monthlyIncome - _debtPayments,
              )),
            ] else ...[
              // Empty state
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.calculate_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enter your income to see budget calculations',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    BudgetTemplate template,
    double income, {
    bool isRecommended = false,
  }) {
    final allocations = BudgetGuidance.calculateRecommendedBudget(
      monthlyIncome: _monthlyIncome,
      template: template,
      existingSavings: _existingSavings > 0 ? _existingSavings : null,
      debtPayments: _debtPayments > 0 ? _debtPayments : null,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRecommended ? 4 : 1,
      color: isRecommended ? Colors.blue.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    template.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isRecommended)
                  Chip(
                    label: const Text('Recommended'),
                    backgroundColor: Colors.green.shade100,
                    labelStyle: const TextStyle(color: Colors.green),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              template.description,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ...allocations.entries.map((entry) {
              final percentage = template.allocations[entry.key] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.key.substring(0, 1).toUpperCase() + entry.key.substring(1),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getCategoryColor(entry.key),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${percentage.toInt()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyFormatter.format(entry.value),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'needs':
      case 'housing':
      case 'food':
      case 'utilities':
        return Colors.blue;
      case 'wants':
      case 'entertainment':
        return Colors.purple;
      case 'savings':
        return Colors.green;
      case 'debt':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
