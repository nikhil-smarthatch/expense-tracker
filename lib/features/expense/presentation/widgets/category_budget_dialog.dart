import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/expense_category.dart';
import '../providers/category_budget_providers.dart';

/// Dialog for setting category-wise budgets
class CategoryBudgetDialog extends ConsumerStatefulWidget {
  const CategoryBudgetDialog({super.key});

  @override
  ConsumerState<CategoryBudgetDialog> createState() =>
      _CategoryBudgetDialogState();
}

class _CategoryBudgetDialogState extends ConsumerState<CategoryBudgetDialog> {
  late Map<ExpenseCategory, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _controllers = {};
    for (final category in ExpenseCategory.values) {
      final budget = ref.read(categoryBudgetProvider(category));
      _controllers[category] = TextEditingController(
        text: budget != null ? budget.toStringAsFixed(0) : '',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveBudgets() async {
    for (final entry in _controllers.entries) {
      final category = entry.key;
      final controller = entry.value;
      final amount = double.tryParse(controller.text.trim());

      if (amount != null && amount > 0) {
        await ref
            .read(categoryBudgetNotifierProvider.notifier)
            .setBudget(category, amount);
      } else if (controller.text.trim().isEmpty) {
        // If empty, remove the budget for this category
        await ref
            .read(categoryBudgetNotifierProvider.notifier)
            .removeBudget(category);
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category budgets updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Category Budgets'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Set monthly budget limits per category. Leave blank to remove.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              ...ExpenseCategory.values.map((category) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: category.color.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          category.icon,
                          color: category.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controllers[category],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: false,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Budget for ${category.label}',
                            prefixText: '₹ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveBudgets,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
