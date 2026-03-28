class Repayment {
  final String id;
  final String loanId;
  final double amount;
  final DateTime date;

  const Repayment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.date,
  });
}
