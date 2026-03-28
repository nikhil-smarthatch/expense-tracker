import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../expense/domain/entities/expense_category.dart';
import '../../../../core/utils/currency_formatter.dart';

// ────────────────────────────────────────
// Pie Chart – Category Breakdown
// ────────────────────────────────────────

class CategoryPieChart extends StatefulWidget {
  const CategoryPieChart({super.key, required this.data});

  /// Map of category → total amount.
  final Map<ExpenseCategory, double> data;

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(child: Text('No data for this month'));
    }

    final total = widget.data.values.fold(0.0, (a, b) => a + b);
    final entries = widget.data.entries.toList();

    return Row(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex =
                          response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: List.generate(entries.length, (i) {
                  final isTouched = i == touchedIndex;
                  final entry = entries[i];
                  final percentage = (entry.value / total * 100);

                  return PieChartSectionData(
                    color: entry.key.color,
                    value: entry.value,
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: isTouched ? 65 : 55,
                    titleStyle: TextStyle(
                      fontSize: isTouched ? 14 : 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        // Legend
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entries
              .map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: entry.key.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry.key.label,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

// ────────────────────────────────────────
// Bar Chart – Daily Spending Trend
// ────────────────────────────────────────

class DailyBarChart extends StatelessWidget {
  const DailyBarChart({super.key, required this.dailyTotals});

  final List<double> dailyTotals;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (dailyTotals.isEmpty || dailyTotals.every((d) => d == 0)) {
      return const Center(child: Text('No spending data'));
    }

    final maxY = dailyTotals.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final day = group.x + 1;
              return BarTooltipItem(
                'Day $day\n${CurrencyFormatter.formatCompact(rod.toY)}',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) => Text(
                CurrencyFormatter.formatCompact(value),
                style: const TextStyle(fontSize: 9),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 5 == 0) {
                  return Text(
                    '${value.toInt() + 1}',
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: cs.outline.withOpacity(0.2),
            strokeWidth: 1,
          ),
        ),
        barGroups: List.generate(dailyTotals.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: dailyTotals[i],
                color: dailyTotals[i] > 0
                    ? cs.primary
                    : cs.outline.withOpacity(0.2),
                width: 8,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }
}
