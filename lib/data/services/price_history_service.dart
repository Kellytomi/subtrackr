import 'package:subtrackr/domain/entities/subscription.dart';
import 'package:subtrackr/domain/entities/price_change.dart';
import 'package:subtrackr/core/constants/app_constants.dart';

/// Service to handle price history and cost calculations with historical pricing
class PriceHistoryService {
  static final PriceHistoryService _instance = PriceHistoryService._internal();
  
  factory PriceHistoryService() {
    return _instance;
  }
  
  PriceHistoryService._internal();

  /// Calculate total spent for a subscription considering price changes
  /// from startDate to endDate (defaults to now)
  double calculateTotalSpentWithHistory({
    required Subscription subscription,
    required List<PriceChange> priceChanges,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    final start = fromDate ?? subscription.startDate;
    final end = toDate ?? DateTime.now();
    
    // Sort price changes by effective date
    final sortedChanges = priceChanges
        .where((change) => change.subscriptionId == subscription.id)
        .toList()
      ..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));
    
    double totalSpent = 0.0;
    DateTime currentDate = start;
    double currentPrice = subscription.amount;
    
    // Get billing cycle duration in days
    final billingCycleDays = _getBillingCycleDays(subscription);
    
    while (currentDate.isBefore(end)) {
      // Find the next price change that affects this period
      final nextChange = sortedChanges.firstWhere(
        (change) => change.effectiveDate.isAfter(currentDate),
        orElse: () => PriceChange(
          subscriptionId: subscription.id,
          oldPrice: currentPrice,
          newPrice: currentPrice,
          effectiveDate: end,
        ),
      );
      
      // Calculate the period this price is active
      final periodEnd = nextChange.effectiveDate.isBefore(end) 
          ? nextChange.effectiveDate 
          : end;
      
      // Calculate how many billing cycles occur in this period
      final periodDays = periodEnd.difference(currentDate).inDays;
      final billingCycles = periodDays / billingCycleDays;
      
      // Add the cost for this period
      totalSpent += currentPrice * billingCycles;
      
      // Move to the next period
      currentDate = periodEnd;
      if (nextChange.effectiveDate.isBefore(end)) {
        currentPrice = nextChange.newPrice;
      }
    }
    
    return totalSpent;
  }

  /// Calculate monthly cost considering upcoming price changes
  double calculateMonthlySpentWithHistory({
    required Subscription subscription,
    required List<PriceChange> priceChanges,
    DateTime? forMonth,
  }) {
    final targetMonth = forMonth ?? DateTime.now();
    final monthStart = DateTime(targetMonth.year, targetMonth.month, 1);
    final monthEnd = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59);
    
    return calculateTotalSpentWithHistory(
      subscription: subscription,
      priceChanges: priceChanges,
      fromDate: monthStart,
      toDate: monthEnd,
    );
  }

  /// Calculate yearly cost considering price changes
  double calculateYearlySpentWithHistory({
    required Subscription subscription,
    required List<PriceChange> priceChanges,
    int? forYear,
  }) {
    final targetYear = forYear ?? DateTime.now().year;
    final yearStart = DateTime(targetYear, 1, 1);
    final yearEnd = DateTime(targetYear + 1, 1, 1);
    
    return calculateTotalSpentWithHistory(
      subscription: subscription,
      priceChanges: priceChanges,
      fromDate: yearStart,
      toDate: yearEnd,
    );
  }

  /// Get the current effective price for a subscription
  double getCurrentPrice({
    required Subscription subscription,
    required List<PriceChange> priceChanges,
    DateTime? asOf,
  }) {
    final targetDate = asOf ?? DateTime.now();
    
    // Find the most recent price change before or on the target date
    final applicableChanges = priceChanges
        .where((change) => 
            change.subscriptionId == subscription.id &&
            change.effectiveDate.isBefore(targetDate.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
    
    if (applicableChanges.isNotEmpty) {
      return applicableChanges.first.newPrice;
    }
    
    return subscription.amount;
  }

  /// Get upcoming price changes for a subscription
  List<PriceChange> getUpcomingPriceChanges({
    required Subscription subscription,
    required List<PriceChange> priceChanges,
    DateTime? fromDate,
  }) {
    final start = fromDate ?? DateTime.now();
    
    return priceChanges
        .where((change) => 
            change.subscriptionId == subscription.id &&
            change.effectiveDate.isAfter(start))
        .toList()
      ..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));
  }

  /// Calculate projected annual cost with known price changes
  double calculateProjectedAnnualCost({
    required Subscription subscription,
    required List<PriceChange> priceChanges,
    DateTime? fromDate,
  }) {
    final start = fromDate ?? DateTime.now();
    final end = DateTime(start.year + 1, start.month, start.day);
    
    return calculateTotalSpentWithHistory(
      subscription: subscription,
      priceChanges: priceChanges,
      fromDate: start,
      toDate: end,
    );
  }

  /// Create a price change for a subscription
  PriceChange createPriceChange({
    required String subscriptionId,
    required double oldPrice,
    required double newPrice,
    required DateTime effectiveDate,
    String? reason,
  }) {
    return PriceChange(
      subscriptionId: subscriptionId,
      oldPrice: oldPrice,
      newPrice: newPrice,
      effectiveDate: effectiveDate,
      reason: reason,
    );
  }

  /// Get billing cycle duration in days
  int _getBillingCycleDays(Subscription subscription) {
    switch (subscription.billingCycle) {
      case AppConstants.BILLING_CYCLE_MONTHLY:
        return 30; // Approximate
      case AppConstants.BILLING_CYCLE_QUARTERLY:
        return 90; // Approximate
      case AppConstants.BILLING_CYCLE_YEARLY:
        return 365; // Approximate
      case AppConstants.BILLING_CYCLE_CUSTOM:
        return subscription.customBillingDays ?? 30;
      default:
        return 30;
    }
  }

  /// Calculate cost breakdown for a time period
  Map<String, dynamic> calculateCostBreakdown({
    required Subscription subscription,
    required List<PriceChange> priceChanges,
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    final sortedChanges = priceChanges
        .where((change) => change.subscriptionId == subscription.id)
        .toList()
      ..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));
    
    final breakdown = <Map<String, dynamic>>[];
    DateTime currentDate = fromDate;
    double currentPrice = subscription.amount;
    double totalCost = 0.0;
    
    final billingCycleDays = _getBillingCycleDays(subscription);
    
    while (currentDate.isBefore(toDate)) {
      final nextChange = sortedChanges.firstWhere(
        (change) => change.effectiveDate.isAfter(currentDate),
        orElse: () => PriceChange(
          subscriptionId: subscription.id,
          oldPrice: currentPrice,
          newPrice: currentPrice,
          effectiveDate: toDate,
        ),
      );
      
      final periodEnd = nextChange.effectiveDate.isBefore(toDate) 
          ? nextChange.effectiveDate 
          : toDate;
      
      final periodDays = periodEnd.difference(currentDate).inDays;
      final billingCycles = periodDays / billingCycleDays;
      final periodCost = currentPrice * billingCycles;
      
      breakdown.add({
        'startDate': currentDate,
        'endDate': periodEnd,
        'price': currentPrice,
        'billingCycles': billingCycles,
        'cost': periodCost,
      });
      
      totalCost += periodCost;
      currentDate = periodEnd;
      if (nextChange.effectiveDate.isBefore(toDate)) {
        currentPrice = nextChange.newPrice;
      }
    }
    
    return {
      'breakdown': breakdown,
      'totalCost': totalCost,
      'period': {
        'start': fromDate,
        'end': toDate,
      },
    };
  }
} 