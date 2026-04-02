import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../notifications/domain/entities/smart_notification.dart';

/// Provider for managing notifications (placeholder - would connect to actual service)
final notificationsProvider = StateProvider<List<SmartNotification>>((ref) => []);

/// Screen for viewing all smart notifications
class NotificationsCenterScreen extends ConsumerWidget {
  const NotificationsCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                // Mark all as read
                ref.read(notificationsProvider.notifier).state = 
                    notifications.map((n) => n.copyWith(isRead: true)).toList();
              },
              child: const Text('Mark All Read'),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showNotificationSettings(context),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(context, notification, ref);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    SmartNotification notification,
    WidgetRef ref,
  ) {
    final priorityColor = _getPriorityColor(notification.priority);

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        // Remove notification
        final current = ref.read(notificationsProvider);
        ref.read(notificationsProvider.notifier).state =
            current.where((n) => n.id != notification.id).toList();
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: notification.isRead ? null : Colors.blue.shade50,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: priorityColor.withAlpha(51),
            child: Text(
              notification.type.icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.message),
              const SizedBox(height: 4),
              Text(
                _formatTime(notification.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          isThreeLine: true,
          onTap: () {
            // Mark as read
            if (!notification.isRead) {
              final current = ref.read(notificationsProvider);
              ref.read(notificationsProvider.notifier).state = current.map((n) {
                if (n.id == notification.id) {
                  return n.copyWith(isRead: true);
                }
                return n;
              }).toList();
            }
            // Navigate if action route exists
            if (notification.actionRoute != null) {
              // Navigator.of(context).pushNamed(notification.actionRoute!);
            }
          },
        ),
      ),
    );
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.critical:
        return Colors.red;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.medium:
        return Colors.blue;
      case NotificationPriority.low:
        return Colors.green;
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showNotificationSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Notification Settings'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Goal Milestones'),
              subtitle: const Text('25%, 50%, 75%, 100% reached'),
              value: true,
              onChanged: (_) {},
            ),
            SwitchListTile(
              title: const Text('Budget Alerts'),
              subtitle: const Text('Warnings when approaching limits'),
              value: true,
              onChanged: (_) {},
            ),
            SwitchListTile(
              title: const Text('Bill Reminders'),
              subtitle: const Text('Upcoming recurring payments'),
              value: true,
              onChanged: (_) {},
            ),
            SwitchListTile(
              title: const Text('Loan Reminders'),
              subtitle: const Text('Repayment due dates'),
              value: true,
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );
  }
}
