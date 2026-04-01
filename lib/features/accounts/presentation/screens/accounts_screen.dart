import 'package:flutter/material.dart';
import '../../../loan/presentation/screens/loan_list_screen.dart';
import '../../../credit_card/presentation/screens/credit_card_list_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Accounts & Liabilities'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Loans'),
              Tab(text: 'Credit Cards'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            LoanListScreen(),
            CreditCardListScreen(),
          ],
        ),
      ),
    );
  }
}
