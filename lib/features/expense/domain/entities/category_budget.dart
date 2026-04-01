import 'expense_category.dart';

/// Represents a budget limit for a specific expense category.
class CategoryBudget {
  const CategoryBudget({
    required this.category,
    required this.limitAmount,
    required this.month,
    required this.year,
  });

  /// The expense category this budget applies to
  final ExpenseCategory category;

  /// Monthly budget limit in rupees
  final double limitAmount;

  /// Month (1-12) this budget applies to
  final int month;

  /// Year this budget applies to
  final int year;

  /// Returns a copy with updated fields
  CategoryBudget copyWith({
    ExpenseCategory? category,
    double? limitAmount,
    int? month,
    int? year,
  }) {
    return CategoryBudget(
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryBudget &&
          other.category == category &&
          other.month == month &&
          other.year == year);

  @override
  int get hashCode => Object.hash(category, month, year);

  @override
  String toString() =>
      'CategoryBudget($category: ₹$limitAmount for $month/$year)';
}
