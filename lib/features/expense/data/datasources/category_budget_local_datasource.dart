import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/category_budget.dart';
import '../models/category_budget_model.dart';
import '../../../../core/constants/app_constants.dart';

/// Local datasource for category budgets using Hive.
class CategoryBudgetLocalDatasource {
  /// Returns all saved category budgets
  List<CategoryBudgetModel> getAll() {
    final box = Hive.box<CategoryBudgetModel>(
      AppConstants.hiveCategoryBudgetBox,
    );
    return box.values.toList();
  }

  /// Gets budget for a specific category in a specific month/year
  CategoryBudgetModel? getByKey(String key) {
    final box = Hive.box<CategoryBudgetModel>(
      AppConstants.hiveCategoryBudgetBox,
    );
    return box.get(key);
  }

  /// Saves or updates a category budget
  Future<void> saveBudget(CategoryBudget budget) async {
    final box = Hive.box<CategoryBudgetModel>(
      AppConstants.hiveCategoryBudgetBox,
    );
    final key = '${budget.category.name}_${budget.month}_${budget.year}';
    final model = CategoryBudgetModel.fromEntity(budget);
    await box.put(key, model);
  }

  /// Deletes a category budget
  Future<void> deleteBudget(String key) async {
    final box = Hive.box<CategoryBudgetModel>(
      AppConstants.hiveCategoryBudgetBox,
    );
    await box.delete(key);
  }

  /// Clears all category budgets
  Future<void> clearAll() async {
    final box = Hive.box<CategoryBudgetModel>(
      AppConstants.hiveCategoryBudgetBox,
    );
    await box.clear();
  }
}
