import 'package:hive/hive.dart';
import '../../domain/entities/savings_goal.dart';

part 'savings_goal_model.g.dart';

/// Hive-persisted model for [SavingsGoal]
@HiveType(typeId: 3)
class SavingsGoalModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String description;

  @HiveField(3)
  late double targetAmount;

  @HiveField(4)
  late double currentAmount;

  @HiveField(5)
  late String category;

  @HiveField(6)
  late String priority;

  @HiveField(7)
  late int createdDateMs;

  @HiveField(8)
  int? deadlineDateMs;

  @HiveField(9, defaultValue: false)
  bool isCompleted;

  @HiveField(10)
  int? completedDateMs;

  SavingsGoalModel({
    required this.id,
    required this.title,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.category,
    required this.priority,
    required this.createdDateMs,
    this.deadlineDateMs,
    this.isCompleted = false,
    this.completedDateMs,
  });

  /// Create a [SavingsGoalModel] from a domain [SavingsGoal]
  factory SavingsGoalModel.fromEntity(SavingsGoal goal) => SavingsGoalModel(
        id: goal.id,
        title: goal.title,
        description: goal.description,
        targetAmount: goal.targetAmount,
        currentAmount: goal.currentAmount,
        category: goal.category,
        priority: goal.priority,
        createdDateMs: goal.createdDate.millisecondsSinceEpoch,
        deadlineDateMs: goal.deadline?.millisecondsSinceEpoch,
        isCompleted: goal.isCompleted,
        completedDateMs: goal.completedDate?.millisecondsSinceEpoch,
      );

  /// Convert this model back to domain [SavingsGoal]
  SavingsGoal toEntity() => SavingsGoal(
        id: id,
        title: title,
        description: description,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        category: category,
        priority: priority,
        createdDate: DateTime.fromMillisecondsSinceEpoch(createdDateMs),
        deadline: deadlineDateMs != null
            ? DateTime.fromMillisecondsSinceEpoch(deadlineDateMs!)
            : null,
        isCompleted: isCompleted,
        completedDate: completedDateMs != null
            ? DateTime.fromMillisecondsSinceEpoch(completedDateMs!)
            : null,
      );
}
