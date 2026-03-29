import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/savings_goal.dart';
import '../providers/smart_insights_providers.dart';
import '../providers/savings_goal_providers.dart';
import '../widgets/spending_breakdown_widget.dart';
import '../widgets/suggestion_card_widget.dart';
import '../widgets/budget_guidance_widget.dart';

/// Smart Insights Dashboard - Shows spending analysis, suggestions, budgets, and predictions
class SmartInsightsScreen extends ConsumerWidget {
  const SmartInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryGoalAsync = ref.watch(primarySavingsGoalProvider);
    final suggestionsAsync = ref.watch(primaryGoalSuggestionsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Insights'),
        elevation: 0,
      ),
      body: primaryGoalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (primaryGoal) {
          if (primaryGoal == null) {
            return _buildNoGoalState(context, cs);
          }

          return suggestionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(
              child: Text('Error loading suggestions'),
            ),
            data: (suggestions) {
              return RefreshIndicator(
                onRefresh: () async {
                  await ref.refresh(spendingByCategoryProvider.future);
                  await ref.refresh(primaryGoalSuggestionsProvider.future);
                  await ref.refresh(completionDateProvider.future);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Primary goal header
                      _buildGoalHeader(context, cs, primaryGoal),
                      const SizedBox(height: 24),

                      // Budget Guidance
                      const BudgetGuidanceWidget(),
                      const SizedBox(height: 24),

                      // Spending Breakdown
                      const SpendingBreakdownWidget(),
                      const SizedBox(height: 24),

                      // Smart Suggestions
                      SuggestionsListWidget(suggestions: suggestions),
                      const SizedBox(height: 24),

                      // Tips section
                      _buildTipsSection(context, cs),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGoalHeader(
    BuildContext context,
    ColorScheme cs,
    SavingsGoal goal,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer,
            cs.primaryContainer.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.savings_outlined,
                color: cs.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Priority: ${goal.priority.toUpperCase()}',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: cs.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            goal.description,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onPrimaryContainer),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNoGoalState(BuildContext context, ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 64,
            color: cs.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Goal',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Create a savings goal to see personalized insights and recommendations',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              // Navigate to add goal screen
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Goal'),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection(BuildContext context, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Savings Tips',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        _buildTipCard(
          context,
          cs,
          Icons.check_circle_rounded,
          'Track Regularly',
          'Review your spending weekly to stay on top of your goals',
        ),
        const SizedBox(height: 12),
        _buildTipCard(
          context,
          cs,
          Icons.trending_down_rounded,
          'Cut Gradually',
          'Reduce spending by 10-20% each month for sustainable habits',
        ),
        const SizedBox(height: 12),
        _buildTipCard(
          context,
          cs,
          Icons.flash_on_rounded,
          'Automate Savings',
          'Set up automatic transfers to a savings account each payday',
        ),
      ],
    );
  }

  Widget _buildTipCard(
    BuildContext context,
    ColorScheme cs,
    IconData icon,
    String title,
    String description,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
