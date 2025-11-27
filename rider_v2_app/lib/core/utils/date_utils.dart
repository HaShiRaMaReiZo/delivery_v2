import 'package:intl/intl.dart';

class MyanmarDateUtils {
  // Myanmar timezone offset: UTC+6:30
  static const int myanmarOffsetHours = 6;
  static const int myanmarOffsetMinutes = 30;

  /// Convert UTC DateTime to Myanmar local time (UTC+6:30)
  static DateTime toMyanmarTime(DateTime utcDateTime) {
    return utcDateTime.add(
      Duration(hours: myanmarOffsetHours, minutes: myanmarOffsetMinutes),
    );
  }

  /// Get current time in Myanmar timezone
  static DateTime getMyanmarNow() {
    return toMyanmarTime(DateTime.now().toUtc());
  }

  /// Format date as "Today", "Yesterday", or "Mon DD, YYYY"
  static String formatDate(DateTime utcDateTime) {
    final myanmarTime = toMyanmarTime(utcDateTime);
    final now = getMyanmarNow();

    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(myanmarTime.year, myanmarTime.month, myanmarTime.day);

    if (date == today) {
      return 'Today';
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd, yyyy').format(myanmarTime);
    }
  }

  /// Format date and time as "DD/MM/YYYY HH:MM"
  static String formatDateTime(DateTime utcDateTime) {
    final myanmarTime = toMyanmarTime(utcDateTime);
    return DateFormat('dd/MM/yyyy HH:mm').format(myanmarTime);
  }

  /// Format date only as "DD/MM/YYYY"
  static String formatDateOnly(DateTime utcDateTime) {
    final myanmarTime = toMyanmarTime(utcDateTime);
    return DateFormat('dd/MM/yyyy').format(myanmarTime);
  }

  /// Get date key for grouping (returns DateTime with only date part in Myanmar time)
  static DateTime getDateKey(DateTime utcDateTime) {
    final myanmarTime = toMyanmarTime(utcDateTime);
    return DateTime(myanmarTime.year, myanmarTime.month, myanmarTime.day);
  }
}
