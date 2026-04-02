import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/savings_goal.dart';
import '../../data/models/savings_goal_model.dart';
import '../../../../core/constants/app_constants.dart';

/// Repository for savings goals data operations
class SavingsGoalRepository {
  final Box<SavingsGoalModel> _box;

  SavingsGoalRepository() : _box = Hive.box<SavingsGoalModel>(AppConstants.hiveSavingsGoalsBox);

  /// Get all savings goals
  List<SavingsGoal> getAllGoals() {
    return _box.values.map((model) => model.toEntity()).toList();
  }

  /// Get active goals (not completed)
  List<SavingsGoal> getActiveGoals() {
    return _box.values
        .where((model) => !model.isCompleted)
        .map((model) => model.toEntity())
        .toList();
  }

  /// Get a specific goal by ID
  SavingsGoal? getGoalById(String id) {
    try {
      final model = _box.values.firstWhere((m) => m.id == id);
      return model.toEntity();
    } catch (e) {
      return null;
    }
  }

  /// Add a new goal
  Future<void> addGoal(SavingsGoal goal) async {
    final model = SavingsGoalModel.fromEntity(goal);
    await _box.add(model);
  }

  /// Update an existing goal
  Future<void> updateGoal(SavingsGoal goal) async {
    final model = SavingsGoalModel.fromEntity(goal);
    final index = _box.values.toList().indexWhere((m) => m.id == goal.id);
    if (index != -1) {
      await _box.putAt(index, model);
    } else {
      throw Exception('Goal not found: ${goal.id}');
    }
  }

  /// Delete a goal
  Future<void> deleteGoal(String id) async {
    final index = _box.values.toList().indexWhere((m) => m.id == id);
    if (index != -1) {
      await _box.deleteAt(index);
    } else {
      throw Exception('Goal not found: $id');
    }
  }

  /// Update goal's current amount
  Future<void> updateGoalAmount(String id, double amount) async {
    final goal = getGoalById(id);
    if (goal != null) {
      await updateGoal(goal.copyWith(currentAmount: amount));
    }
  }

  /// Mark goal as completed
  Future<void> completeGoal(String id) async {
    final goal = getGoalById(id);
    if (goal != null) {
      await updateGoal(goal.copyWith(
        isCompleted: true,
        completedDate: DateTime.now(),
      ));
    }
  }
}
