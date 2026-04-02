/// Budget template configurations
class BudgetTemplate {
  final String name;
  final String description;
  final Map<String, double> allocations; // category -> percentage

  const BudgetTemplate({
    required this.name,
    required this.description,
    required this.allocations,
  });

  /// The classic 50/30/20 rule
  /// 50% Needs, 30% Wants, 20% Savings
  static const BudgetTemplate rule503020 = BudgetTemplate(
    name: '50/30/20 Rule',
    description: 'Classic budgeting: 50% needs, 30% wants, 20% savings',
    allocations: {
      'needs': 50.0,
      'wants': 30.0,
      'savings': 20.0,
    },
  );

  /// Aggressive savings template
  /// 50% Needs, 20% Wants, 30% Savings
  static const BudgetTemplate aggressiveSavings = BudgetTemplate(
    name: 'Aggressive Savings',
    description: 'Prioritize savings: 50% needs, 20% wants, 30% savings',
    allocations: {
      'needs': 50.0,
      'wants': 20.0,
      'savings': 30.0,
    },
  );

  /// Minimalist budget
  /// 60% Needs, 20% Wants, 20% Savings
  static const BudgetTemplate minimalist = BudgetTemplate(
    name: 'Minimalist',
    description: 'Live simply: 60% needs, 20% wants, 20% savings',
    allocations: {
      'needs': 60.0,
      'wants': 20.0,
      'savings': 20.0,
    },
  );

  /// Zero-based budget (every dollar has a job)
  static const BudgetTemplate zeroBased = BudgetTemplate(
    name: 'Zero-Based',
    description: 'Give every rupee a job',
    allocations: {
      'housing': 30.0,
      'food': 15.0,
      'transportation': 10.0,
      'utilities': 10.0,
      'entertainment': 10.0,
      'savings': 15.0,
      'debt': 10.0,
    },
  );

  /// All available templates
  static const List<BudgetTemplate> allTemplates = [
    rule503020,
    aggressiveSavings,
    minimalist,
    zeroBased,
  ];

  /// Calculate amounts based on income
  Map<String, double> calculateAmounts(double monthlyIncome) {
    return allocations.map((category, percentage) {
      return MapEntry(category, (monthlyIncome * percentage) / 100);
    });
  }

  /// Get recommendation based on income level
  static BudgetTemplate getRecommendation(double monthlyIncome) {
    if (monthlyIncome < 30000) {
      return minimalist; // Focus on essentials
    } else if (monthlyIncome < 80000) {
      return rule503020; // Balanced approach
    } else {
      return aggressiveSavings; // Can save more
    }
  }
}

/// Budget guidance calculator
class BudgetGuidance {
  /// Calculate recommended budget based on template
  static Map<String, double> calculateRecommendedBudget({
    required double monthlyIncome,
    required BudgetTemplate template,
    double? existingSavings,
    double? debtPayments,
  }) {
    final allocations = template.calculateAmounts(monthlyIncome);

    // Adjust for debt payments if specified
    if (debtPayments != null && debtPayments > 0) {
      final needsAmount = allocations['needs'] ?? 0;
      allocations['needs'] = needsAmount + debtPayments;
    }

    return allocations;
  }

  /// Analyze current spending against budget template
  static BudgetAnalysis analyzeSpending({
    required double monthlyIncome,
    required Map<String, double> actualSpending,
    required BudgetTemplate template,
  }) {
    final recommended = template.calculateAmounts(monthlyIncome);
    final analysis = <String, CategoryAnalysis>{};

    for (final entry in recommended.entries) {
      final category = entry.key;
      final recommendedAmount = entry.value;
      final actualAmount = actualSpending[category] ?? 0;
      final difference = actualAmount - recommendedAmount;
      final percentage = recommendedAmount > 0
          ? ((actualAmount / recommendedAmount) * 100).toDouble()
          : 0.0;

      analysis[category] = CategoryAnalysis(
        category: category,
        recommended: recommendedAmount,
        actual: actualAmount,
        difference: difference,
        percentageOfRecommended: percentage,
        status: percentage > 100
            ? CategoryStatus.overBudget
            : percentage > 90
                ? CategoryStatus.atRisk
                : CategoryStatus.onTrack,
      );
    }

    return BudgetAnalysis(
      categoryAnalysis: analysis,
      totalRecommended: recommended.values.fold(0.0, (sum, v) => sum + v),
      totalActual: actualSpending.values.fold(0.0, (sum, v) => sum + v),
      template: template,
    );
  }

  /// Get suggestions for improving budget adherence
  static List<String> getSuggestions(BudgetAnalysis analysis) {
    final suggestions = <String>[];

    for (final category in analysis.categoryAnalysis.values) {
      if (category.status == CategoryStatus.overBudget) {
        suggestions.add(
          '${category.category}: Reduce by ₹${category.difference.abs().toStringAsFixed(0)} to stay on track',
        );
      } else if (category.status == CategoryStatus.atRisk) {
        suggestions.add(
          '${category.category}: Close to limit - monitor spending',
        );
      }
    }

    if (analysis.totalActual > analysis.totalRecommended) {
      final overspend = analysis.totalActual - analysis.totalRecommended;
      suggestions.add(
        'Overall: You\'re spending ₹${overspend.toStringAsFixed(0)} more than planned',
      );
    }

    return suggestions;
  }
}

/// Analysis result for a single category
class CategoryAnalysis {
  final String category;
  final double recommended;
  final double actual;
  final double difference;
  final double percentageOfRecommended;
  final CategoryStatus status;

  CategoryAnalysis({
    required this.category,
    required this.recommended,
    required this.actual,
    required this.difference,
    required this.percentageOfRecommended,
    required this.status,
  });
}

enum CategoryStatus {
  onTrack,
  atRisk,
  overBudget,
}

/// Complete budget analysis
class BudgetAnalysis {
  final Map<String, CategoryAnalysis> categoryAnalysis;
  final double totalRecommended;
  final double totalActual;
  final BudgetTemplate template;

  BudgetAnalysis({
    required this.categoryAnalysis,
    required this.totalRecommended,
    required this.totalActual,
    required this.template,
  });

  double get totalDifference => totalActual - totalRecommended;
  bool get isOverBudget => totalActual > totalRecommended;
}
