import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/loan.dart';
import '../../domain/entities/loan_type.dart';
import '../../domain/entities/repayment.dart';
import '../../data/repositories/loan_repository.dart';

final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  return LoanRepository();
});

class LoansNotifier extends AsyncNotifier<List<Loan>> {
  @override
  Future<List<Loan>> build() => ref.watch(loanRepositoryProvider).getAllLoans();

  Future<void> refresh() => update((_) => ref.read(loanRepositoryProvider).getAllLoans());

  Future<void> addLoan({
    required LoanType type,
    required String personName,
    required double totalAmount,
    required DateTime date,
    String? note,
  }) async {
    final loan = Loan(
      id: const Uuid().v4(),
      type: type,
      personName: personName,
      totalAmount: totalAmount,
      remainingAmount: totalAmount,
      date: date,
      note: note,
      isSettled: false,
    );
    await ref.read(loanRepositoryProvider).addLoan(loan);
    await refresh();
  }

  Future<void> updateLoan(Loan loan) async {
    await ref.read(loanRepositoryProvider).updateLoan(loan);
    await refresh();
  }

  Future<void> deleteLoan(String id) async {
    await ref.read(loanRepositoryProvider).deleteLoan(id);
    await refresh();
  }

  Future<void> addRepayment(String loanId, double amount, DateTime date) async {
    final loan = state.value?.firstWhere((l) => l.id == loanId);
    if (loan == null) return;
    
    final repayment = Repayment(
      id: const Uuid().v4(),
      loanId: loanId,
      amount: amount,
      date: date,
    );
    await ref.read(loanRepositoryProvider).addRepayment(repayment);
    
    final newRemaining = loan.remainingAmount - amount;
    final updatedLoan = loan.copyWith(
      remainingAmount: newRemaining < 0 ? 0 : newRemaining,
      isSettled: newRemaining <= 0,
    );
    await ref.read(loanRepositoryProvider).updateLoan(updatedLoan);
    
    ref.invalidate(repaymentsProvider(loanId));
    await refresh();
  }
}

final loansProvider = AsyncNotifierProvider<LoansNotifier, List<Loan>>(
  LoansNotifier.new,
);

final repaymentsProvider = FutureProvider.family<List<Repayment>, String>((ref, loanId) async {
  return ref.watch(loanRepositoryProvider).getRepaymentsForLoan(loanId);
});

final totalBorrowedProvider = Provider<double>((ref) {
  final loansAsync = ref.watch(loansProvider);
  return loansAsync.maybeWhen(
    data: (loans) => loans
        .where((l) => l.type == LoanType.borrow && !l.isSettled)
        .fold(0.0, (sum, l) => sum + l.remainingAmount),
    orElse: () => 0.0,
  );
});

final totalLentProvider = Provider<double>((ref) {
  final loansAsync = ref.watch(loansProvider);
  return loansAsync.maybeWhen(
    data: (loans) => loans
        .where((l) => l.type == LoanType.lend && !l.isSettled)
        .fold(0.0, (sum, l) => sum + l.remainingAmount),
    orElse: () => 0.0,
  );
});
