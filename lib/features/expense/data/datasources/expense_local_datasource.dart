import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/expense.dart';
import '../models/expense_model.dart';
import '../../../../core/constants/app_constants.dart';

/// Wraps Hive box operations for [ExpenseModel].
class ExpenseLocalDatasource {
  Box<ExpenseModel> get _box => Hive.box<ExpenseModel>(AppConstants.hiveExpenseBox);

  /// Returns all stored [ExpenseModel] instances.
  List<ExpenseModel> getAll() => _box.values.toList();

  /// Persists (or updates) a model using its [id] as the key.
  Future<void> save(ExpenseModel model) => _box.put(model.id, model);

  /// Deletes the model with the given [id].
  Future<void> delete(String id) => _box.delete(id);

  /// Deletes all stored models.
  Future<void> clear() => _box.clear();

  /// Utility: converts domain [Expense] → persist to Hive.
  Future<void> saveEntity(Expense expense) =>
      save(ExpenseModel.fromEntity(expense));
}
