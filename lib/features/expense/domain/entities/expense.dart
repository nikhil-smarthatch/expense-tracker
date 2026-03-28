import 'expense_category.dart';

/// Core domain entity for an expense.
/// This is the pure domain model – independent of any persistence layer.
class Expense {
  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
  });

  final String id;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? note;

  /// Returns a copy of this expense with updated fields.
  Expense copyWith({
    String? id,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? note,
    bool clearNote = false,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: clearNote ? null : (note ?? this.note),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Expense && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Expense(id: $id, amount: $amount, category: ${category.label}, date: $date)';
}
