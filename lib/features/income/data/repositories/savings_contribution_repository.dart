import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';

/// Model for tracking individual savings contributions
class SavingsContribution {
  final String id;
  final String goalId;
  final double amount;
  final DateTime date;
  final String? note; // Optional note about the contribution
  final String? source; // e.g., "Monthly savings", "Bonus", "Gift"

  SavingsContribution({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.note,
    this.source,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'goalId': goalId,
    'amount': amount,
    'date': date.toIso8601String(),
    'note': note,
    'source': source,
  };

  factory SavingsContribution.fromJson(Map<String, dynamic> json) =>
      SavingsContribution(
        id: json['id'],
        goalId: json['goalId'],
        amount: json['amount'],
        date: DateTime.parse(json['date']),
        note: json['note'],
        source: json['source'],
      );
}

/// Repository for managing savings contribution history
class SavingsContributionRepository {
  final Box<String> _box = Hive.box<String>(AppConstants.hiveSavingsGoalsBox);
  static const String _contributionsKey = 'contributions';

  /// Add a new contribution
  Future<void> addContribution(SavingsContribution contribution) async {
    final contributions = await getAllContributions();
    contributions.add(contribution);
    await _saveContributions(contributions);
  }

  /// Get all contributions
  Future<List<SavingsContribution>> getAllContributions() async {
    final jsonString = _box.get(_contributionsKey);
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => SavingsContribution.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get contributions for a specific goal
  Future<List<SavingsContribution>> getContributionsForGoal(String goalId) async {
    final allContributions = await getAllContributions();
    return allContributions.where((c) => c.goalId == goalId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get contributions within a date range
  Future<List<SavingsContribution>> getContributionsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final allContributions = await getAllContributions();
    return allContributions.where((c) {
      return c.date.isAfter(start) && 
             c.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Delete a contribution
  Future<void> deleteContribution(String contributionId) async {
    final contributions = await getAllContributions();
    contributions.removeWhere((c) => c.id == contributionId);
    await _saveContributions(contributions);
  }

  /// Get contribution statistics for a goal
  Future<ContributionStats> getStatsForGoal(String goalId) async {
    final contributions = await getContributionsForGoal(goalId);
    
    if (contributions.isEmpty) {
      return ContributionStats.empty();
    }

    final totalAmount = contributions.fold(0.0, (sum, c) => sum + c.amount);
    final averageAmount = totalAmount / contributions.length;
    
    // Group by month
    final monthlyTotals = <String, double>{};
    for (final c in contributions) {
      final key = '${c.date.year}-${c.date.month.toString().padLeft(2, '0')}';
      monthlyTotals[key] = (monthlyTotals[key] ?? 0) + c.amount;
    }

    // Find highest contribution
    final highest = contributions.reduce((a, b) => a.amount > b.amount ? a : b);

    return ContributionStats(
      totalContributions: contributions.length,
      totalAmount: totalAmount,
      averageAmount: averageAmount,
      firstContributionDate: contributions.last.date,
      lastContributionDate: contributions.first.date,
      highestContribution: highest.amount,
      monthlyBreakdown: monthlyTotals,
    );
  }

  /// Save contributions to storage
  Future<void> _saveContributions(List<SavingsContribution> contributions) async {
    final jsonList = contributions.map((c) => c.toJson()).toList();
    await _box.put(_contributionsKey, jsonEncode(jsonList));
  }

  String jsonEncode(List<Map<String, dynamic>> jsonList) {
    return jsonList.toString(); // Simple serialization for now
  }

  dynamic jsonDecode(String jsonString) {
    // Placeholder - would use proper JSON parsing
    return [];
  }
}

/// Statistics for contributions
class ContributionStats {
  final int totalContributions;
  final double totalAmount;
  final double averageAmount;
  final DateTime? firstContributionDate;
  final DateTime? lastContributionDate;
  final double highestContribution;
  final Map<String, double> monthlyBreakdown;

  ContributionStats({
    required this.totalContributions,
    required this.totalAmount,
    required this.averageAmount,
    this.firstContributionDate,
    this.lastContributionDate,
    required this.highestContribution,
    required this.monthlyBreakdown,
  });

  factory ContributionStats.empty() => ContributionStats(
    totalContributions: 0,
    totalAmount: 0,
    averageAmount: 0,
    highestContribution: 0,
    monthlyBreakdown: {},
  );

  /// Get average monthly savings
  double get averageMonthlySavings {
    if (monthlyBreakdown.isEmpty) return 0;
    final total = monthlyBreakdown.values.fold(0.0, (sum, v) => sum + v);
    return total / monthlyBreakdown.length;
  }
}
