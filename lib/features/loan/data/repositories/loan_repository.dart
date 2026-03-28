import 'package:hive/hive.dart';
import '../models/loan_model.dart';
import '../models/repayment_model.dart';
import '../../domain/entities/loan.dart';
import '../../domain/entities/repayment.dart';
import '../../../../core/constants/app_constants.dart';

class LoanRepository {
  final Box<LoanModel> _loansBox = Hive.box<LoanModel>(AppConstants.hiveLoansBox);
  final Box<RepaymentModel> _repaymentsBox = Hive.box<RepaymentModel>(AppConstants.hiveRepaymentsBox);

  // Loans
  Future<List<Loan>> getAllLoans() async {
    return _loansBox.values.map((model) => model.toEntity()).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addLoan(Loan loan) async {
    final model = LoanModel.fromEntity(loan);
    await _loansBox.put(model.id, model);
  }

  Future<void> updateLoan(Loan loan) async {
    final model = LoanModel.fromEntity(loan);
    await _loansBox.put(model.id, model);
  }

  Future<void> deleteLoan(String id) async {
    await _loansBox.delete(id);
    // Also delete associated repayments
    final repaymentsToDelete = _repaymentsBox.values.where((r) => r.loanId == id).map((r) => r.id).toList();
    for (final rId in repaymentsToDelete) {
      await _repaymentsBox.delete(rId);
    }
  }

  // Repayments
  Future<List<Repayment>> getRepaymentsForLoan(String loanId) async {
    return _repaymentsBox.values
        .where((model) => model.loanId == loanId)
        .map((model) => model.toEntity())
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addRepayment(Repayment repayment) async {
    final model = RepaymentModel.fromEntity(repayment);
    await _repaymentsBox.put(model.id, model);
  }

  Future<void> deleteRepayment(String id) async {
    await _repaymentsBox.delete(id);
  }
}
