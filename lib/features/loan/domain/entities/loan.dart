import 'loan_type.dart';

class Loan {
  final String id;
  final LoanType type;
  final String personName;
  final double totalAmount;
  final double remainingAmount;
  final DateTime date;
  final String? note;
  final bool isSettled;

  const Loan({
    required this.id,
    required this.type,
    required this.personName,
    required this.totalAmount,
    required this.remainingAmount,
    required this.date,
    this.note,
    this.isSettled = false,
  });

  Loan copyWith({
    String? id,
    LoanType? type,
    String? personName,
    double? totalAmount,
    double? remainingAmount,
    DateTime? date,
    String? note,
    bool? isSettled,
  }) {
    return Loan(
      id: id ?? this.id,
      type: type ?? this.type,
      personName: personName ?? this.personName,
      totalAmount: totalAmount ?? this.totalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      date: date ?? this.date,
      note: note ?? this.note,
      isSettled: isSettled ?? this.isSettled,
    );
  }
}
