import 'package:flutter/material.dart';

/// Expense category enumeration with metadata.
enum ExpenseCategory {
  food,
  travel,
  bills,
  shopping,
  salary,
  others;

  String get label {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.bills:
        return 'Bills';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.salary:
        return 'Salary';
      case ExpenseCategory.others:
        return 'Others';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.travel:
        return Icons.flight_rounded;
      case ExpenseCategory.bills:
        return Icons.receipt_long_rounded;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.salary:
        return Icons.monetization_on_rounded;
      case ExpenseCategory.others:
        return Icons.category_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return const Color(0xFFFF6B6B);
      case ExpenseCategory.travel:
        return const Color(0xFF4ECDC4);
      case ExpenseCategory.bills:
        return const Color(0xFFFFBE0B);
      case ExpenseCategory.shopping:
        return const Color(0xFF9D4EDD);
      case ExpenseCategory.salary:
        return const Color(0xFF06D6A0);
      case ExpenseCategory.others:
        return const Color(0xFF118AB2);
    }
  }

  /// Maps the enum name (string) to enum value for Hive storage.
  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExpenseCategory.others,
    );
  }
}
