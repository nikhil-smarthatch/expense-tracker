import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/expense_providers.dart';
import '../../data/services/report_export_service.dart';
import '../../domain/entities/expense.dart';
import '../../../../core/utils/currency_formatter.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _isGenerating = false;

  Future<void> _generateAndShare(
    String reportType,
    Future<String> Function() generator,
  ) async {
    setState(() => _isGenerating = true);

    try {
      final filePath = await generator();
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Financial Report - $reportType',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Export'),
      ),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (expenses) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary section
              _SummaryCard(expenses: expenses, cs: cs),
              const SizedBox(height: 24),

              // Export options
              Text(
                'Export Reports',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // All Transactions CSV
              _ExportCard(
                title: 'All Transactions',
                description: 'Export all income and expense records as CSV',
                icon: Icons.table_chart_outlined,
                onPressed: _isGenerating
                    ? null
                    : () => _generateAndShare(
                          'All Transactions',
                          () => ReportExportService.generateTransactionCSV(
                            expenses,
                            'all_transactions_${DateTime.now().millisecondsSinceEpoch}',
                          ),
                        ),
              ),
              const SizedBox(height: 12),

              // Monthly Summary
              _ExportCard(
                title: 'Monthly Summary',
                description: 'View monthly income and expense breakdown',
                icon: Icons.calendar_month_outlined,
                onPressed: _isGenerating
                    ? null
                    : () => _generateAndShare(
                          'Monthly Summary',
                          () => ReportExportService.generateMonthlySummaryCSV(
                            expenses,
                            'monthly_summary_${DateTime.now().millisecondsSinceEpoch}',
                          ),
                        ),
              ),
              const SizedBox(height: 12),

              // Category Breakdown
              _ExportCard(
                title: 'Category Breakdown',
                description: 'Spending by category with percentages',
                icon: Icons.pie_chart_outline_rounded,
                onPressed: _isGenerating
                    ? null
                    : () => _generateAndShare(
                          'Category Report',
                          () => ReportExportService.generateCategoryReportCSV(
                            expenses,
                            'category_report_${DateTime.now().millisecondsSinceEpoch}',
                          ),
                        ),
              ),
              const SizedBox(height: 12),

              // Full Text Report
              _ExportCard(
                title: 'Complete Report',
                description: 'Comprehensive summary with all statistics',
                icon: Icons.description_outlined,
                onPressed: _isGenerating
                    ? null
                    : () => _generateAndShare(
                          'Complete Report',
                          () => ReportExportService.generateTextReport(
                            expenses,
                            'complete_report_${DateTime.now().millisecondsSinceEpoch}',
                          ),
                        ),
              ),

              const SizedBox(height: 24),

              // Info section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ℹ️ Exports Explained',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• CSV files can be opened in Excel or Google Sheets\n'
                      '• All reports are generated with current date\n'
                      '• Share directly with your accountant or email\n'
                      '• Reports include all data entries to date',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<Expense> expenses;
  final ColorScheme cs;

  const _SummaryCard({required this.expenses, required this.cs});

  @override
  Widget build(BuildContext context) {
    final totalIncome = expenses
        .where((e) => e.isIncome)
        .fold<double>(0, (sum, e) => sum + e.amount);
    final totalExpense = expenses
        .where((e) => !e.isIncome)
        .fold<double>(0, (sum, e) => sum + e.amount);

    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Records',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onPrimaryContainer.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 4),
            Text(
              '${expenses.length} entries',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Income',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(totalIncome),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Expense',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(totalExpense),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onPressed;

  const _ExportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: cs.onSecondaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
