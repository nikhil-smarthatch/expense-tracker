import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../expense/presentation/screens/reports_screen.dart';
import 'data_export_screen.dart';

/// Settings screen providing access to all app features
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Preferences Section
          _buildSectionHeader(context, 'Preferences'),
          ListTile(
            leading: const Icon(Icons.currency_rupee),
            title: const Text('Currency'),
            subtitle: const Text('INR (Indian Rupee)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCurrencySelector(context),
          ),
          
          // Data Management Section
          _buildSectionHeader(context, 'Data Management'),
          ListTile(
            leading: const Icon(Icons.backup_rounded),
            title: const Text('Export & Backup'),
            subtitle: const Text('Export data to CSV/JSON'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DataExportScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Reports'),
            subtitle: const Text('View expense analytics and trends'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReportsScreen()),
            ),
          ),
          
          // About Section
          _buildSectionHeader(context, 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('App Version'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showCurrencySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Select Currency'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Divider(),
            RadioListTile<String>(
              title: const Text('Indian Rupee (₹)'),
              value: 'INR',
              groupValue: 'INR',
              onChanged: (_) => Navigator.pop(context),
            ),
            RadioListTile<String>(
              title: const Text('US Dollar (\$)'),
              value: 'USD',
              groupValue: 'INR',
              onChanged: (_) {},
            ),
            RadioListTile<String>(
              title: const Text('Euro (€)'),
              value: 'EUR',
              groupValue: 'INR',
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );
  }
}
