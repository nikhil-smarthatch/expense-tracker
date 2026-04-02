import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../expense/domain/entities/expense.dart';
import '../../../expense/presentation/providers/expense_providers.dart';
import '../../../loan/presentation/providers/loan_providers.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Comprehensive search screen for all transactions
class TransactionSearchScreen extends ConsumerStatefulWidget {
  const TransactionSearchScreen({super.key});

  @override
  ConsumerState<TransactionSearchScreen> createState() => _TransactionSearchScreenState();
}

class _TransactionSearchScreenState extends ConsumerState<TransactionSearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minAmount;
  double? _maxAmount;
  String? _selectedType; // 'all', 'income', 'expense', 'loan'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SearchResult> _performSearch(
    List<Expense> expenses,
    List<dynamic> loans,
  ) {
    final results = <SearchResult>[];
    final query = _query.toLowerCase().trim();

    // Search expenses
    for (final expense in expenses) {
      // Text search
      final bool matchesQuery = query.isEmpty ||
          expense.note?.toLowerCase().contains(query) == true ||
          expense.category.label.toLowerCase().contains(query) ||
          expense.amount.toString().contains(query);

      // Type filter
      final bool matchesType = _selectedType == null ||
          _selectedType == 'all' ||
          (_selectedType == 'income' && expense.isIncome) ||
          (_selectedType == 'expense' && !expense.isIncome);

      // Date range filter
      bool matchesDate = true;
      if (_startDate != null && expense.date.isBefore(_startDate!)) {
        matchesDate = false;
      }
      if (_endDate != null && expense.date.isAfter(_endDate!)) {
        matchesDate = false;
      }

      // Amount range filter
      bool matchesAmount = true;
      if (_minAmount != null && expense.amount < _minAmount!) {
        matchesAmount = false;
      }
      if (_maxAmount != null && expense.amount > _maxAmount!) {
        matchesAmount = false;
      }

      if (matchesQuery && matchesType && matchesDate && matchesAmount) {
        results.add(SearchResult(
          id: expense.id,
          title: expense.note ?? expense.category.label,
          subtitle: expense.category.label,
          amount: expense.amount,
          date: expense.date,
          type: expense.isIncome ? 'income' : 'expense',
          entity: expense,
        ));
      }
    }

    // Sort by date (newest first)
    results.sort((a, b) => b.date.compareTo(a.date));

    return results;
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Results',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              
              // Transaction Type
              Text('Transaction Type', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip('All', 'all', setState),
                  _buildFilterChip('Income', 'income', setState),
                  _buildFilterChip('Expense', 'expense', setState),
                ],
              ),
              const SizedBox(height: 16),
              
              // Date Range
              Text('Date Range', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _startDate = date);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_startDate != null
                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                          : 'From'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_endDate != null
                          ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                          : 'To'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Amount Range
              Text('Amount Range', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Min Amount',
                        prefixText: '₹',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() => _minAmount = double.tryParse(value));
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Max Amount',
                        prefixText: '₹',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() => _maxAmount = double.tryParse(value));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Apply/Clear buttons
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                        _minAmount = null;
                        _maxAmount = null;
                        _selectedType = null;
                      });
                      this.setState(() {});
                      Navigator.pop(context);
                    },
                    child: const Text('Clear All'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      this.setState(() {});
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Filters'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, StateSetter setState) {
    final isSelected = _selectedType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedType = selected ? value : null);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);
    final loansAsync = ref.watch(loansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by note, category, or amount...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          
          // Results
          Expanded(
            child: expensesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (expenses) => loansAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (loans) {
                  final results = _performSearch(expenses, loans);
                  
                  if (results.isEmpty && _query.isNotEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No results found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final result = results[index];
                      final isIncome = result.type == 'income';
                      final isExpense = result.type == 'expense';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isIncome
                              ? Colors.green.withAlpha(51)
                              : isExpense
                                  ? Colors.red.withAlpha(51)
                                  : Colors.blue.withAlpha(51),
                          child: Icon(
                            isIncome
                                ? Icons.arrow_downward
                                : isExpense
                                    ? Icons.arrow_upward
                                    : Icons.account_balance,
                            color: isIncome
                                ? Colors.green
                                : isExpense
                                    ? Colors.red
                                    : Colors.blue,
                          ),
                        ),
                        title: Text(result.title),
                        subtitle: Text(
                          '${result.subtitle} • ${result.date.day}/${result.date.month}/${result.date.year}',
                        ),
                        trailing: Text(
                          CurrencyFormatter.format(result.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                        onTap: () {
                          // Navigate to detail view
                        },
                      );
                    },
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

/// Search result model
class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;
  final String type; // 'income', 'expense', 'loan'
  final dynamic entity;

  SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.type,
    required this.entity,
  });
}
