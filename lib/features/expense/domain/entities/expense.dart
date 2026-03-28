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
    this.isIncome = false,
    this.receiptPath,
    this.isCreditCard = false,
    this.isCreditCardSettled = false,
  });

  final String id;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? note;
  final bool isIncome;
  final String? receiptPath;
  final bool isCreditCard;
  final bool isCreditCardSettled;

  /// Returns a copy of this expense with updated fields.
  Expense copyWith({
    String? id,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? note,
    bool clearNote = false,
    bool? isIncome,
    String? receiptPath,
    bool clearReceipt = false,
    bool? isCreditCard,
    bool? isCreditCardSettled,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: clearNote ? null : (note ?? this.note),
      isIncome: isIncome ?? this.isIncome,
      receiptPath: clearReceipt ? null : (receiptPath ?? this.receiptPath),
      isCreditCard: isCreditCard ?? this.isCreditCard,
      isCreditCardSettled: isCreditCardSettled ?? this.isCreditCardSettled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Expense && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Expense(id: $id, amount: $amount, isIncome: $isIncome, category: ${category.label}, date: $date)';
}
