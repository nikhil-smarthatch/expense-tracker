import 'package:hive/hive.dart';
import '../../domain/entities/category_budget.dart';
import '../../domain/entities/expense_category.dart';

part 'category_budget_model.g.dart';

/// Hive-persisted model for [CategoryBudget].
@HiveType(typeId: 4)
class CategoryBudgetModel extends HiveObject {
  CategoryBudgetModel();

  @HiveField(0)
  late String categoryName;

  @HiveField(1)
  late double limitAmount;

  @HiveField(2)
  late int month;

  @HiveField(3)
  late int year;

  /// Converts this model to a domain entity
  CategoryBudget toEntity() {
    return CategoryBudget(
      category: ExpenseCategory.values.firstWhere(
        (c) => c.name == categoryName,
        orElse: () => ExpenseCategory.others,
      ),
      limitAmount: limitAmount,
      month: month,
      year: year,
    );
  }

  /// Creates a model from a domain entity
  factory CategoryBudgetModel.fromEntity(CategoryBudget budget) {
    return CategoryBudgetModel()
      ..categoryName = budget.category.name
      ..limitAmount = budget.limitAmount
      ..month = budget.month
      ..year = budget.year;
  }
}
