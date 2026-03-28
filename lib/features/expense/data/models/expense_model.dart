import 'package:hive/hive.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_category.dart';

part 'expense_model.g.dart';

/// Hive-persisted model for [Expense].
/// Stores [category] as its string name and [date] as millisecondsSinceEpoch.
@HiveType(typeId: 0)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late double amount;

  /// Category stored as enum name string (e.g., 'food', 'travel').
  @HiveField(2)
  late String categoryName;

  /// Stored as millisecondsSinceEpoch for portability.
  @HiveField(3)
  late int dateMs;

  @HiveField(4)
  String? note;

  @HiveField(5, defaultValue: false)
  bool isIncome;

  @HiveField(6)
  String? receiptPath;

  ExpenseModel({
    required this.id,
    required this.amount,
    required this.categoryName,
    required this.dateMs,
    this.note,
    this.isIncome = false,
    this.receiptPath,
  });

  /// Creates an [ExpenseModel] from a domain [Expense].
  factory ExpenseModel.fromEntity(Expense expense) => ExpenseModel(
        id: expense.id,
        amount: expense.amount,
        categoryName: expense.category.name,
        dateMs: expense.date.millisecondsSinceEpoch,
        note: expense.note,
        isIncome: expense.isIncome,
        receiptPath: expense.receiptPath,
      );

  /// Converts this model back to the domain [Expense] entity.
  Expense toEntity() => Expense(
        id: id,
        amount: amount,
        category: ExpenseCategory.fromString(categoryName),
        date: DateTime.fromMillisecondsSinceEpoch(dateMs),
        note: note,
        isIncome: isIncome,
        receiptPath: receiptPath,
      );
}
