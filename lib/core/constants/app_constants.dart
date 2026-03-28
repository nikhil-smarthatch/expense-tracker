/// App-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'Expense Tracker';
  static const String hiveExpenseBox = 'expenses';
  static const String hiveBudgetBox = 'budgets';

  /// Default budget limit (monthly, in rupees)
  static const double defaultBudgetLimit = 30000.0;

  /// Number of recent transactions shown on dashboard
  static const int recentTransactionCount = 5;

  /// Currency symbol
  static const String currencySymbol = '₹';
}
