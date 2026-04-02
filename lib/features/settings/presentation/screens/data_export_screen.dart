import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/data_export_service.dart';
import '../../../expense/presentation/providers/expense_providers.dart';
import '../../../income/presentation/providers/savings_goal_providers.dart';
import '../../../loan/presentation/providers/loan_providers.dart';

class DataExportScreen extends ConsumerWidget {
  const DataExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final goalsAsync = ref.watch(allSavingsGoalsProvider);
    final loansAsync = ref.watch(loansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Export & Backup'),
      ),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (expenses) => goalsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (goals) => loansAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (loans) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data Summary',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryRow('Transactions', expenses.length.toString()),
                          _buildSummaryRow('Savings Goals', goals.length.toString()),
                          _buildSummaryRow('Loans', loans.length.toString()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Export Options',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Export All Data (JSON)
                  ListTile(
                    leading: const Icon(Icons.backup_rounded),
                    title: const Text('Export All Data (JSON)'),
                    subtitle: const Text('Complete backup with all records'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final json = await DataExportService.exportAllToJson(
                        expenses: expenses,
                        goals: goals,
                        loans: loans,
                      );
                      await DataExportService.exportAndShare(
                        content: json,
                        fileName: 'expense_tracker_backup.json',
                        mimeType: 'application/json',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Backup exported successfully')),
                        );
                      }
                    },
                  ),
                  const Divider(),
                  
                  // Export Expenses (CSV)
                  ListTile(
                    leading: const Icon(Icons.table_chart_outlined),
                    title: const Text('Export Expenses (CSV)'),
                    subtitle: const Text('Spreadsheet format for analysis'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final csv = await DataExportService.exportExpensesToCsv(expenses);
                      await DataExportService.exportAndShare(
                        content: csv,
                        fileName: 'expenses.csv',
                        mimeType: 'text/csv',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Expenses exported successfully')),
                        );
                      }
                    },
                  ),
                  const Divider(),
                  
                  // Export Savings Goals (CSV)
                  ListTile(
                    leading: const Icon(Icons.savings_outlined),
                    title: const Text('Export Savings Goals (CSV)'),
                    subtitle: const Text('Goal progress and targets'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final csv = await DataExportService.exportGoalsToCsv(goals);
                      await DataExportService.exportAndShare(
                        content: csv,
                        fileName: 'savings_goals.csv',
                        mimeType: 'text/csv',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Goals exported successfully')),
                        );
                      }
                    },
                  ),
                  const Divider(),
                  
                  // Export Loans (CSV)
                  ListTile(
                    leading: const Icon(Icons.account_balance_outlined),
                    title: const Text('Export Loans (CSV)'),
                    subtitle: const Text('Loan and repayment records'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final csv = await DataExportService.exportLoansToCsv(loans);
                      await DataExportService.exportAndShare(
                        content: csv,
                        fileName: 'loans.csv',
                        mimeType: 'text/csv',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Loans exported successfully')),
                        );
                      }
                    },
                  ),
                  const Divider(),
                  
                  // Save Local Backup
                  ListTile(
                    leading: const Icon(Icons.save_alt_rounded),
                    title: const Text('Save Local Backup'),
                    subtitle: const Text('Store backup on device'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final json = await DataExportService.exportAllToJson(
                        expenses: expenses,
                        goals: goals,
                        loans: loans,
                      );
                      final path = await DataExportService.saveBackup(json);
                      await DataExportService.cleanupOldBackups();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Backup saved to: $path')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
