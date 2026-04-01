/// Represents a reminder notification
class Reminder {
  final String id;
  final String title;
  final String message;
  final ReminderType type;
  final DateTime dateTime;
  final bool isActive;
  final String? relatedId; // ID of related expense, loan, or goal

  const Reminder({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.dateTime,
    this.isActive = true,
    this.relatedId,
  });

  Reminder copyWith({
    String? id,
    String? title,
    String? message,
    ReminderType? type,
    DateTime? dateTime,
    bool? isActive,
    String? relatedId,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
      isActive: isActive ?? this.isActive,
      relatedId: relatedId ?? this.relatedId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Reminder && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Reminder($title - $type)';
}

enum ReminderType {
  /// Bill payment reminder
  bill,

  /// Budget exceeded warning
  budgetWarning,

  /// Savings goal deadline approaching
  savingsGoal,

  /// Recurring income/expense due
  recurring,
}
