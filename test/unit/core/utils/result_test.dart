import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense_category.dart';
import 'package:expense_tracker/core/utils/result.dart';

// Mock classes
class MockExpense extends Mock implements Expense {}

void main() {
  group('Result<T>', () {
    test('should create success result with data', () {
      final result = Result.success(42);
      
      expect(result.isSuccess, true);
      expect(result.isFailure, false);
      expect(result.data, 42);
      expect(result.error, null);
    });

    test('should create failure result with error', () {
      final error = AppError.unknown('Test error');
      final result = Result.failure(error);
      
      expect(result.isSuccess, false);
      expect(result.isFailure, true);
      expect(result.data, null);
      expect(result.error, error);
    });

    test('getOrThrow should return data on success', () {
      final result = Result.success(42);
      expect(result.getOrThrow(), 42);
    });

    test('getOrThrow should throw on failure', () {
      final error = AppError.unknown('Test error');
      final result = Result.failure(error);
      expect(() => result.getOrThrow(), throwsA(isA<AppError>()));
    });

    test('getOrElse should return data on success', () {
      final result = Result.success(42);
      expect(result.getOrElse(0), 42);
    });

    test('getOrElse should return default on failure', () {
      final error = AppError.unknown('Test error');
      final result = Result.failure(error);
      expect(result.getOrElse(0), 0);
    });

    test('fold should call correct callback', () {
      final successResult = Result.success(42);
      final failureResult = Result.failure(AppError.unknown('Error'));

      final successValue = successResult.fold(
        (data) => data * 2,
        (error) => 0,
      );
      expect(successValue, 84);

      final failureValue = failureResult.fold(
        (data) => data * 2,
        (error) => -1,
      );
      expect(failureValue, -1);
    });

    test('map should transform success data', () {
      final result = Result.success(42);
      final mapped = result.map((n) => n.toString());
      
      expect(mapped.isSuccess, true);
      expect(mapped.data, '42');
    });

    test('map should preserve failure', () {
      final error = AppError.unknown('Error');
      final result = Result<int>.failure(error);
      final mapped = result.map((n) => n.toString());
      
      expect(mapped.isFailure, true);
      expect(mapped.error, error);
    });
  });

  group('Expense Entity', () {
    test('should create expense with required fields', () {
      final expense = Expense(
        id: 'test-1',
        amount: 100.0,
        category: ExpenseCategory.food,
        date: DateTime(2024, 1, 1),
      );

      expect(expense.id, 'test-1');
      expect(expense.amount, 100.0);
      expect(expense.category, ExpenseCategory.food);
      expect(expense.isIncome, false);
    });

    test('copyWith should create updated copy', () {
      final expense = Expense(
        id: 'test-1',
        amount: 100.0,
        category: ExpenseCategory.food,
        date: DateTime(2024, 1, 1),
      );

      final updated = expense.copyWith(amount: 150.0);

      expect(updated.id, expense.id);
      expect(updated.amount, 150.0);
      expect(updated.category, expense.category);
    });

    test('should identify equal expenses by id', () {
      final expense1 = Expense(
        id: 'same-id',
        amount: 100.0,
        category: ExpenseCategory.food,
        date: DateTime(2024, 1, 1),
      );

      final expense2 = Expense(
        id: 'same-id',
        amount: 200.0,
        category: ExpenseCategory.bills,
        date: DateTime(2024, 2, 1),
      );

      expect(expense1 == expense2, true);
      expect(expense1.hashCode == expense2.hashCode, true);
    });
  });

  group('Budget Templates', () {
    test('50/30/20 rule should have correct allocations', () {
      final allocations = BudgetTemplate.rule503020.allocations;
      
      expect(allocations['needs'], 50.0);
      expect(allocations['wants'], 30.0);
      expect(allocations['savings'], 20.0);
    });

    test('should calculate amounts correctly', () {
      const template = BudgetTemplate.rule503020;
      final amounts = template.calculateAmounts(50000);

      expect(amounts['needs'], 25000);
      expect(amounts['wants'], 15000);
      expect(amounts['savings'], 10000);
    });
  });

  group('SavingsGoal Calculations', () {
    test('should calculate remaining amount correctly', () {
      final goal = SavingsGoal(
        id: 'test-1',
        title: 'Test Goal',
        description: 'Test',
        targetAmount: 10000,
        currentAmount: 3000,
        category: 'Emergency',
        priority: 'high',
        createdDate: DateTime.now(),
      );

      expect(goal.remainingAmount, 7000);
    });

    test('should calculate progress percentage correctly', () {
      final goal = SavingsGoal(
        id: 'test-1',
        title: 'Test Goal',
        description: 'Test',
        targetAmount: 10000,
        currentAmount: 2500,
        category: 'Emergency',
        priority: 'high',
        createdDate: DateTime.now(),
      );

      expect(goal.progressPercentage, 25.0);
    });
  });
}

// Minimal SavingsGoal implementation for testing
class SavingsGoal {
  final String id;
  final String title;
  final String description;
  final double targetAmount;
  final double currentAmount;
  final String category;
  final String priority;
  final DateTime createdDate;
  final DateTime? deadline;
  final bool isCompleted;

  SavingsGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.category,
    required this.priority,
    required this.createdDate,
    this.deadline,
    this.isCompleted = false,
  });

  double get remainingAmount =>
      (targetAmount - currentAmount).clamp(0.0, double.infinity);

  double get progressPercentage {
    if (targetAmount <= 0) return 0;
    return ((currentAmount / targetAmount) * 100).clamp(0.0, 100.0);
  }
}

// Minimal BudgetTemplate for testing
class BudgetTemplate {
  final String name;
  final Map<String, double> allocations;

  const BudgetTemplate({
    required this.name,
    required this.allocations,
  });

  static const rule503020 = BudgetTemplate(
    name: '50/30/20 Rule',
    allocations: {
      'needs': 50.0,
      'wants': 30.0,
      'savings': 20.0,
    },
  );

  Map<String, double> calculateAmounts(double income) {
    return allocations.map((k, v) => MapEntry(k, (income * v) / 100));
  }
}
