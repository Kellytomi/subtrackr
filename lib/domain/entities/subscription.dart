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
      id: this.id,
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
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
      billingCycle: map['billingCycle'],
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      renewalDate: DateTime.fromMillisecondsSinceEpoch(map['renewalDate']),
      status: map['status'],
      description: map['description'],
      website: map['website'],
      logoUrl: map['logoUrl'],
      customBillingDays: map['customBillingDays'],
      category: map['category'],
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      notificationDays: map['notificationDays'] ?? AppConstants.defaultNotificationDaysBeforeRenewal,
      paymentHistory: map['paymentHistory'] != null
          ? (map['paymentHistory'] as List)
              .map((timestamp) => DateTime.fromMillisecondsSinceEpoch(timestamp))
              .toList()
          : null,
      currencyCode: map['currencyCode'] ?? 'USD',
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
  
  // Check if the subscription is due soon (within the next 7 days)
  bool get isDueSoon {
    if (status != AppConstants.statusActive) return false;
    
    final now = DateTime.now();
    final difference = renewalDate.difference(now).inDays;
    return difference >= 0 && difference <= 7;
  }
  
  // Check if the subscription is overdue
  bool get isOverdue {
    if (status != AppConstants.statusActive) return false;
    
    final now = DateTime.now();
    return renewalDate.isBefore(now);
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
} 