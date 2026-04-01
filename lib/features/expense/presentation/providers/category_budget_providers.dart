import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category_budget.dart';
import '../../domain/entities/expense_category.dart';
import '../../data/repositories/category_budget_repository.dart';
import '../../data/datasources/category_budget_local_datasource.dart';

// Data source provider
final categoryBudgetDatasourceProvider =
    Provider<CategoryBudgetLocalDatasource>((ref) {
  return CategoryBudgetLocalDatasource();
});

// Repository provider
final categoryBudgetRepositoryProvider =
    Provider<CategoryBudgetRepository>((ref) {
  final datasource = ref.watch(categoryBudgetDatasourceProvider);
  return CategoryBudgetRepository(datasource);
});

// All category budgets for current month
final categoryBudgetsProvider = Provider<List<CategoryBudget>>((ref) {
  final repository = ref.watch(categoryBudgetRepositoryProvider);
  final now = DateTime.now();
  final allBudgets = repository.getAllBudgets();

  return allBudgets
      .where((b) => b.month == now.month && b.year == now.year)
      .toList();
});

// Get budget for specific category in current month
final categoryBudgetProvider =
    Provider.family<double?, ExpenseCategory>((ref, category) {
  final budgets = ref.watch(categoryBudgetsProvider);
  final budget = budgets.firstWhere((b) => b.category == category,
      orElse: () => CategoryBudget(
            category: category,
            limitAmount: 0,
            month: 0,
            year: 0,
          ));
  return budget.limitAmount > 0 ? budget.limitAmount : null;
});

// Get map of all category budgets (for compatibility)
final categoryBudgetVisibleProvider =
    Provider<Map<ExpenseCategory, double>>((ref) {
  final budgets = ref.watch(categoryBudgetsProvider);
  final map = <ExpenseCategory, double>{};
  for (final budget in budgets) {
    map[budget.category] = budget.limitAmount;
  }
  return map;
});

// Notifier for managing category budgets
class CategoryBudgetNotifier extends StateNotifier<AsyncValue<void>> {
  final CategoryBudgetRepository _repository;

  CategoryBudgetNotifier(this._repository) : super(const AsyncValue.data(null));

  /// Sets or updates budget for a category (current month)
  Future<void> setBudget(ExpenseCategory category, double amount) async {
    final now = DateTime.now();
    final budget = CategoryBudget(
      category: category,
      limitAmount: amount,
      month: now.month,
      year: now.year,
    );
    await _repository.saveBudget(budget);
  }

  /// Removes budget for a category (current month)
  Future<void> removeBudget(ExpenseCategory category) async {
    final now = DateTime.now();
    await _repository.deleteBudget(category.name, now.month, now.year);
  }

  /// Clears all category budgets
  Future<void> clearAll() async {
    await _repository.clearAll();
  }
}

final categoryBudgetNotifierProvider =
    StateNotifierProvider<CategoryBudgetNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(categoryBudgetRepositoryProvider);
  return CategoryBudgetNotifier(repository);
});
