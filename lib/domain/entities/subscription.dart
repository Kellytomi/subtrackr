import 'package:uuid/uuid.dart';
import 'package:subtrackr/core/constants/app_constants.dart';

class Subscription {
  final String id;
  final String name;
  final double amount;
  final String billingCycle; // monthly, quarterly, yearly, custom
  final DateTime startDate;
  final DateTime renewalDate;
  final String status; // active, paused, cancelled
  final String? description;
  final String? website;
  final String? logoUrl;
  final int? customBillingDays; // Only used if billingCycle is custom
  final String? category;
  final bool notificationsEnabled;
  final int notificationDays; // Days before renewal to send notification
  final List<DateTime>? paymentHistory;
  final String currencyCode; // Currency code (e.g., USD, EUR, NGN)
  
  Subscription({
    String? id,
    required this.name,
    required this.amount,
    required this.billingCycle,
    required this.startDate,
    required this.renewalDate,
    this.status = AppConstants.statusActive,
    this.description,
    this.website,
    this.logoUrl,
    this.customBillingDays,
    this.category,
    this.notificationsEnabled = true,
    this.notificationDays = AppConstants.defaultNotificationDaysBeforeRenewal,
    this.paymentHistory,
    this.currencyCode = 'USD', // Default to USD
  }) : id = id ?? const Uuid().v4();
  
  // Create a copy of this subscription with some fields updated
  Subscription copyWith({
    String? name,
    double? amount,
    String? billingCycle,
    DateTime? startDate,
    DateTime? renewalDate,
    String? status,
    String? description,
    String? website,
    String? logoUrl,
    int? customBillingDays,
    String? category,
    bool? notificationsEnabled,
    int? notificationDays,
    List<DateTime>? paymentHistory,
    String? currencyCode,
  }) {
    return Subscription(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      billingCycle: billingCycle ?? this.billingCycle,
      startDate: startDate ?? this.startDate,
      renewalDate: renewalDate ?? this.renewalDate,
      status: status ?? this.status,
      description: description ?? this.description,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      customBillingDays: customBillingDays ?? this.customBillingDays,
      category: category ?? this.category,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationDays: notificationDays ?? this.notificationDays,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }
  
  // Convert subscription to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'billingCycle': billingCycle,
      'startDate': startDate.millisecondsSinceEpoch,
      'renewalDate': renewalDate.millisecondsSinceEpoch,
      'status': status,
      'description': description,
      'website': website,
      'logoUrl': logoUrl,
      'customBillingDays': customBillingDays,
      'category': category,
      'notificationsEnabled': notificationsEnabled,
      'notificationDays': notificationDays,
      'paymentHistory': paymentHistory?.map((date) => date.millisecondsSinceEpoch).toList(),
      'currencyCode': currencyCode,
    };
  }
  
  // Create a subscription from a map
  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      billingCycle: map['billingCycle'] as String? ?? AppConstants.billingCycleMonthly,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int? ?? 0),
      renewalDate: DateTime.fromMillisecondsSinceEpoch(map['renewalDate'] as int? ?? 0),
      status: map['status'] as String? ?? AppConstants.statusActive,
      description: map['description'] as String?,
      website: map['website'] as String?,
      logoUrl: map['logoUrl'] as String?,
      customBillingDays: map['customBillingDays'] as int?,
      category: map['category'] as String?,
      notificationsEnabled: (map['notificationsEnabled'] as bool?) ?? true,
      notificationDays: (map['notificationDays'] as int?) ?? AppConstants.defaultNotificationDaysBeforeRenewal,
      paymentHistory: map['paymentHistory'] != null
          ? (map['paymentHistory'] as List<dynamic>)
              .map((timestamp) => DateTime.fromMillisecondsSinceEpoch(timestamp as int))
              .toList()
          : null,
      currencyCode: map['currencyCode'] as String? ?? 'USD',
    );
  }
  
  // Calculate monthly cost
  double get monthlyCost {
    switch (billingCycle) {
      case AppConstants.billingCycleMonthly:
        return amount;
      case AppConstants.billingCycleQuarterly:
        return amount / 3;
      case AppConstants.billingCycleYearly:
        return amount / 12;
      case AppConstants.billingCycleCustom:
        if (customBillingDays != null && customBillingDays! > 0) {
          return amount * 30 / customBillingDays!;
        }
        return amount;
      default:
        return amount;
    }
  }
  
  // Calculate yearly cost
  double get yearlyCost {
    switch (billingCycle) {
      case AppConstants.billingCycleMonthly:
        return amount * 12;
      case AppConstants.billingCycleQuarterly:
        return amount * 4;
      case AppConstants.billingCycleYearly:
        return amount;
      case AppConstants.billingCycleCustom:
        if (customBillingDays != null && customBillingDays! > 0) {
          return amount * 365 / customBillingDays!;
        }
        return amount;
      default:
        return amount;
    }
  }
  
  // Get the billing cycle as a human-readable string
  String get billingCycleText {
    switch (billingCycle) {
      case AppConstants.billingCycleMonthly:
        return 'Monthly';
      case AppConstants.billingCycleQuarterly:
        return 'Quarterly';
      case AppConstants.billingCycleYearly:
        return 'Yearly';
      case AppConstants.billingCycleCustom:
        if (customBillingDays != null) {
          return 'Every $customBillingDays days';
        }
        return 'Custom';
      default:
        return 'Unknown';
    }
  }
  
  // Get the status as a human-readable string
  String get statusText {
    switch (status) {
      case AppConstants.statusActive:
        return 'Active';
      case AppConstants.statusPaused:
        return 'Paused';
      case AppConstants.statusCancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
  
  // Check if the subscription is due soon (within the next 3 days)
  bool get isDueSoon {
    if (status != AppConstants.statusActive) return false;
    
    final now = DateTime.now();
    final difference = renewalDate.difference(now).inDays;
    return difference >= 0 && difference <= 3;
  }
  
  // Check if the subscription is overdue
  bool get isOverdue {
    if (status != AppConstants.statusActive) return false;
    
    final now = DateTime.now();
    // Compare only the dates, not the times
    final today = DateTime(now.year, now.month, now.day);
    final renewalDateOnly = DateTime(renewalDate.year, renewalDate.month, renewalDate.day);
    
    // Only overdue if strictly before today (not today)
    return renewalDateOnly.isBefore(today);
  }
  
  // Get days until renewal
  int get daysUntilRenewal {
    final now = DateTime.now();
    return renewalDate.difference(now).inDays;
  }
  
  // Add a payment to the history
  Subscription addPayment(DateTime paymentDate) {
    final updatedHistory = paymentHistory?.toList() ?? [];
    updatedHistory.add(paymentDate);
    return copyWith(paymentHistory: updatedHistory);
  }
  
  // Pause the subscription
  Subscription pause() {
    return copyWith(status: AppConstants.statusPaused);
  }
  
  // Resume the subscription
  Subscription resume() {
    return copyWith(status: AppConstants.statusActive);
  }
  
  // Cancel the subscription
  Subscription cancel() {
    return copyWith(status: AppConstants.statusCancelled);
  }
  
  // Mark subscription as paid and update renewal date
  Subscription markAsPaid() {
    // Add current date to payment history
    final updatedHistory = paymentHistory?.toList() ?? [];
    final paymentDate = DateTime.now();
    updatedHistory.add(paymentDate);
    
    // Calculate next renewal date based on the original pattern
    // We calculate from the current renewal date, not from the payment date
    DateTime nextRenewal;
    switch (billingCycle) {
      case AppConstants.billingCycleMonthly:
        // Keep the same day of month for the next renewal
        final nextMonth = renewalDate.month + 1;
        final nextYear = renewalDate.year + (nextMonth > 12 ? 1 : 0);
        final adjustedMonth = nextMonth > 12 ? nextMonth - 12 : nextMonth;
        
        // Handle edge cases like the 31st of a month that doesn't have 31 days
        final lastDayOfMonth = DateTime(nextYear, adjustedMonth + 1, 0).day;
        final nextDay = renewalDate.day > lastDayOfMonth ? lastDayOfMonth : renewalDate.day;
        
        nextRenewal = DateTime(nextYear, adjustedMonth, nextDay);
        
        // If the calculated date is in the past, move forward another month
        if (nextRenewal.isBefore(paymentDate)) {
          final oneMoreMonth = nextRenewal.month + 1;
          final oneMoreYear = nextRenewal.year + (oneMoreMonth > 12 ? 1 : 0);
          final finalMonth = oneMoreMonth > 12 ? oneMoreMonth - 12 : oneMoreMonth;
          
          // Handle edge cases again
          final daysInFinalMonth = DateTime(oneMoreYear, finalMonth + 1, 0).day;
          final finalDay = nextRenewal.day > daysInFinalMonth ? daysInFinalMonth : nextRenewal.day;
          
          nextRenewal = DateTime(oneMoreYear, finalMonth, finalDay);
        }
        break;
      case AppConstants.billingCycleQuarterly:
        // Keep the same day but add 3 months
        final nextMonth = renewalDate.month + 3;
        final nextYear = renewalDate.year + (nextMonth > 12 ? 1 : 0);
        final adjustedMonth = nextMonth > 12 ? nextMonth - 12 : nextMonth;
        
        // Handle edge cases
        final lastDayOfMonth = DateTime(nextYear, adjustedMonth + 1, 0).day;
        final nextDay = renewalDate.day > lastDayOfMonth ? lastDayOfMonth : renewalDate.day;
        
        nextRenewal = DateTime(nextYear, adjustedMonth, nextDay);
        
        // If the calculated date is in the past, move forward another quarter
        if (nextRenewal.isBefore(paymentDate)) {
          final oneMoreQuarter = nextRenewal.month + 3;
          final oneMoreYear = nextRenewal.year + (oneMoreQuarter > 12 ? 1 : 0);
          final finalMonth = oneMoreQuarter > 12 ? oneMoreQuarter - 12 : oneMoreQuarter;
          
          // Handle edge cases again
          final daysInFinalMonth = DateTime(oneMoreYear, finalMonth + 1, 0).day;
          final finalDay = nextRenewal.day > daysInFinalMonth ? daysInFinalMonth : nextRenewal.day;
          
          nextRenewal = DateTime(oneMoreYear, finalMonth, finalDay);
        }
        break;
      case AppConstants.billingCycleYearly:
        // Keep the same day and month, but add a year
        final nextYear = renewalDate.year + 1;
        
        // Handle Feb 29 for leap years
        if (renewalDate.month == 2 && renewalDate.day == 29) {
          final isLeapYear = (nextYear % 4 == 0 && nextYear % 100 != 0) || nextYear % 400 == 0;
          final nextDay = isLeapYear ? 29 : 28;
          nextRenewal = DateTime(nextYear, 2, nextDay);
        } else {
          nextRenewal = DateTime(nextYear, renewalDate.month, renewalDate.day);
        }
        
        // If the calculated date is in the past, add another year
        if (nextRenewal.isBefore(paymentDate)) {
          nextRenewal = DateTime(nextRenewal.year + 1, nextRenewal.month, nextRenewal.day);
        }
        break;
      case AppConstants.billingCycleCustom:
        if (customBillingDays != null) {
          // For custom, we do add from the renewal date
          nextRenewal = renewalDate.add(Duration(days: customBillingDays!));
          
          // If next renewal is in the past, keep adding cycles until it's in the future
          while (nextRenewal.isBefore(paymentDate)) {
            nextRenewal = nextRenewal.add(Duration(days: customBillingDays!));
          }
        } else {
          // Default to monthly if custom days is not provided
          final nextMonth = renewalDate.month + 1;
          final nextYear = renewalDate.year + (nextMonth > 12 ? 1 : 0);
          final adjustedMonth = nextMonth > 12 ? nextMonth - 12 : nextMonth;
          nextRenewal = DateTime(nextYear, adjustedMonth, renewalDate.day);
          
          if (nextRenewal.isBefore(paymentDate)) {
            final oneMoreMonth = nextRenewal.month + 1;
            final oneMoreYear = nextRenewal.year + (oneMoreMonth > 12 ? 1 : 0);
            final finalMonth = oneMoreMonth > 12 ? oneMoreMonth - 12 : oneMoreMonth;
            nextRenewal = DateTime(oneMoreYear, finalMonth, nextRenewal.day);
          }
        }
        break;
      default:
        // Default to monthly
        final nextMonth = renewalDate.month + 1;
        final nextYear = renewalDate.year + (nextMonth > 12 ? 1 : 0);
        final adjustedMonth = nextMonth > 12 ? nextMonth - 12 : nextMonth;
        nextRenewal = DateTime(nextYear, adjustedMonth, renewalDate.day);
        
        if (nextRenewal.isBefore(paymentDate)) {
          final oneMoreMonth = nextRenewal.month + 1;
          final oneMoreYear = nextRenewal.year + (oneMoreMonth > 12 ? 1 : 0);
          final finalMonth = oneMoreMonth > 12 ? oneMoreMonth - 12 : oneMoreMonth;
          nextRenewal = DateTime(oneMoreYear, finalMonth, nextRenewal.day);
        }
    }
    
    // Return updated subscription
    return copyWith(
      paymentHistory: updatedHistory,
      renewalDate: nextRenewal,
      status: AppConstants.statusActive, // Ensure subscription is active
    );
  }
} 