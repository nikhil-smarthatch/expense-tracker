import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/expense.dart';

/// Service for generating and exporting financial reports
class ReportExportService {
  /// Generates a CSV file with all transactions
  static Future<String> generateTransactionCSV(
    List<Expense> expenses,
    String fileName,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName.csv';

    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln('Date,Type,Category,Amount,Note');

    // CSV Rows
    for (final expense in expenses) {
      final type = expense.isIncome ? 'Income' : 'Expense';
      final amount = expense.amount;
      final category = expense.category.label;
      final date = expense.date.toString().split(' ')[0]; // YYYY-MM-DD
      final note = expense.note?.replaceAll(',', ';') ?? '';

      buffer.writeln('$date,$type,$category,$amount,$note');
    }

    // Write to file
    final file = File(filePath);
    await file.writeAsString(buffer.toString());

    return filePath;
  }

  /// Generates a monthly summary CSV
  static Future<String> generateMonthlySummaryCSV(
    List<Expense> expenses,
    String fileName,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName.csv';

    // Group by month
    final monthlyData = <String, Map<String, double>>{};

    for (final expense in expenses) {
      final monthKey =
          '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}';

      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = {'income': 0, 'expense': 0};
      }

      if (expense.isIncome) {
        monthlyData[monthKey]!['income'] =
            monthlyData[monthKey]!['income']! + expense.amount;
      } else {
        monthlyData[monthKey]!['expense'] =
            monthlyData[monthKey]!['expense']! + expense.amount;
      }
    }

    final buffer = StringBuffer();
    buffer.writeln('Month,Income,Expense,Net');

    // Sort months
    final sortedMonths = monthlyData.keys.toList()..sort();

    for (final month in sortedMonths) {
      final data = monthlyData[month]!;
      final income = data['income'] ?? 0;
      final expense = data['expense'] ?? 0;
      final net = income - expense;

      buffer.writeln('$month,$income,$expense,$net');
    }

    final file = File(filePath);
    await file.writeAsString(buffer.toString());

    return filePath;
  }

  /// Generates category-wise spending report
  static Future<String> generateCategoryReportCSV(
    List<Expense> expenses,
    String fileName,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName.csv';

    final categoryData = <String, double>{};
    double totalSpending = 0;

    for (final expense in expenses.where((e) => !e.isIncome)) {
      final category = expense.category.label;
      categoryData[category] = (categoryData[category] ?? 0) + expense.amount;
      totalSpending += expense.amount;
    }

    final buffer = StringBuffer();
    buffer.writeln('Category,Amount,Percentage');

    // Sort by amount descending
    final sortedEntries = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedEntries) {
      final percentage = totalSpending > 0
          ? ((entry.value / totalSpending) * 100).toStringAsFixed(2)
          : '0.00';
      buffer.writeln(
          '${entry.key},${entry.value.toStringAsFixed(2)},$percentage');
    }

    buffer.writeln('TOTAL,$totalSpending,100.00');

    final file = File(filePath);
    await file.writeAsString(buffer.toString());

    return filePath;
  }

  /// Generates a text summary report
  static Future<String> generateTextReport(
    List<Expense> allExpenses,
    String fileName,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName.txt';

    final now = DateTime.now();
    final buffer = StringBuffer();

    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('FINANCIAL REPORT');
    buffer.writeln('Generated: $now');
    buffer.writeln('═══════════════════════════════════════\n');

    // Overall statistics
    final totalIncome = allExpenses
        .where((e) => e.isIncome)
        .fold<double>(0, (sum, e) => sum + e.amount);

    final totalExpense = allExpenses
        .where((e) => !e.isIncome)
        .fold<double>(0, (sum, e) => sum + e.amount);

    buffer.writeln('OVERALL SUMMARY');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Total Income:  ₹$totalIncome');
    buffer.writeln('Total Expense: ₹$totalExpense');
    buffer.writeln('Net Balance:   ₹${totalIncome - totalExpense}');
    buffer.writeln('Entries:       ${allExpenses.length}\n');

    // Monthly breakdown (last 3 months)
    buffer.writeln('RECENT MONTHS');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    for (int i = 2; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i);
      final monthExpenses = allExpenses.where((e) =>
          e.date.month == monthDate.month && e.date.year == monthDate.year);

      final monthIncome = monthExpenses
          .where((e) => e.isIncome)
          .fold<double>(0, (sum, e) => sum + e.amount);

      final monthExpense = monthExpenses
          .where((e) => !e.isIncome)
          .fold<double>(0, (sum, e) => sum + e.amount);

      buffer.writeln(
          '${monthDate.year}-${monthDate.month.toString().padLeft(2, '0')}: '
          'Income: ₹$monthIncome | Expense: ₹$monthExpense');
    }

    buffer.writeln();
    buffer.writeln('═══════════════════════════════════════');

    final file = File(filePath);
    await file.writeAsString(buffer.toString());

    return filePath;
  }
}
