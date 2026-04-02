import '../entities/loan.dart';

/// Debt payoff strategy types
enum PayoffStrategy {
  snowball,    // Pay smallest debts first (psychological wins)
  avalanche,   // Pay highest interest first (mathematically optimal)
  highestBalance, // Pay highest balance first
}

/// Extension to add interest rate to Loan (would need to be added to Loan entity)
extension LoanInterestExtension on Loan {
  // Default interest rate for calculations (if not stored in Loan)
  double get estimatedInterestRate {
    // In real implementation, this would come from the Loan entity
    return 0.12; // 12% default assumption
  }
}

/// Calculator for debt payoff strategies
class DebtPayoffCalculator {
  /// Calculate payoff plan using specified strategy
  static PayoffPlan calculatePayoffPlan({
    required List<Loan> loans,
    required double monthlyPayment,
    required PayoffStrategy strategy,
    double? extraPayment,
  }) {
    if (monthlyPayment <= 0) {
      return PayoffPlan.empty();
    }

    // Sort loans based on strategy
    final List<Loan> sortedLoans = _sortLoansByStrategy(loans, strategy);
    
    final List<MonthlyPayment> paymentSchedule = <MonthlyPayment>[];
    final Map<String, List<double>> remainingBalances = <String, List<double>>{};
    
    // Initialize tracking for each loan
    final Map<String, double> currentBalances = <String, double>{};
    for (final Loan loan in sortedLoans) {
      currentBalances[loan.id] = loan.remainingAmount;
      remainingBalances[loan.id] = [loan.remainingAmount];
    }

    int month = 0;
    double totalPaid = 0.0;
    double totalInterest = 0.0;
    const int maxMonths = 360; // 30 years safety limit

    while (currentBalances.values.any((b) => b > 0) && month < maxMonths) {
      month++;
      double availablePayment = monthlyPayment + (extraPayment ?? 0);
      double monthlyInterest = 0.0;

      // Calculate interest for each loan
      for (final Loan loan in sortedLoans) {
        final double balance = currentBalances[loan.id] ?? 0;
        if (balance > 0) {
          final double interest = balance * (loan.estimatedInterestRate / 12);
          monthlyInterest += interest;
          currentBalances[loan.id] = balance + interest;
        }
      }

      totalInterest += monthlyInterest;

      // Apply payments using strategy
      for (final loan in sortedLoans) {
        final balance = currentBalances[loan.id] ?? 0;
        if (balance > 0 && availablePayment > 0) {
          final payment = balance < availablePayment ? balance : availablePayment;
          currentBalances[loan.id] = balance - payment;
          availablePayment -= payment;
          totalPaid += payment;

          // Record balance after payment
          remainingBalances[loan.id]!.add(currentBalances[loan.id]!);
        }
      }

      paymentSchedule.add(MonthlyPayment(
        month: month,
        totalPayment: monthlyPayment + (extraPayment ?? 0),
        interestPaid: monthlyInterest,
        principalPaid: (monthlyPayment + (extraPayment ?? 0)) - monthlyInterest,
        remainingBalance: currentBalances.values.fold(0, (sum, b) => sum + b),
      ));
    }

    // Calculate individual loan payoff details
    final loanPayoffs = _calculateLoanPayoffs(
      sortedLoans,
      remainingBalances,
      paymentSchedule,
    );

    return PayoffPlan(
      strategy: strategy,
      totalMonths: month,
      totalPaid: totalPaid + totalInterest,
      totalInterest: totalInterest,
      monthlyPayment: monthlyPayment,
      paymentSchedule: paymentSchedule,
      loanPayoffs: loanPayoffs,
      payoffDate: DateTime.now().add(Duration(days: month * 30)),
    );
  }

  /// Sort loans based on payoff strategy
  static List<Loan> _sortLoansByStrategy(List<Loan> loans, PayoffStrategy strategy) {
    final sorted = List<Loan>.from(loans)
      ..sort((a, b) {
        switch (strategy) {
          case PayoffStrategy.snowball:
            // Smallest balance first
            return a.remainingAmount.compareTo(b.remainingAmount);
          case PayoffStrategy.avalanche:
            // Highest interest rate first (using estimated)
            return b.estimatedInterestRate.compareTo(a.estimatedInterestRate);
          case PayoffStrategy.highestBalance:
            // Highest balance first
            return b.remainingAmount.compareTo(a.remainingAmount);
        }
      });
    return sorted;
  }

  /// Calculate payoff details for each loan
  static List<LoanPayoffDetail> _calculateLoanPayoffs(
    List<Loan> loans,
    Map<String, List<double>> balanceHistory,
    List<MonthlyPayment> schedule,
  ) {
    final details = <LoanPayoffDetail>[];

    for (final loan in loans) {
      final balances = balanceHistory[loan.id] ?? [];
      var payoffMonth = 0;
      
      for (var i = 0; i < balances.length; i++) {
        if (balances[i] <= 0) {
          payoffMonth = i;
          break;
        }
      }

      details.add(LoanPayoffDetail(
        loanId: loan.id,
        loanName: loan.personName,
        originalBalance: loan.totalAmount,
        payoffMonth: payoffMonth,
        totalInterestPaid: _calculateInterestForLoan(loan, payoffMonth, balances),
      ));
    }

    return details;
  }

  static double _calculateInterestForLoan(
    Loan loan,
    int payoffMonth,
    List<double> balanceHistory,
  ) {
    var totalInterest = 0.0;
    for (var i = 0; i < payoffMonth && i < balanceHistory.length - 1; i++) {
      final balance = balanceHistory[i];
      final nextBalance = balanceHistory[i + 1];
      // Rough interest estimate based on balance change
      if (nextBalance < balance) {
        totalInterest += (balance - nextBalance) * 0.01; // Simplified
      }
    }
    return totalInterest;
  }

  /// Compare different payoff strategies
  static StrategyComparison compareStrategies({
    required List<Loan> loans,
    required double monthlyPayment,
    double? extraPayment,
  }) {
    final snowball = calculatePayoffPlan(
      loans: loans,
      monthlyPayment: monthlyPayment,
      strategy: PayoffStrategy.snowball,
      extraPayment: extraPayment,
    );

    final avalanche = calculatePayoffPlan(
      loans: loans,
      monthlyPayment: monthlyPayment,
      strategy: PayoffStrategy.avalanche,
      extraPayment: extraPayment,
    );

    return StrategyComparison(
      snowballPlan: snowball,
      avalanchePlan: avalanche,
      recommended: avalanche.totalInterest < snowball.totalInterest
          ? PayoffStrategy.avalanche
          : PayoffStrategy.snowball,
      savingsWithAvalanche: snowball.totalInterest - avalanche.totalInterest,
    );
  }

  /// Calculate how extra payments affect payoff
  static ExtraPaymentImpact calculateExtraPaymentImpact({
    required List<Loan> loans,
    required double monthlyPayment,
    required double extraPayment,
    required PayoffStrategy strategy,
  }) {
    final basePlan = calculatePayoffPlan(
      loans: loans,
      monthlyPayment: monthlyPayment,
      strategy: strategy,
    );

    final withExtraPlan = calculatePayoffPlan(
      loans: loans,
      monthlyPayment: monthlyPayment,
      strategy: strategy,
      extraPayment: extraPayment,
    );

    return ExtraPaymentImpact(
      monthsSaved: basePlan.totalMonths - withExtraPlan.totalMonths,
      interestSaved: basePlan.totalInterest - withExtraPlan.totalInterest,
      totalExtraPaid: extraPayment * withExtraPlan.totalMonths,
      newPayoffDate: withExtraPlan.payoffDate,
    );
  }
}

/// Payoff plan result
class PayoffPlan {
  final PayoffStrategy strategy;
  final int totalMonths;
  final double totalPaid;
  final double totalInterest;
  final double monthlyPayment;
  final List<MonthlyPayment> paymentSchedule;
  final List<LoanPayoffDetail> loanPayoffs;
  final DateTime payoffDate;

  PayoffPlan({
    required this.strategy,
    required this.totalMonths,
    required this.totalPaid,
    required this.totalInterest,
    required this.monthlyPayment,
    required this.paymentSchedule,
    required this.loanPayoffs,
    required this.payoffDate,
  });

  factory PayoffPlan.empty() => PayoffPlan(
    strategy: PayoffStrategy.avalanche,
    totalMonths: 0,
    totalPaid: 0,
    totalInterest: 0,
    monthlyPayment: 0,
    paymentSchedule: [],
    loanPayoffs: [],
    payoffDate: DateTime.now(),
  );

  double get totalPrincipal => totalPaid - totalInterest;
}

/// Monthly payment breakdown
class MonthlyPayment {
  final int month;
  final double totalPayment;
  final double interestPaid;
  final double principalPaid;
  final double remainingBalance;

  MonthlyPayment({
    required this.month,
    required this.totalPayment,
    required this.interestPaid,
    required this.principalPaid,
    required this.remainingBalance,
  });
}

/// Individual loan payoff details
class LoanPayoffDetail {
  final String loanId;
  final String loanName;
  final double originalBalance;
  final int payoffMonth;
  final double totalInterestPaid;

  LoanPayoffDetail({
    required this.loanId,
    required this.loanName,
    required this.originalBalance,
    required this.payoffMonth,
    required this.totalInterestPaid,
  });
}

/// Comparison between strategies
class StrategyComparison {
  final PayoffPlan snowballPlan;
  final PayoffPlan avalanchePlan;
  final PayoffStrategy recommended;
  final double savingsWithAvalanche;

  StrategyComparison({
    required this.snowballPlan,
    required this.avalanchePlan,
    required this.recommended,
    required this.savingsWithAvalanche,
  });
}

/// Impact of making extra payments
class ExtraPaymentImpact {
  final int monthsSaved;
  final double interestSaved;
  final double totalExtraPaid;
  final DateTime newPayoffDate;

  ExtraPaymentImpact({
    required this.monthsSaved,
    required this.interestSaved,
    required this.totalExtraPaid,
    required this.newPayoffDate,
  });
}
