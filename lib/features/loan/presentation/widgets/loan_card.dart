import 'package:flutter/material.dart';
import '../../domain/entities/loan.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../screens/loan_detail_screen.dart'; // We'll create this next

class LoanCard extends StatelessWidget {
  const LoanCard({super.key, required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSettled = loan.isSettled;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => LoanDetailScreen(loan: loan)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSettled ? Colors.grey.withValues(alpha: 0.2) : cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: isSettled ? Colors.grey : cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.personName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSettled ? Colors.grey : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppDateUtils.formatShortDate(loan.date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(loan.remainingAmount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSettled
                          ? Colors.grey
                          : (loan.remainingAmount > 0 ? cs.primary : Colors.green),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSettled ? Colors.grey.withValues(alpha: 0.2) : cs.tertiaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isSettled ? 'Settled' : 'Active',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isSettled ? Colors.grey : cs.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
