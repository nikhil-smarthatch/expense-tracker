import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense_category.dart';

/// Helper to create a test expense quickly.
Expense makeExpense({
  String id = '1',
  double amount = 100.0,
  ExpenseCategory category = ExpenseCategory.food,
  DateTime? date,
  String? note,
}) =>
    Expense(
      id: id,
      amount: amount,
      category: category,
      date: date ?? DateTime(2025, 3, 1),
      note: note,
    );

void main() {
  group('Expense entity', () {
    test('copyWith preserves unchanged fields', () {
      final original = makeExpense(amount: 500, note: 'Dinner');
      final updated = original.copyWith(amount: 750);
      expect(updated.id, original.id);
      expect(updated.amount, 750);
      expect(updated.note, 'Dinner');
    });

    test('copyWith clearNote removes the note', () {
      final original = makeExpense(note: 'Lunch');
      final updated = original.copyWith(clearNote: true);
      expect(updated.note, isNull);
    });

    test('equality is based on id', () {
      final a = makeExpense(id: 'abc', amount: 100);
      final b = makeExpense(id: 'abc', amount: 999);
      expect(a, equals(b));
    });
  });

  group('Monthly total calculation', () {
    final expenses = [
      makeExpense(id: '1', amount: 200, date: DateTime(2025, 3, 5)),
      makeExpense(id: '2', amount: 350, date: DateTime(2025, 3, 10)),
      makeExpense(id: '3', amount: 150, date: DateTime(2025, 4, 1)),
    ];

    test('total for March 2025 is 550', () {
      final march = expenses
          .where((e) => e.date.month == 3 && e.date.year == 2025)
          .fold(0.0, (sum, e) => sum + e.amount);
      expect(march, 550.0);
    });

    test('total for April 2025 is 150', () {
      final april = expenses
          .where((e) => e.date.month == 4 && e.date.year == 2025)
          .fold(0.0, (sum, e) => sum + e.amount);
      expect(april, 150.0);
    });

    test('total for empty month is 0', () {
      final feb = expenses
          .where((e) => e.date.month == 2 && e.date.year == 2025)
          .fold(0.0, (sum, e) => sum + e.amount);
      expect(feb, 0.0);
    });
  });

  group('Category breakdown', () {
    final expenses = [
      makeExpense(id: '1', amount: 400, category: ExpenseCategory.food),
      makeExpense(id: '2', amount: 300, category: ExpenseCategory.food),
      makeExpense(id: '3', amount: 500, category: ExpenseCategory.travel),
      makeExpense(id: '4', amount: 200, category: ExpenseCategory.bills),
    ];

    Map<ExpenseCategory, double> buildBreakdown(List<Expense> list) {
      final map = <ExpenseCategory, double>{};
      for (final e in list) {
        map[e.category] = (map[e.category] ?? 0) + e.amount;
      }
      return map;
    }

    test('food total is 700', () {
      final breakdown = buildBreakdown(expenses);
      expect(breakdown[ExpenseCategory.food], 700.0);
    });

    test('travel total is 500', () {
      final breakdown = buildBreakdown(expenses);
      expect(breakdown[ExpenseCategory.travel], 500.0);
    });

    test('highest category is food', () {
      final breakdown = buildBreakdown(expenses);
      final highest =
          breakdown.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      expect(highest, ExpenseCategory.food);
    });

    test('missing category returns null', () {
      final breakdown = buildBreakdown(expenses);
      expect(breakdown[ExpenseCategory.shopping], isNull);
    });
  });

  group('ExpenseCategory', () {
    test('fromString returns correct enum', () {
      expect(ExpenseCategory.fromString('food'), ExpenseCategory.food);
      expect(ExpenseCategory.fromString('travel'), ExpenseCategory.travel);
    });

    test('fromString falls back to others for unknown value', () {
      expect(ExpenseCategory.fromString('unknown'), ExpenseCategory.others);
    });

    test('all categories have non-empty labels', () {
      for (final cat in ExpenseCategory.values) {
        expect(cat.label, isNotEmpty);
      }
    });
  });

  group('Filtering logic', () {
    final now = DateTime.now();
    final expenses = [
      makeExpense(id: '1', date: now),
      makeExpense(id: '2', date: now.subtract(const Duration(days: 40))),
      makeExpense(id: '3', date: now.subtract(const Duration(days: 5))),
    ];

    test('filters to current month only', () {
      final current = expenses
          .where(
              (e) => e.date.month == now.month && e.date.year == now.year)
          .toList();
      expect(current.length, 2);
    });

    test('sorting by date descending works', () {
      final sorted = [...expenses]..sort((a, b) => b.date.compareTo(a.date));
      expect(sorted.first.id, '1'); // most recent first
    });
  });
}
