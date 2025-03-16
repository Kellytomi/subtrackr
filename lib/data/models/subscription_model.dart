import 'package:hive/hive.dart';
import 'package:subtrackr/domain/entities/subscription.dart';

part 'subscription_model.g.dart';

@HiveType(typeId: 0)
class SubscriptionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String billingCycle;

  @HiveField(4)
  final DateTime startDate;

  @HiveField(5)
  final DateTime renewalDate;

  @HiveField(6)
  final String status;

  @HiveField(7)
  final String? description;

  @HiveField(8)
  final String? website;

  @HiveField(9)
  final String? logoUrl;

  @HiveField(10)
  final int? customBillingDays;

  @HiveField(11)
  final String? category;

  @HiveField(12)
  final bool notificationsEnabled;

  @HiveField(13)
  final int notificationDays;

  @HiveField(14)
  final List<DateTime>? paymentHistory;
  
  @HiveField(15)
  final String currencyCode;

  SubscriptionModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.billingCycle,
    required this.startDate,
    required this.renewalDate,
    required this.status,
    this.description,
    this.website,
    this.logoUrl,
    this.customBillingDays,
    this.category,
    required this.notificationsEnabled,
    required this.notificationDays,
    this.paymentHistory,
    this.currencyCode = 'USD',
  });

  // Convert from domain entity to Hive model
  factory SubscriptionModel.fromEntity(Subscription subscription) {
    return SubscriptionModel(
      id: subscription.id,
      name: subscription.name,
      amount: subscription.amount,
      billingCycle: subscription.billingCycle,
      startDate: subscription.startDate,
      renewalDate: subscription.renewalDate,
      status: subscription.status,
      description: subscription.description,
      website: subscription.website,
      logoUrl: subscription.logoUrl,
      customBillingDays: subscription.customBillingDays,
      category: subscription.category,
      notificationsEnabled: subscription.notificationsEnabled,
      notificationDays: subscription.notificationDays,
      paymentHistory: subscription.paymentHistory,
      currencyCode: subscription.currencyCode,
    );
  }

  // Convert from Hive model to domain entity
  Subscription toEntity() {
    return Subscription(
      id: id,
      name: name,
      amount: amount,
      billingCycle: billingCycle,
      startDate: startDate,
      renewalDate: renewalDate,
      status: status,
      description: description,
      website: website,
      logoUrl: logoUrl,
      customBillingDays: customBillingDays,
      category: category,
      notificationsEnabled: notificationsEnabled,
      notificationDays: notificationDays,
      paymentHistory: paymentHistory,
      currencyCode: currencyCode,
    );
  }
} 