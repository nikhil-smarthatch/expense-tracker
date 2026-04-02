import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/loan_type.dart';
import '../providers/loan_providers.dart';
import '../widgets/loan_card.dart';
import 'debt_payoff_calculator_screen.dart';

class LoanListScreen extends ConsumerStatefulWidget {
  const LoanListScreen({super.key});

  @override
  ConsumerState<LoanListScreen> createState() => _LoanListScreenState();
}

class _LoanListScreenState extends ConsumerState<LoanListScreen> {
  LoanType _selectedType = LoanType.borrow;

  @override
  Widget build(BuildContext context) {
    final loansAsync = ref.watch(loansProvider);
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Debt Payoff Calculator Card
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.calculate_rounded),
              title: const Text('Debt Payoff Calculator'),
              subtitle: const Text('Snowball vs Avalanche strategy'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DebtPayoffCalculatorScreen()),
              ),
            ),
          ),
        ),
        // Loan Type Toggle
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<LoanType>(
              segments: const [
                ButtonSegment(
                  value: LoanType.borrow,
                  label: Text('I Borrowed'),
                  icon: Icon(Icons.download_rounded),
                ),
                ButtonSegment(
                  value: LoanType.lend,
                  label: Text('I Lent'),
                  icon: Icon(Icons.upload_rounded),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (set) {
                setState(() => _selectedType = set.first);
              },
            ),
          ),
        ),
        Expanded(
          child: loansAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (loans) {
              final filtered = loans.where((l) => l.type == _selectedType).toList();
              return RefreshIndicator(
                onRefresh: () => ref.refresh(loansProvider.future),
                child: filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.account_balance_wallet_outlined, size: 64, color: cs.primary.withValues(alpha: 0.5)),
                                  const SizedBox(height: 16),
                                  Text('No ${_selectedType.label.toLowerCase()} records found.', style: Theme.of(context).textTheme.titleMedium),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return LoanCard(loan: filtered[index]);
                        },
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}
