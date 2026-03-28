import 'package:intl/intl.dart';

/// Date utility helpers used across the app.
class AppDateUtils {
  AppDateUtils._();

  static String formatDate(DateTime date) =>
      DateFormat('MMM dd, yyyy').format(date);

  static String formatMonthYear(DateTime date) =>
      DateFormat('MMMM yyyy').format(date);

  static String formatShortDate(DateTime date) =>
      DateFormat('MMM dd').format(date);

  static String formatDay(DateTime date) => DateFormat('d').format(date);

  static bool isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59);

  /// Returns a list of all days in the month of [date].
  static List<DateTime> daysInMonth(DateTime date) {
    final start = startOfMonth(date);
    final end = endOfMonth(date);
    return List.generate(
      end.day,
      (i) => DateTime(start.year, start.month, start.day + i),
    );
  }
}
