import 'package:hive/hive.dart';
import '../../domain/entities/loan.dart';
import '../../domain/entities/loan_type.dart';

part 'loan_model.g.dart';

@HiveType(typeId: 1)
class LoanModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String typeName;

  @HiveField(2)
  late String personName;

  @HiveField(3)
  late double totalAmount;

  @HiveField(4)
  late double remainingAmount;

  @HiveField(5)
  late int dateMs;

  @HiveField(6)
  String? note;

  @HiveField(7, defaultValue: false)
  bool isSettled;

  LoanModel({
    required this.id,
    required this.typeName,
    required this.personName,
    required this.totalAmount,
    required this.remainingAmount,
    required this.dateMs,
    this.note,
    this.isSettled = false,
  });

  factory LoanModel.fromEntity(Loan loan) => LoanModel(
        id: loan.id,
        typeName: loan.type.name,
        personName: loan.personName,
        totalAmount: loan.totalAmount,
        remainingAmount: loan.remainingAmount,
        dateMs: loan.date.millisecondsSinceEpoch,
        note: loan.note,
        isSettled: loan.isSettled,
      );

  Loan toEntity() => Loan(
        id: id,
        type: LoanType.fromString(typeName),
        personName: personName,
        totalAmount: totalAmount,
        remainingAmount: remainingAmount,
        date: DateTime.fromMillisecondsSinceEpoch(dateMs),
        note: note,
        isSettled: isSettled,
      );
}
