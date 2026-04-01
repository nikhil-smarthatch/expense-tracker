import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/savings_goal_providers.dart';
import '../widgets/goal_progress_card.dart';
import 'add_edit_goal_screen.dart';

class SavingsGoalScreenPanel extends ConsumerWidget {
  const SavingsGoalScreenPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allGoalsAsync = ref.watch(allSavingsGoalsProvider);
    final overallProgressAsync = ref.watch(overallGoalProgressProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AddEditGoalScreen(),
          ),
        ),
        tooltip: 'Create Goal',
        child: const Icon(Icons.add_rounded),
      ),
      body: allGoalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (goals) => overallProgressAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (overallProgress) => RefreshIndicator(
            onRefresh: () => ref.refresh(allSavingsGoalsProvider.future),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
              child: Column(
                children: [
                  // Overall progress header
                  if (goals.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Overall Progress',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${overallProgress.toStringAsFixed(1)}% Complete',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    '${goals.length} Goal${goals.length != 1 ? 's' : ''}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value:
                                      (overallProgress / 100).clamp(0.0, 1.0),
                                  minHeight: 10,
                                  backgroundColor: cs.surfaceContainerHighest,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(cs.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Goals list
                  if (goals.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.savings_outlined,
                              size: 64,
                              color: cs.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No savings goals yet',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your first savings goal to get started',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AddEditGoalScreen(),
                                ),
                              ),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Create Goal'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Active Goals',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ),
                    ...goals
                        .where((g) => !g.isCompleted)
                        .map((goal) => GoalProgressCard(
                              goal: goal,
                              onTap: () async {
                                final result =
                                    await Navigator.of(context).push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AddEditGoalScreen(existingGoal: goal),
                                  ),
                                );
                                if (result == true) {
                                  ref.invalidate(allSavingsGoalsProvider);
                                }
                              },
                            )),
                    if (goals.any((g) => g.isCompleted)) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Completed Goals',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                      ...goals
                          .where((g) => g.isCompleted)
                          .map((goal) => GoalProgressCard(
                                goal: goal,
                                onTap: () async {
                                  final result =
                                      await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AddEditGoalScreen(existingGoal: goal),
                                    ),
                                  );
                                  if (result == true) {
                                    ref.invalidate(allSavingsGoalsProvider);
                                  }
                                },
                              )),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
