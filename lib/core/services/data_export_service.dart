import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/expense/domain/entities/expense.dart';
import '../../features/income/domain/entities/savings_goal.dart';
import '../../features/loan/domain/entities/loan.dart';

/// Service for exporting app data to various formats
class DataExportService {
  /// Export expenses to CSV format
  static Future<String> exportExpensesToCsv(List<Expense> expenses) async {
    final rows = <List<String>>[
      ['ID', 'Amount', 'Category', 'Date', 'Note', 'Is Income', 'Is Credit Card', 'Is Settled'],
    ];

    for (final expense in expenses) {
      rows.add([
        expense.id,
        expense.amount.toStringAsFixed(2),
        expense.category.label,
        expense.date.toIso8601String(),
        expense.note ?? '',
        expense.isIncome.toString(),
        expense.isCreditCard.toString(),
        expense.isCreditCardSettled.toString(),
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Export savings goals to CSV
  static Future<String> exportGoalsToCsv(List<SavingsGoal> goals) async {
    final rows = <List<String>>[
      ['ID', 'Title', 'Description', 'Target Amount', 'Current Amount', 'Category', 'Priority', 'Deadline', 'Is Completed'],
    ];

    for (final goal in goals) {
      rows.add([
        goal.id,
        goal.title,
        goal.description,
        goal.targetAmount.toStringAsFixed(2),
        goal.currentAmount.toStringAsFixed(2),
        goal.category,
        goal.priority,
        goal.deadline?.toIso8601String() ?? '',
        goal.isCompleted.toString(),
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Export loans to CSV
  static Future<String> exportLoansToCsv(List<Loan> loans) async {
    final rows = <List<String>>[
      ['ID', 'Type', 'Person Name', 'Total Amount', 'Remaining', 'Date', 'Is Settled', 'Note'],
    ];

    for (final loan in loans) {
      rows.add([
        loan.id,
        loan.type.name,
        loan.personName,
        loan.totalAmount.toStringAsFixed(2),
        loan.remainingAmount.toStringAsFixed(2),
        loan.date.toIso8601String(),
        loan.isSettled.toString(),
        loan.note ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Export all data to JSON
  static Future<String> exportAllToJson({
    required List<Expense> expenses,
    required List<SavingsGoal> goals,
    required List<Loan> loans,
  }) async {
    final data = {
      'exportDate': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0',
      'expenses': expenses.map((e) => _expenseToJson(e)).toList(),
      'savingsGoals': goals.map((g) => _goalToJson(g)).toList(),
      'loans': loans.map((l) => _loanToJson(l)).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Save data to file and share
  static Future<void> exportAndShare({
    required String content,
    required String fileName,
    required String mimeType,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(content);
    await Share.shareXFiles([XFile(file.path)], text: 'Expense Tracker Export');
  }

  /// Save backup to local storage
  static Future<String> saveBackup(String jsonData) async {
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/backups');
    
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${backupDir.path}/backup_$timestamp.json');
    await file.writeAsString(jsonData);
    
    return file.path;
  }

  /// Get list of backups
  static Future<List<File>> getBackups() async {
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/backups');
    
    if (!await backupDir.exists()) return [];
    
    final files = backupDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();
    
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files;
  }

  /// Delete old backups keeping only recent ones
  static Future<void> cleanupOldBackups({int keepCount = 5}) async {
    final backups = await getBackups();
    if (backups.length <= keepCount) return;

    for (var i = keepCount; i < backups.length; i++) {
      await backups[i].delete();
    }
  }

  // Helper methods for JSON serialization
  static Map<String, dynamic> _expenseToJson(Expense e) => {
        'id': e.id,
        'amount': e.amount,
        'category': e.category.name,
        'date': e.date.toIso8601String(),
        'note': e.note,
        'isIncome': e.isIncome,
        'isCreditCard': e.isCreditCard,
        'isCreditCardSettled': e.isCreditCardSettled,
        'creditCardPaidAmount': e.creditCardPaidAmount,
        'isRecurring': e.isRecurring,
        'recurrenceInterval': e.recurrenceInterval,
      };

  static Map<String, dynamic> _goalToJson(SavingsGoal g) => {
        'id': g.id,
        'title': g.title,
        'description': g.description,
        'targetAmount': g.targetAmount,
        'currentAmount': g.currentAmount,
        'category': g.category,
        'priority': g.priority,
        'createdDate': g.createdDate.toIso8601String(),
        'deadline': g.deadline?.toIso8601String(),
        'isCompleted': g.isCompleted,
        'completedDate': g.completedDate?.toIso8601String(),
      };

  static Map<String, dynamic> _loanToJson(Loan l) => {
        'id': l.id,
        'type': l.type.name,
        'personName': l.personName,
        'totalAmount': l.totalAmount,
        'remainingAmount': l.remainingAmount,
        'date': l.date.toIso8601String(),
        'note': l.note,
        'isSettled': l.isSettled,
      };
}
