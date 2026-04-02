/// Enum representing different savings goal categories
enum SavingsCategory {
  emergencyFund,
  vacation,
  house,
  education,
  car,
  business,
  retirement,
  other;

  /// Get the display label for the category
  String get label {
    switch (this) {
      case SavingsCategory.emergencyFund:
        return 'Emergency Fund';
      case SavingsCategory.vacation:
        return 'Vacation';
      case SavingsCategory.house:
        return 'House';
      case SavingsCategory.education:
        return 'Education';
      case SavingsCategory.car:
        return 'Car';
      case SavingsCategory.business:
        return 'Business';
      case SavingsCategory.retirement:
        return 'Retirement';
      case SavingsCategory.other:
        return 'Other';
    }
  }

  /// Convert string to enum value
  static SavingsCategory fromString(String value) {
    return SavingsCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SavingsCategory.other,
    );
  }
}

/// Enum representing priority levels for savings goals
enum Priority {
  high,
  medium,
  low;

  /// Get the display label for the priority
  String get label {
    switch (this) {
      case Priority.high:
        return 'High';
      case Priority.medium:
        return 'Medium';
      case Priority.low:
        return 'Low';
    }
  }

  /// Convert string to enum value
  static Priority fromString(String value) {
    return Priority.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Priority.medium,
    );
  }

  /// Get numeric value for comparison (higher = more important)
  int get value {
    switch (this) {
      case Priority.high:
        return 3;
      case Priority.medium:
        return 2;
      case Priority.low:
        return 1;
    }
  }
}
