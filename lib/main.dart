import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/expense/data/models/expense_model.dart';
import 'features/expense/presentation/screens/expense_list_screen.dart';
import 'features/expense/presentation/screens/add_edit_expense_screen.dart';
import 'features/loan/presentation/screens/loan_list_screen.dart';
import 'features/loan/presentation/screens/add_edit_loan_screen.dart';
import 'features/loan/data/models/loan_model.dart';
import 'features/loan/data/models/repayment_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseModelAdapter());
  Hive.registerAdapter(LoanModelAdapter());
  Hive.registerAdapter(RepaymentModelAdapter());
  await Hive.openBox<ExpenseModel>(AppConstants.hiveExpenseBox);
  await Hive.openBox<double>(AppConstants.hiveBudgetBox);
  await Hive.openBox<LoanModel>(AppConstants.hiveLoansBox);
  await Hive.openBox<RepaymentModel>(AppConstants.hiveRepaymentsBox);

  runApp(
    const ProviderScope(
      child: ExpenseTrackerApp(),
    ),
  );
}

class ExpenseTrackerApp extends ConsumerWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    DashboardScreen(),
    ExpenseListScreen(),
    LoanListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt_rounded),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Loans',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 ? null : FloatingActionButton(
        onPressed: () {
          if (_currentIndex == 1) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddEditExpenseScreen()));
          } else if (_currentIndex == 2) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddEditLoanScreen()));
          }
        },
        tooltip: _currentIndex == 1 ? 'Add Expense' : 'Add Loan',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
