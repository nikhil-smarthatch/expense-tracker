/// Savings goal domain entity
class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.category,
    required this.priority,
    required this.createdDate,
    this.deadline,
    this.isCompleted = false,
    this.completedDate,
  });

  final String id;
  final String title;
  final String description;
  final double targetAmount;
  final double currentAmount;
  final String category; // e.g., "Emergency Fund", "Vacation", "House"
  final String priority; // e.g., "high", "medium", "low"
  final DateTime createdDate;
  final DateTime? deadline;
  final bool isCompleted;
  final DateTime? completedDate;

  /// Calculate remaining amount to save
  double get remainingAmount =>
      (targetAmount - currentAmount).clamp(0.0, double.infinity);

  /// Calculate progress percentage
  double get progressPercentage {
    if (targetAmount <= 0) return 0;
    return ((currentAmount / targetAmount) * 100).clamp(0.0, 100.0);
  }

  /// Calculate remaining months if deadline is set
  int? get remainingMonths {
    if (deadline == null || isCompleted) return null;
    final now = DateTime.now();
    if (now.isAfter(deadline!)) return 0;

    final difference = deadline!.difference(now);
    return (difference.inDays / 30).ceil();
  }

  /// Calculate required monthly savings if deadline is set
  double? get requiredMonthlySavings {
    if (deadline == null || remainingMonths == null || remainingMonths! <= 0) {
      return null;
    }
    if (remainingAmount <= 0) {
      return 0;
    }
    return remainingAmount / remainingMonths!;
  }

  /// Calculate status
  GoalStatus getStatus(double actualMonthlySavings) {
    if (isCompleted) return GoalStatus.completed;

    final required = requiredMonthlySavings;
    if (required == null) return GoalStatus.noDeadline;

    if (actualMonthlySavings >= required) return GoalStatus.onTrack;
    if (actualMonthlySavings >= required * 0.8) return GoalStatus.atRisk;
    return GoalStatus.behind;
  }

  /// Create a copy with updated fields
  SavingsGoal copyWith({
    String? id,
    String? title,
    String? description,
    double? targetAmount,
    double? currentAmount,
    String? category,
    String? priority,
    DateTime? createdDate,
    DateTime? deadline,
    bool? isCompleted,
    DateTime? completedDate,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      createdDate: createdDate ?? this.createdDate,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SavingsGoal && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SavingsGoal(id: $id, title: $title, target: $targetAmount, current: $currentAmount, progress: ${progressPercentage.toStringAsFixed(1)}%)';
}

/// Goal status enum
enum GoalStatus {
  noDeadline, // No deadline set
  onTrack, // Actual savings >= required savings
  atRisk, // Actual savings >= 80% of required
  behind, // Actual savings < 80% of required
  completed, // Goal completed
}
