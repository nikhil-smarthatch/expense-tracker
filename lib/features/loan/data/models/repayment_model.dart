import 'package:hive/hive.dart';
import '../../domain/entities/repayment.dart';

part 'repayment_model.g.dart';

@HiveType(typeId: 2)
class RepaymentModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String loanId;

  @HiveField(2)
  late double amount;

  @HiveField(3)
  late int dateMs;

  RepaymentModel({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.dateMs,
  });

  factory RepaymentModel.fromEntity(Repayment repayment) => RepaymentModel(
        id: repayment.id,
        loanId: repayment.loanId,
        amount: repayment.amount,
        dateMs: repayment.date.millisecondsSinceEpoch,
      );

  Repayment toEntity() => Repayment(
        id: id,
        loanId: loanId,
        amount: amount,
        date: DateTime.fromMillisecondsSinceEpoch(dateMs),
      );
}
