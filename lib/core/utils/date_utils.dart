import 'package:intl/intl.dart';

class AppDateUtils {
  // Format a date to a readable string (e.g., "Jan 15, 2023")
  static String formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }
  
  // Format a date to show only the month and day (e.g., "Jan 15")
  static String formatMonthDay(DateTime date) {
    return DateFormat.MMMd().format(date);
  }
  
  // Format a date to show the full date with time (e.g., "Jan 15, 2023 14:30")
  static String formatDateWithTime(DateTime date) {
    return DateFormat.yMMMd().add_Hm().format(date);
  }
  
  // Calculate the next renewal date based on the billing cycle
  static DateTime calculateNextRenewalDate(DateTime startDate, String billingCycle, [int? customDays]) {
    final now = DateTime.now();
    DateTime nextRenewal = startDate;
    
    // Keep adding billing cycles until we find a date in the future
    while (nextRenewal.isBefore(now)) {
      switch (billingCycle) {
        case 'monthly':
          nextRenewal = DateTime(
            nextRenewal.year,
            nextRenewal.month + 1,
            nextRenewal.day,
          );
          break;
        case 'quarterly':
          nextRenewal = DateTime(
            nextRenewal.year,
            nextRenewal.month + 3,
            nextRenewal.day,
          );
          break;
        case 'yearly':
          nextRenewal = DateTime(
            nextRenewal.year + 1,
            nextRenewal.month,
            nextRenewal.day,
          );
          break;
        case 'custom':
          if (customDays != null) {
            nextRenewal = nextRenewal.add(Duration(days: customDays));
          } else {
            // Default to monthly if custom days is not provided
            nextRenewal = DateTime(
              nextRenewal.year,
              nextRenewal.month + 1,
              nextRenewal.day,
            );
          }
          break;
        default:
          // Default to monthly
          nextRenewal = DateTime(
            nextRenewal.year,
            nextRenewal.month + 1,
            nextRenewal.day,
          );
      }
    }
    
    return nextRenewal;
  }
  
  // Calculate days remaining until a date
  static int daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    
    return targetDate.difference(today).inDays;
  }
  
  // Check if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  // Check if a date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
  }
  
  // Get a human-readable string for days remaining (e.g., "Today", "Tomorrow", "3 days")
  static String getDaysRemainingText(DateTime date) {
    if (isToday(date)) {
      return 'Today';
    } else if (isTomorrow(date)) {
      return 'Tomorrow';
    } else {
      final days = daysUntil(date);
      return '$days ${days == 1 ? 'day' : 'days'}';
    }
  }
  
  // Get the month name from a date
  static String getMonthName(DateTime date) {
    return DateFormat.MMMM().format(date);
  }
  
  // Get the year from a date
  static String getYear(DateTime date) {
    return DateFormat.y().format(date);
  }
  
  // Get the first day of the current month
  static DateTime getFirstDayOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }
  
  // Get the last day of the current month
  static DateTime getLastDayOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0);
  }
  
  // Get the first day of the current year
  static DateTime getFirstDayOfYear() {
    final now = DateTime.now();
    return DateTime(now.year, 1, 1);
  }
  
  // Get the last day of the current year
  static DateTime getLastDayOfYear() {
    final now = DateTime.now();
    return DateTime(now.year, 12, 31);
  }
} 