import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../features/expense/data/datasources/expense_local_datasource.dart';
import '../../features/expense/data/repositories/expense_repository_impl.dart';
import '../../features/expense/domain/entities/expense.dart';
import '../../features/expense/domain/entities/expense_category.dart';

/// Seeds the Hive box with realistic dummy data if it is empty.
Future<void> seedSampleData(OverrideLocalDatasource datasource) async {
  if (datasource.getAll().isNotEmpty) return;

  final now = DateTime.now();
  const uuid = Uuid();

  final samples = <Expense>[
    // Current month
    Expense(id: uuid.v4(), amount: 850, category: ExpenseCategory.food, date: now.subtract(const Duration(days: 1)), note: 'Dinner with family'),
    Expense(id: uuid.v4(), amount: 2400, category: ExpenseCategory.bills, date: now.subtract(const Duration(days: 2)), note: 'Electricity bill'),
    Expense(id: uuid.v4(), amount: 340, category: ExpenseCategory.food, date: now.subtract(const Duration(days: 3)), note: 'Lunch'),
    Expense(id: uuid.v4(), amount: 1200, category: ExpenseCategory.shopping, date: now.subtract(const Duration(days: 4)), note: 'New shirt'),
    Expense(id: uuid.v4(), amount: 560, category: ExpenseCategory.travel, date: now.subtract(const Duration(days: 5)), note: 'Cab fare'),
    Expense(id: uuid.v4(), amount: 3500, category: ExpenseCategory.travel, date: now.subtract(const Duration(days: 6)), note: 'Train ticket'),
    Expense(id: uuid.v4(), amount: 980, category: ExpenseCategory.food, date: now.subtract(const Duration(days: 7)), note: 'Groceries'),
    Expense(id: uuid.v4(), amount: 1599, category: ExpenseCategory.shopping, date: now.subtract(const Duration(days: 8)), note: 'Headphones'),
    Expense(id: uuid.v4(), amount: 450, category: ExpenseCategory.others, date: now.subtract(const Duration(days: 9)), note: 'Medicine'),
    Expense(id: uuid.v4(), amount: 760, category: ExpenseCategory.food, date: now.subtract(const Duration(days: 10)), note: 'Pizza'),
    Expense(id: uuid.v4(), amount: 1100, category: ExpenseCategory.bills, date: now.subtract(const Duration(days: 11)), note: 'Internet bill'),
    Expense(id: uuid.v4(), amount: 2800, category: ExpenseCategory.shopping, date: now.subtract(const Duration(days: 12)), note: 'Shoes'),
    Expense(id: uuid.v4(), amount: 200, category: ExpenseCategory.food, date: now.subtract(const Duration(days: 13)), note: 'Coffee'),
    Expense(id: uuid.v4(), amount: 4500, category: ExpenseCategory.bills, date: now.subtract(const Duration(days: 14)), note: 'Rent installment'),
    Expense(id: uuid.v4(), amount: 600, category: ExpenseCategory.travel, date: now.subtract(const Duration(days: 15)), note: 'Petrol'),

    // Last month
    Expense(id: uuid.v4(), amount: 5000, category: ExpenseCategory.bills, date: DateTime(now.year, now.month - 1, 5), note: 'Rent'),
    Expense(id: uuid.v4(), amount: 1200, category: ExpenseCategory.food, date: DateTime(now.year, now.month - 1, 8), note: 'Restaurant'),
    Expense(id: uuid.v4(), amount: 900, category: ExpenseCategory.travel, date: DateTime(now.year, now.month - 1, 12), note: 'Bus pass'),
    Expense(id: uuid.v4(), amount: 3200, category: ExpenseCategory.shopping, date: DateTime(now.year, now.month - 1, 18), note: 'Clothes'),
    Expense(id: uuid.v4(), amount: 400, category: ExpenseCategory.others, date: DateTime(now.year, now.month - 1, 25), note: 'Miscellaneous'),
  ];

  for (final expense in samples) {
    await datasource.saveEntity(expense);
  }
}

// Alias to avoid import friction
typedef OverrideLocalDatasource = ExpenseLocalDatasource;
