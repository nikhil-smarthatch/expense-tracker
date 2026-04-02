/// Types of notifications that can be triggered
enum NotificationType {
  goalMilestone,     // 25%, 50%, 75%, 100% of savings goal
  goalDeadline,      // Goal deadline approaching
  budgetWarning,     // Budget limit warning
  budgetExceeded,    // Budget exceeded
  billDue,           // Recurring bill due
  loanReminder,      // Loan repayment reminder
  debtPaidOff,       // Loan fully repaid
  goalCompleted,     // Savings goal achieved
}

/// Notification priority levels
enum NotificationPriority {
  low,
  medium,
  high,
  critical,
}

/// Smart notification model
class SmartNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final bool isRead;
  final String? actionRoute;  // Route to navigate when tapped
  final Map<String, dynamic>? payload;  // Additional data

  const SmartNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.createdAt,
    this.scheduledFor,
    this.isRead = false,
    this.actionRoute,
    this.payload,
  });

  SmartNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? createdAt,
    DateTime? scheduledFor,
    bool? isRead,
    String? actionRoute,
    Map<String, dynamic>? payload,
  }) {
    return SmartNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
      payload: payload ?? this.payload,
    );
  }
}

/// Extension methods for priority
extension NotificationPriorityExtension on NotificationPriority {
  int get value {
    switch (this) {
      case NotificationPriority.low:
        return 1;
      case NotificationPriority.medium:
        return 2;
      case NotificationPriority.high:
        return 3;
      case NotificationPriority.critical:
        return 4;
    }
  }

  String get label {
    switch (this) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.medium:
        return 'Medium';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.critical:
        return 'Critical';
    }
  }
}

/// Extension methods for notification type
extension NotificationTypeExtension on NotificationType {
  String get defaultTitle {
    switch (this) {
      case NotificationType.goalMilestone:
        return '🎯 Goal Milestone!';
      case NotificationType.goalDeadline:
        return '⏰ Goal Deadline Approaching';
      case NotificationType.budgetWarning:
        return '⚠️ Budget Warning';
      case NotificationType.budgetExceeded:
        return '🚨 Budget Exceeded';
      case NotificationType.billDue:
        return '💳 Bill Due';
      case NotificationType.loanReminder:
        return '📋 Loan Reminder';
      case NotificationType.debtPaidOff:
        return '🎉 Debt Paid Off!';
      case NotificationType.goalCompleted:
        return '🎊 Goal Achieved!';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.goalMilestone:
        return '🎯';
      case NotificationType.goalDeadline:
        return '⏰';
      case NotificationType.budgetWarning:
        return '⚠️';
      case NotificationType.budgetExceeded:
        return '🚨';
      case NotificationType.billDue:
        return '💳';
      case NotificationType.loanReminder:
        return '📋';
      case NotificationType.debtPaidOff:
        return '🎉';
      case NotificationType.goalCompleted:
        return '🎊';
    }
  }
}
