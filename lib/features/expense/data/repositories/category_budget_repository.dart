import '../../domain/entities/category_budget.dart';
import '../datasources/category_budget_local_datasource.dart';

/// Repository for category budgets
class CategoryBudgetRepository {
  final CategoryBudgetLocalDatasource _datasource;

  CategoryBudgetRepository(this._datasource);

  /// Gets all category budgets
  List<CategoryBudget> getAllBudgets() {
    return _datasource.getAll().map((model) => model.toEntity()).toList();
  }

  /// Gets budget for specific category in specific month/year
  CategoryBudget? getBudgetForCategory(
    String categoryName,
    int month,
    int year,
  ) {
    final key = '$categoryName${month}_$year';
    final model = _datasource.getByKey(key);
    return model?.toEntity();
  }

  /// Saves a category budget
  Future<void> saveBudget(CategoryBudget budget) =>
      _datasource.saveBudget(budget);

  /// Deletes a category budget
  Future<void> deleteBudget(String categoryName, int month, int year) {
    final key = '$categoryName${month}_$year';
    return _datasource.deleteBudget(key);
  }

  /// Clears all budgets
  Future<void> clearAll() => _datasource.clearAll();
}
