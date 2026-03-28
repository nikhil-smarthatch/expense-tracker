enum LoanType {
  borrow,
  lend;

  String get label {
    switch (this) {
      case LoanType.borrow:
        return 'Borrow';
      case LoanType.lend:
        return 'Lend';
    }
  }

  static LoanType fromString(String name) {
    return LoanType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => LoanType.borrow,
    );
  }
}
