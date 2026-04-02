import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../income/domain/entities/savings_goal.dart';
import '../../expense/domain/entities/expense.dart';
import '../../loan/domain/entities/loan.dart';
import '../domain/entities/smart_notification.dart';

/// Service for generating and managing smart notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  /// Initialize notification plugin
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(initSettings);
  }

  /// Check for savings goal milestones and generate notifications
  List<SmartNotification> checkGoalMilestones(SavingsGoal goal) {
    final notifications = <SmartNotification>[];
    final progress = goal.progressPercentage;
    
    final milestones = [25.0, 50.0, 75.0, 100.0];
    
    for (final milestone in milestones) {
      // Check if we just crossed this milestone (within 1% tolerance)
      if (progress >= milestone && progress < milestone + 1) {
        final isCompleted = milestone == 100.0;
        
        notifications.add(SmartNotification(
          id: '${goal.id}_milestone_${milestone.toInt()}',
          title: isCompleted ? '🎊 Goal Achieved!' : '🎯 Milestone Reached!',
          message: isCompleted
              ? 'Congratulations! You\'ve reached your goal "${goal.title}"'
              : 'You\'ve saved ${milestone.toInt()}% of your goal "${goal.title}"',
          type: isCompleted ? NotificationType.goalCompleted : NotificationType.goalMilestone,
          priority: isCompleted ? NotificationPriority.high : NotificationPriority.medium,
          createdAt: DateTime.now(),
          actionRoute: '/savings-goals',
          payload: {'goalId': goal.id, 'milestone': milestone},
        ));
      }
    }
    
    return notifications;
  }

  /// Check for approaching goal deadlines
  SmartNotification? checkGoalDeadline(SavingsGoal goal) {
    if (goal.deadline == null || goal.isCompleted) return null;
    
    final daysUntilDeadline = goal.deadline!.difference(DateTime.now()).inDays;
    
    // Notify at 7 days, 3 days, and 1 day before deadline
    if ([7, 3, 1].contains(daysUntilDeadline)) {
      final urgency = daysUntilDeadline == 1 
          ? NotificationPriority.critical 
          : NotificationPriority.high;
      
      final remaining = goal.remainingAmount;
      final monthlyNeeded = goal.requiredMonthlySavings ?? 0;
      
      return SmartNotification(
        id: '${goal.id}_deadline_$daysUntilDeadline',
        title: '⏰ Goal Deadline in $daysUntilDeadline Day${daysUntilDeadline > 1 ? 's' : ''}',
        message: remaining > 0
            ? '"${goal.title}" needs ${remaining.toStringAsFixed(0)} more. Save ${monthlyNeeded.toStringAsFixed(0)}/month to reach it!'
            : '"${goal.title}" deadline approaching - you\'re almost there!',
        type: NotificationType.goalDeadline,
        priority: urgency,
        createdAt: DateTime.now(),
        actionRoute: '/savings-goals',
        payload: {'goalId': goal.id, 'daysLeft': daysUntilDeadline},
      );
    }
    
    return null;
  }

  /// Check budget status and generate warnings
  SmartNotification? checkBudgetStatus({
    required double monthlyBudget,
    required double currentSpending,
    required int daysInMonth,
    required int currentDay,
  }) {
    if (monthlyBudget <= 0) return null;
    
    final percentageUsed = (currentSpending / monthlyBudget) * 100;
    final daysElapsed = currentDay;
    final expectedProgress = (daysElapsed / daysInMonth) * 100;
    
    // Budget exceeded
    if (currentSpending > monthlyBudget) {
      final overage = currentSpending - monthlyBudget;
      return SmartNotification(
        id: 'budget_exceeded_${DateTime.now().month}',
        title: '🚨 Budget Exceeded',
        message: 'You\'ve exceeded your monthly budget by ${overage.toStringAsFixed(0)}. Consider reducing expenses for the rest of the month.',
        type: NotificationType.budgetExceeded,
        priority: NotificationPriority.critical,
        createdAt: DateTime.now(),
        actionRoute: '/expenses',
      );
    }
    
    // Budget warning at 80% usage or if ahead of schedule
    if (percentageUsed >= 80 || percentageUsed > expectedProgress + 20) {
      return SmartNotification(
        id: 'budget_warning_${DateTime.now().month}',
        title: '⚠️ Budget Warning',
        message: 'You\'ve used ${percentageUsed.toStringAsFixed(0)}% of your monthly budget. ${daysInMonth - currentDay} days remaining.',
        type: NotificationType.budgetWarning,
        priority: percentageUsed >= 90 ? NotificationPriority.high : NotificationPriority.medium,
        createdAt: DateTime.now(),
        actionRoute: '/expenses',
      );
    }
    
    return null;
  }

  /// Check for recurring bills due
  List<SmartNotification> checkRecurringBills(List<Expense> expenses) {
    final notifications = <SmartNotification>[];
    final now = DateTime.now();
    
    // Get recurring expenses that are bills
    final recurringBills = expenses.where((e) => 
      e.isRecurring && 
      !e.isIncome &&
      (e.category.name == 'bills' || e.category.name == 'utilities')
    );
    
    for (final bill in recurringBills) {
      // Check if bill is due in next 3 days
      final daysUntilDue = bill.date.difference(now).inDays;
      
      if (daysUntilDue >= 0 && daysUntilDue <= 3) {
        notifications.add(SmartNotification(
          id: '${bill.id}_due_$daysUntilDue',
          title: '💳 Bill Due${daysUntilDue == 0 ? ' Today' : ' in $daysUntilDue Days'}',
          message: '${bill.category.label}: ${bill.amount.toStringAsFixed(2)} is due${daysUntilDue == 0 ? ' today' : ' on ${bill.date.day}/${bill.date.month}'}',
          type: NotificationType.billDue,
          priority: daysUntilDue == 0 ? NotificationPriority.high : NotificationPriority.medium,
          createdAt: DateTime.now(),
          scheduledFor: bill.date,
          actionRoute: '/expenses',
          payload: {'expenseId': bill.id, 'amount': bill.amount},
        ));
      }
    }
    
    return notifications;
  }

  /// Check loan status and generate reminders
  List<SmartNotification> checkLoanReminders(List<Loan> loans) {
    final notifications = <SmartNotification>[];
    
    for (final loan in loans.where((l) => !l.isSettled)) {
      // Reminder for borrowed money (you owe)
      if (loan.type.name == 'borrow') {
        notifications.add(SmartNotification(
          id: '${loan.id}_reminder',
          title: '📋 Loan Reminder',
          message: 'You owe ${loan.personName}: ${loan.remainingAmount.toStringAsFixed(2)}',
          type: NotificationType.loanReminder,
          priority: loan.remainingAmount > loan.totalAmount * 0.5 
              ? NotificationPriority.high 
              : NotificationPriority.medium,
          createdAt: DateTime.now(),
          actionRoute: '/accounts',
          payload: {'loanId': loan.id, 'remaining': loan.remainingAmount},
        ));
      }
      
      // Notification when loan is fully paid off
      if (loan.remainingAmount <= 0 && !loan.isSettled) {
        notifications.add(SmartNotification(
          id: '${loan.id}_paid_off',
          title: '🎉 ${loan.type.name == 'borrow' ? 'Debt' : 'Loan'} Paid Off!',
          message: loan.type.name == 'borrow'
              ? 'You\'ve fully repaid ${loan.personName}!'
              : '${loan.personName} has fully repaid you!',
          type: NotificationType.debtPaidOff,
          priority: NotificationPriority.high,
          createdAt: DateTime.now(),
          actionRoute: '/accounts',
          payload: {'loanId': loan.id},
        ));
      }
    }
    
    return notifications;
  }

  /// Show local notification
  Future<void> showLocalNotification(SmartNotification notification) async {
    const androidDetails = AndroidNotificationDetails(
      'expense_tracker_channel',
      'Expense Tracker Notifications',
      channelDescription: 'Smart notifications for your finances',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      notification.id.hashCode,
      notification.title,
      notification.message,
      details,
      payload: notification.payload?.toString(),
    );
  }

  /// Schedule a future notification
  Future<void> scheduleNotification(SmartNotification notification) async {
    if (notification.scheduledFor == null) return;
    
    const androidDetails = AndroidNotificationDetails(
      'scheduled_channel',
      'Scheduled Notifications',
      channelDescription: 'Scheduled financial reminders',
    );
    
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _notifications.zonedSchedule(
      notification.id.hashCode,
      notification.title,
      notification.message,
      tz.TZDateTime.from(notification.scheduledFor!, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
