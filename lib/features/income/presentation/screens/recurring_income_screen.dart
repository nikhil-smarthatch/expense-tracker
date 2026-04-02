import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for managing recurring income settings
final recurringIncomeSettingsProvider = StateNotifierProvider<RecurringIncomeNotifier, List<RecurringIncome>>((ref) {
  return RecurringIncomeNotifier();
});

/// Model for recurring income configuration
class RecurringIncome {
  final String id;
  final String source; // e.g., "Salary", "Freelance", "Rental"
  final double amount;
  final String recurrenceType; // 'monthly', 'weekly', 'biweekly'
  final int dayOfMonth; // For monthly: 1-31
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? note;

  RecurringIncome({
    required this.id,
    required this.source,
    required this.amount,
    required this.recurrenceType,
    required this.dayOfMonth,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.note,
  });

  RecurringIncome copyWith({
    String? id,
    String? source,
    double? amount,
    String? recurrenceType,
    int? dayOfMonth,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? note,
  }) {
    return RecurringIncome(
      id: id ?? this.id,
      source: source ?? this.source,
      amount: amount ?? this.amount,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      note: note ?? this.note,
    );
  }

  /// Get next occurrence date
  DateTime getNextOccurrence() {
    final now = DateTime.now();
    
    switch (recurrenceType) {
      case 'monthly':
        var next = DateTime(now.year, now.month, dayOfMonth);
        if (next.isBefore(now)) {
          next = DateTime(now.year, now.month + 1, dayOfMonth);
        }
        return next;
        
      case 'weekly':
        final next = now.add(const Duration(days: 7));
        return next;
        
      case 'biweekly':
        final next = now.add(const Duration(days: 14));
        return next;
        
      default:
        return now;
    }
  }
}

/// Notifier for managing recurring income
class RecurringIncomeNotifier extends StateNotifier<List<RecurringIncome>> {
  RecurringIncomeNotifier() : super([]);

  void addRecurringIncome(RecurringIncome income) {
    state = [...state, income];
  }

  void updateRecurringIncome(RecurringIncome income) {
    state = state.map((i) => i.id == income.id ? income : i).toList();
  }

  void deleteRecurringIncome(String id) {
    state = state.where((i) => i.id != id).toList();
  }

  void toggleActive(String id) {
    state = state.map((i) {
      if (i.id == id) {
        return i.copyWith(isActive: !i.isActive);
      }
      return i;
    }).toList();
  }

  /// Get projected income for a month
  double getProjectedMonthlyIncome() {
    return state.where((i) => i.isActive).fold(0.0, (sum, income) {
      switch (income.recurrenceType) {
        case 'monthly':
          return sum + income.amount;
        case 'weekly':
          return sum + (income.amount * 4); // ~4 weeks per month
        case 'biweekly':
          return sum + (income.amount * 2); // ~2 payments per month
        default:
          return sum;
      }
    });
  }

  /// Get incomes due today
  List<RecurringIncome> getIncomesDueToday() {
    final now = DateTime.now();
    return state.where((income) {
      if (!income.isActive) return false;
      
      switch (income.recurrenceType) {
        case 'monthly':
          return now.day == income.dayOfMonth;
        case 'weekly':
        case 'biweekly':
          // Check if today matches the start date pattern
          final daysSinceStart = now.difference(income.startDate).inDays;
          final interval = income.recurrenceType == 'weekly' ? 7 : 14;
          return daysSinceStart % interval == 0;
        default:
          return false;
      }
    }).toList();
  }
}

/// Screen for managing recurring income
class RecurringIncomeScreen extends ConsumerWidget {
  const RecurringIncomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringIncomes = ref.watch(recurringIncomeSettingsProvider);
    final projectedIncome = ref.read(recurringIncomeSettingsProvider.notifier).getProjectedMonthlyIncome();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Income'),
      ),
      body: Column(
        children: [
          // Projected Income Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Projected Monthly Income',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${projectedIncome.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Recurring Income List
          Expanded(
            child: recurringIncomes.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.repeat, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No recurring income set up'),
                        Text(
                          'Add your salary or other regular income',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: recurringIncomes.length,
                    itemBuilder: (context, index) {
                      final income = recurringIncomes[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: income.isActive 
                              ? Colors.green.withAlpha(51)
                              : Colors.grey.withAlpha(51),
                          child: Icon(
                            Icons.repeat,
                            color: income.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                        title: Text(income.source),
                        subtitle: Text(
                          '${income.recurrenceType} • Day ${income.dayOfMonth}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${income.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Switch(
                              value: income.isActive,
                              onChanged: (_) {
                                ref.read(recurringIncomeSettingsProvider.notifier)
                                    .toggleActive(income.id);
                              },
                            ),
                          ],
                        ),
                        onTap: () => _showEditDialog(context, ref, income),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    _showIncomeDialog(context, ref, null);
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, RecurringIncome income) {
    _showIncomeDialog(context, ref, income);
  }

  void _showIncomeDialog(BuildContext context, WidgetRef ref, RecurringIncome? existing) {
    final sourceController = TextEditingController(text: existing?.source ?? '');
    final amountController = TextEditingController(
      text: existing?.amount.toString() ?? '',
    );
    String recurrenceType = existing?.recurrenceType ?? 'monthly';
    int dayOfMonth = existing?.dayOfMonth ?? 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? 'Add Recurring Income' : 'Edit Recurring Income'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: sourceController,
                  decoration: const InputDecoration(
                    labelText: 'Source (e.g., Salary)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: recurrenceType,
                  decoration: const InputDecoration(
                    labelText: 'Recurrence',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'biweekly', child: Text('Bi-weekly')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => recurrenceType = value);
                    }
                  },
                ),
                if (recurrenceType == 'monthly') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: dayOfMonth,
                    decoration: const InputDecoration(
                      labelText: 'Day of Month',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(31, (i) => i + 1)
                        .map((day) => DropdownMenuItem(
                              value: day,
                              child: Text(day.toString()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => dayOfMonth = value);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0 || sourceController.text.isEmpty) return;

                final income = RecurringIncome(
                  id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  source: sourceController.text,
                  amount: amount,
                  recurrenceType: recurrenceType,
                  dayOfMonth: dayOfMonth,
                  startDate: DateTime.now(),
                  isActive: true,
                );

                if (existing == null) {
                  ref.read(recurringIncomeSettingsProvider.notifier)
                      .addRecurringIncome(income);
                } else {
                  ref.read(recurringIncomeSettingsProvider.notifier)
                      .updateRecurringIncome(income);
                }

                Navigator.pop(context);
              },
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
