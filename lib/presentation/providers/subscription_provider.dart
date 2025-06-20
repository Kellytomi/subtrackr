import 'package:flutter/material.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/core/utils/date_utils.dart';
import 'package:subtrackr/data/repositories/subscription_repository.dart';
import 'package:subtrackr/data/repositories/price_change_repository.dart';
import 'package:subtrackr/data/services/notification_service.dart';
import 'package:subtrackr/data/services/settings_service.dart';
import 'package:subtrackr/data/services/price_history_service.dart';
import 'package:subtrackr/domain/entities/subscription.dart';
import 'package:subtrackr/domain/entities/price_change.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionRepository _repository;
  final PriceChangeRepository _priceChangeRepository;
  final NotificationService _notificationService;
  final SettingsService _settingsService;
  final PriceHistoryService _priceHistoryService;
  
  List<Subscription> _subscriptions = [];
  bool _isLoading = false;
  String? _error;
  
  SubscriptionProvider({
    required SubscriptionRepository repository,
    required PriceChangeRepository priceChangeRepository,
    required NotificationService notificationService,
    required SettingsService settingsService,
  })  : _repository = repository,
        _priceChangeRepository = priceChangeRepository,
        _notificationService = notificationService,
        _settingsService = settingsService,
        _priceHistoryService = PriceHistoryService();
  
  // Getters
  List<Subscription> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Get active subscriptions
  List<Subscription> get activeSubscriptions => _subscriptions
      .where((subscription) => subscription.status == AppConstants.STATUS_ACTIVE)
      .toList();
  
  // Get paused subscriptions
  List<Subscription> get pausedSubscriptions => _subscriptions
      .where((subscription) => subscription.status == AppConstants.STATUS_PAUSED)
      .toList();
  
  // Get cancelled subscriptions
  List<Subscription> get cancelledSubscriptions => _subscriptions
      .where((subscription) => subscription.status == AppConstants.STATUS_CANCELLED)
      .toList();
  
  // Get subscriptions due soon (within the next 3 days)
  List<Subscription> get subscriptionsDueSoon => _subscriptions
      .where((subscription) => 
          subscription.status == AppConstants.STATUS_ACTIVE &&
          subscription.isDueSoon)
      .toList();
  
  // Get overdue subscriptions
  List<Subscription> get overdueSubscriptions => _subscriptions
      .where((subscription) => 
          subscription.status == AppConstants.STATUS_ACTIVE &&
          subscription.isOverdue)
      .toList();
  
  // Get total monthly spending
  double get totalMonthlySpending => activeSubscriptions
      .fold<double>(0, (total, subscription) => total + subscription.monthlyCost);
  
  // Get total yearly spending
  double get totalYearlySpending => activeSubscriptions
      .fold<double>(0, (total, subscription) => total + subscription.yearlyCost);
  
  // Get total monthly spending grouped by currency
  Map<String, double> get totalMonthlySpendingByCurrency {
    final map = <String, double>{};
    
    for (final subscription in activeSubscriptions) {
      final currencyCode = subscription.currencyCode;
      if (!map.containsKey(currencyCode)) {
        map[currencyCode] = 0;
      }
      map[currencyCode] = map[currencyCode]! + subscription.monthlyCost;
    }
    
    return map;
  }
  
  // Get total yearly spending grouped by currency
  Map<String, double> get totalYearlySpendingByCurrency {
    final map = <String, double>{};
    
    for (final subscription in activeSubscriptions) {
      final currencyCode = subscription.currencyCode;
      if (!map.containsKey(currencyCode)) {
        map[currencyCode] = 0;
      }
      map[currencyCode] = map[currencyCode]! + subscription.yearlyCost;
    }
    
    return map;
  }
  
  // Get subscriptions grouped by currency
  Map<String, List<Subscription>> get subscriptionsByCurrency {
    final map = <String, List<Subscription>>{};
    
    for (final subscription in _subscriptions) {
      final currencyCode = subscription.currencyCode;
      if (!map.containsKey(currencyCode)) {
        map[currencyCode] = [];
      }
      map[currencyCode]!.add(subscription);
    }
    
    return map;
  }
  
  // Get subscriptions by category
  Map<String?, List<Subscription>> get subscriptionsByCategory {
    final map = <String?, List<Subscription>>{};
    
    for (final subscription in _subscriptions) {
      final category = subscription.category;
      if (!map.containsKey(category)) {
        map[category] = [];
      }
      map[category]!.add(subscription);
    }
    
    return map;
  }
  
  // Load all subscriptions
  Future<void> loadSubscriptions() async {
    if (_isLoading) return; // Prevent concurrent loads
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final loadedSubscriptions = _repository.getAllSubscriptions();
      loadedSubscriptions.sort((a, b) => a.name.compareTo(b.name)); // Sort alphabetically
      
      // Ensure each subscription has a valid currency code
      for (int i = 0; i < loadedSubscriptions.length; i++) {
        final subscription = loadedSubscriptions[i];
        if (subscription.currencyCode.isEmpty) {
          // If currency code is empty, use the default currency code
          final updatedSubscription = subscription.copyWith(
            currencyCode: _settingsService.getCurrencyCode() ?? AppConstants.DEFAULT_CURRENCY_CODE,
          );
          loadedSubscriptions[i] = updatedSubscription;
          await _repository.updateSubscription(updatedSubscription);
        }
      }
      
      _subscriptions = loadedSubscriptions;
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = AppConstants.ERROR_LOADING_SUBSCRIPTIONS;
      notifyListeners();
    }
  }
  
  // Add a new subscription
  Future<void> addSubscription(Subscription subscription) async {
    try {
      await _repository.addSubscription(subscription);
      _subscriptions = [..._subscriptions, subscription];
      _subscriptions.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
      
      // Schedule notification if active
      if (subscription.status == AppConstants.STATUS_ACTIVE) {
        _scheduleNotification(subscription);
      }
    } catch (e) {
      _error = AppConstants.ERROR_ADDING_SUBSCRIPTION;
      notifyListeners();
    }
  }
  
  // Update a subscription
  Future<void> updateSubscription(Subscription subscription) async {
    try {
      await _repository.updateSubscription(subscription);
      _subscriptions = _subscriptions.map((s) => 
        s.id == subscription.id ? subscription : s
      ).toList();
      _subscriptions.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
      
      // Update notification if active
      if (subscription.status == AppConstants.STATUS_ACTIVE) {
        _scheduleNotification(subscription);
      } else {
        await _notificationService.cancelNotification(subscription.id.hashCode);
      }
    } catch (e) {
      _error = AppConstants.ERROR_UPDATING_SUBSCRIPTION;
      notifyListeners();
    }
  }
  
  // Delete a subscription
  Future<void> deleteSubscription(String id) async {
    try {
      await _repository.deleteSubscription(id);
      await _notificationService.cancelNotification(id.hashCode);
      _subscriptions = _subscriptions.where((s) => s.id != id).toList();
      notifyListeners();
    } catch (e) {
      _error = AppConstants.ERROR_DELETING_SUBSCRIPTION;
      notifyListeners();
    }
  }
  
  // Mark subscription as paid
  Future<void> markSubscriptionAsPaid(String id) async {
    try {
      final subscription = _subscriptions.firstWhere(
        (s) => s.id == id,
        orElse: () => throw Exception('Subscription not found'),
      );
      final nextRenewalDate = AppDateUtils.calculateNextRenewalDate(
        subscription.renewalDate,
        subscription.billingCycle,
        subscription.customBillingDays,
      );
      
      final updatedSubscription = subscription.copyWith(
        renewalDate: nextRenewalDate,
      );
      
      await _repository.updateSubscription(updatedSubscription);
      await loadSubscriptions(); // Reload to ensure proper state update
      
      // Reschedule notification
      _scheduleNotification(updatedSubscription);
    } catch (e) {
      _error = AppConstants.ERROR_UPDATING_SUBSCRIPTION;
      notifyListeners();
    }
  }
  
  // Pause subscription
  Future<void> pauseSubscription(String id) async {
    try {
      final subscription = _subscriptions.firstWhere(
        (s) => s.id == id,
        orElse: () => throw Exception('Subscription not found'),
      );
      final updatedSubscription = subscription.copyWith(
        status: AppConstants.STATUS_PAUSED,
      );
      
      await _repository.updateSubscription(updatedSubscription);
      await _notificationService.cancelNotification(id.hashCode);
      await loadSubscriptions(); // Reload to ensure proper state update
    } catch (e) {
      _error = AppConstants.ERROR_UPDATING_SUBSCRIPTION;
      notifyListeners();
    }
  }
  
  // Resume subscription
  Future<void> resumeSubscription(String id) async {
    try {
      final subscription = _subscriptions.firstWhere(
        (s) => s.id == id,
        orElse: () => throw Exception('Subscription not found'),
      );
      final updatedSubscription = subscription.copyWith(
        status: AppConstants.STATUS_ACTIVE,
      );
      
      await _repository.updateSubscription(updatedSubscription);
      _scheduleNotification(updatedSubscription);
      await loadSubscriptions(); // Reload to ensure proper state update
    } catch (e) {
      _error = AppConstants.ERROR_UPDATING_SUBSCRIPTION;
      notifyListeners();
    }
  }
  
  // Cancel subscription
  Future<void> cancelSubscription(String id) async {
    try {
      final subscription = _subscriptions.firstWhere(
        (s) => s.id == id,
        orElse: () => throw Exception('Subscription not found'),
      );
      final updatedSubscription = subscription.copyWith(
        status: AppConstants.STATUS_CANCELLED,
      );
      
      await _repository.updateSubscription(updatedSubscription);
      await _notificationService.cancelNotification(id.hashCode);
      await loadSubscriptions(); // Reload to ensure proper state update
    } catch (e) {
      _error = AppConstants.ERROR_UPDATING_SUBSCRIPTION;
      notifyListeners();
    }
  }
  
  // Add a payment to a subscription
  Future<void> addPayment(String id, DateTime paymentDate) async {
    try {
      final subscription = _subscriptions.firstWhere(
        (s) => s.id == id,
        orElse: () => throw Exception('Subscription not found'),
      );
      final updatedSubscription = subscription.addPayment(paymentDate);
      await updateSubscription(updatedSubscription);
    } catch (e) {
      _error = AppConstants.ERROR_UPDATING_SUBSCRIPTION;
      notifyListeners();
    }
  }

  // Add a price change to a subscription
  Future<void> addPriceChange(PriceChange priceChange) async {
    try {
      await _priceChangeRepository.addPriceChange(priceChange);
      
      // If the price change is effective now or in the past, update the subscription price
      if (priceChange.effectiveDate.isBefore(DateTime.now().add(const Duration(days: 1)))) {
        final subscription = _subscriptions.firstWhere(
          (s) => s.id == priceChange.subscriptionId,
          orElse: () => throw Exception('Subscription not found'),
        );
        
        final updatedSubscription = subscription.copyWith(
          amount: priceChange.newPrice,
        );
        
        await updateSubscription(updatedSubscription);
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Error adding price change';
      notifyListeners();
    }
  }

  // Get price history for a subscription
  Future<List<PriceChange>> getPriceHistory(String subscriptionId) async {
    try {
      return await _priceChangeRepository.getPriceChangesForSubscription(subscriptionId);
    } catch (e) {
      debugPrint('Error getting price history: $e');
      return [];
    }
  }

  // Get upcoming price changes for a subscription
  Future<List<PriceChange>> getUpcomingPriceChanges(String subscriptionId) async {
    try {
      final allChanges = await _priceChangeRepository.getPriceChangesForSubscription(subscriptionId);
      return _priceHistoryService.getUpcomingPriceChanges(
        subscription: _subscriptions.firstWhere((s) => s.id == subscriptionId),
        priceChanges: allChanges,
      );
    } catch (e) {
      debugPrint('Error getting upcoming price changes: $e');
      return [];
    }
  }

  // Calculate total monthly spending with price history
  Future<double> getTotalMonthlySpendingWithHistory({DateTime? forMonth}) async {
    try {
      double total = 0.0;
      
      for (final subscription in activeSubscriptions) {
        final priceChanges = await _priceChangeRepository.getPriceChangesForSubscription(subscription.id);
        final monthlySpent = _priceHistoryService.calculateMonthlySpentWithHistory(
          subscription: subscription,
          priceChanges: priceChanges,
          forMonth: forMonth,
        );
        total += monthlySpent;
      }
      
      return total;
    } catch (e) {
      debugPrint('Error calculating monthly spending with history: $e');
      return totalMonthlySpending; // Fallback to basic calculation
    }
  }

  // Calculate total yearly spending with price history
  Future<double> getTotalYearlySpendingWithHistory({int? forYear}) async {
    try {
      double total = 0.0;
      
      for (final subscription in activeSubscriptions) {
        final priceChanges = await _priceChangeRepository.getPriceChangesForSubscription(subscription.id);
        final yearlySpent = _priceHistoryService.calculateYearlySpentWithHistory(
          subscription: subscription,
          priceChanges: priceChanges,
          forYear: forYear,
        );
        total += yearlySpent;
      }
      
      return total;
    } catch (e) {
      debugPrint('Error calculating yearly spending with history: $e');
      return totalYearlySpending; // Fallback to basic calculation
    }
  }

  // Get current effective price for a subscription
  Future<double> getCurrentEffectivePrice(String subscriptionId) async {
    try {
      final subscription = _subscriptions.firstWhere((s) => s.id == subscriptionId);
      final priceChanges = await _priceChangeRepository.getPriceChangesForSubscription(subscriptionId);
      
      return _priceHistoryService.getCurrentPrice(
        subscription: subscription,
        priceChanges: priceChanges,
      );
    } catch (e) {
      debugPrint('Error getting current effective price: $e');
      final subscription = _subscriptions.firstWhere((s) => s.id == subscriptionId);
      return subscription.amount; // Fallback to subscription's base price
    }
  }
  
  // Schedule a notification for a subscription
  void _scheduleNotification(Subscription subscription) {
    // Skip if renewal date is in the past
    if (subscription.renewalDate.isBefore(DateTime.now())) {
              debugPrint('DEBUG: Skipping notification for ${subscription.name} because renewal date ${subscription.renewalDate} is in the past');
      return;
    }
    
    // Get notification time from settings
    final notificationTime = _settingsService.getNotificationTime();
    
    // Calculate notification date (X days before renewal date)
    final renewalDate = subscription.renewalDate;
    final notificationDate = DateTime(
      renewalDate.year,
      renewalDate.month,
      renewalDate.day - subscription.notificationDays,
      notificationTime.hour,
      notificationTime.minute,
    );
    
    // Skip if notification date is in the past
    if (notificationDate.isBefore(DateTime.now())) {
              debugPrint('DEBUG: Notification date $notificationDate for ${subscription.name} is in the past');
      
      // If renewal is still in the future, schedule for now + 1 minute as fallback
      if (renewalDate.isAfter(DateTime.now())) {
        final fallbackDate = DateTime.now().add(const Duration(minutes: 1));
        debugPrint('DEBUG: Using fallback date $fallbackDate for ${subscription.name}');
        
        _notificationService.scheduleNotification(
          id: subscription.id.hashCode,
          title: 'Upcoming Subscription Renewal',
          body: '${subscription.name} will renew ${subscription.notificationDays == 0 ? "today" : "soon"}',
          scheduledDate: fallbackDate,
        );
      }
      return;
    }
    
          debugPrint('DEBUG: Scheduling notification for ${subscription.name} on $notificationDate');
    
    // Schedule notification
    _notificationService.scheduleNotification(
      id: subscription.id.hashCode,
      title: 'Subscription Renewal Reminder',
      body: '${subscription.name} will renew in ${subscription.notificationDays} days',
      scheduledDate: notificationDate,
    );
  }
  
  // Reschedule all notifications
  Future<void> rescheduleAllNotifications() async {
    // Cancel all existing notifications
    await _notificationService.cancelAllNotifications();
    
    // Schedule new notifications for active subscriptions
    if (_settingsService.areNotificationsEnabled()) {
      for (final subscription in activeSubscriptions) {
        if (subscription.notificationsEnabled) {
          _scheduleNotification(subscription);
        }
      }
    }
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Delete all subscriptions
  Future<void> deleteAllSubscriptions() async {
    try {
      // Get all subscription IDs
      final ids = List<String>.from(_subscriptions.map((s) => s.id));
      
      // Delete each subscription from repository
      for (final id in ids) {
        await _repository.deleteSubscription(id);
      }
      
      // Clear the in-memory list
      _subscriptions.clear();
      
      // Cancel all notifications
      await _notificationService.cancelAllNotifications();
      
      notifyListeners();
    } catch (e) {
      _error = 'Error deleting all subscriptions';
      notifyListeners();
    }
  }
  
  // Debug notifications - print all pending notifications to console
  Future<void> debugNotifications() async {
    final pendingNotifications = await _notificationService.getPendingNotifications();
    debugPrint('DEBUG: ===== PENDING NOTIFICATIONS =====');
    debugPrint('DEBUG: Total pending notifications: ${pendingNotifications.length}');
    
    for (final notification in pendingNotifications) {
      debugPrint('DEBUG: Notification ID: ${notification.id}');
      debugPrint('DEBUG: Title: ${notification.title}');
      debugPrint('DEBUG: Body: ${notification.body}');
      debugPrint('DEBUG: Payload: ${notification.payload}');
      debugPrint('DEBUG: ---------------------');
    }
    
    // Debug active subscriptions and their renewal dates
    debugPrint('DEBUG: ===== ACTIVE SUBSCRIPTIONS =====');
    final now = DateTime.now();
    for (final subscription in activeSubscriptions) {
      final notificationTime = _settingsService.getNotificationTime();
      final renewalDate = subscription.renewalDate;
      final notificationDate = DateTime(
        renewalDate.year,
        renewalDate.month,
        renewalDate.day - subscription.notificationDays,
        notificationTime.hour,
        notificationTime.minute,
      );
      
      debugPrint('DEBUG: Subscription: ${subscription.name}');
      debugPrint('DEBUG: Renewal date: ${subscription.renewalDate}');
      debugPrint('DEBUG: Scheduled notification date: $notificationDate');
      debugPrint('DEBUG: Days until renewal: ${subscription.daysUntilRenewal}');
      debugPrint('DEBUG: Notification days before: ${subscription.notificationDays}');
      debugPrint('DEBUG: Is notification date in past: ${notificationDate.isBefore(now)}');
      debugPrint('DEBUG: Is renewal date in past: ${renewalDate.isBefore(now)}');
      debugPrint('DEBUG: ---------------------');
    }
  }
} 