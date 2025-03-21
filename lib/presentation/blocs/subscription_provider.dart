import 'package:flutter/material.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/core/utils/date_utils.dart';
import 'package:subtrackr/data/repositories/subscription_repository.dart';
import 'package:subtrackr/data/services/notification_service.dart';
import 'package:subtrackr/data/services/settings_service.dart';
import 'package:subtrackr/domain/entities/subscription.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionRepository _repository;
  final NotificationService _notificationService;
  final SettingsService _settingsService;
  
  List<Subscription> _subscriptions = [];
  bool _isLoading = false;
  String? _error;
  
  SubscriptionProvider({
    required SubscriptionRepository repository,
    required NotificationService notificationService,
    required SettingsService settingsService,
  })  : _repository = repository,
        _notificationService = notificationService,
        _settingsService = settingsService;
  
  // Getters
  List<Subscription> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Get active subscriptions
  List<Subscription> get activeSubscriptions => _subscriptions
      .where((subscription) => subscription.status == AppConstants.statusActive)
      .toList();
  
  // Get paused subscriptions
  List<Subscription> get pausedSubscriptions => _subscriptions
      .where((subscription) => subscription.status == AppConstants.statusPaused)
      .toList();
  
  // Get cancelled subscriptions
  List<Subscription> get cancelledSubscriptions => _subscriptions
      .where((subscription) => subscription.status == AppConstants.statusCancelled)
      .toList();
  
  // Get subscriptions due soon (within the next 7 days)
  List<Subscription> get subscriptionsDueSoon => _subscriptions
      .where((subscription) => 
          subscription.status == AppConstants.statusActive &&
          subscription.isDueSoon)
      .toList();
  
  // Get overdue subscriptions
  List<Subscription> get overdueSubscriptions => _subscriptions
      .where((subscription) => 
          subscription.status == AppConstants.statusActive &&
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
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _subscriptions = _repository.getAllSubscriptions();
      
      // Ensure each subscription has a valid currency code
      for (int i = 0; i < _subscriptions.length; i++) {
        final subscription = _subscriptions[i];
        if (subscription.currencyCode.isEmpty) {
          // If currency code is empty, use the default currency code
          final updatedSubscription = subscription.copyWith(
            currencyCode: _settingsService.getCurrencyCode() ?? AppConstants.defaultCurrencyCode,
          );
          _subscriptions[i] = updatedSubscription;
          await _repository.updateSubscription(updatedSubscription);
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = AppConstants.errorLoadingSubscriptions;
      notifyListeners();
    }
  }
  
  // Add a new subscription
  Future<void> addSubscription(Subscription subscription) async {
    try {
      // Ensure the subscription has a valid currency code
      Subscription subscriptionToAdd = subscription;
      if (subscription.currencyCode.isEmpty) {
        subscriptionToAdd = subscription.copyWith(
          currencyCode: _settingsService.getCurrencyCode() ?? AppConstants.defaultCurrencyCode,
        );
      }
      
      await _repository.addSubscription(subscriptionToAdd);
      _subscriptions.add(subscriptionToAdd);
      
      // Schedule notification if enabled
      if (subscriptionToAdd.notificationsEnabled && 
          _settingsService.areNotificationsEnabled() &&
          subscriptionToAdd.status == AppConstants.statusActive) {
        _scheduleNotification(subscriptionToAdd);
      }
      
      notifyListeners();
    } catch (e) {
      _error = AppConstants.errorSavingSubscription;
      notifyListeners();
    }
  }
  
  // Update an existing subscription
  Future<void> updateSubscription(Subscription updatedSubscription) async {
    try {
      // Ensure the subscription has a valid currency code
      Subscription subscriptionToUpdate = updatedSubscription;
      if (updatedSubscription.currencyCode.isEmpty) {
        // Find the existing subscription to get its currency code
        final existingSubscription = _subscriptions.firstWhere(
          (s) => s.id == updatedSubscription.id,
          orElse: () => updatedSubscription,
        );
        
        // If the existing subscription has a currency code, use it
        if (existingSubscription.currencyCode.isNotEmpty) {
          subscriptionToUpdate = updatedSubscription.copyWith(
            currencyCode: existingSubscription.currencyCode,
          );
        } else {
          // Otherwise, use the default currency code
          subscriptionToUpdate = updatedSubscription.copyWith(
            currencyCode: _settingsService.getCurrencyCode() ?? AppConstants.defaultCurrencyCode,
          );
        }
      }
      
      await _repository.updateSubscription(subscriptionToUpdate);
      
      final index = _subscriptions.indexWhere((s) => s.id == subscriptionToUpdate.id);
      if (index != -1) {
        _subscriptions[index] = subscriptionToUpdate;
      }
      
      // Cancel existing notification
      await _notificationService.cancelNotification(subscriptionToUpdate.id.hashCode);
      
      // Schedule new notification if enabled
      if (subscriptionToUpdate.notificationsEnabled && 
          _settingsService.areNotificationsEnabled() &&
          subscriptionToUpdate.status == AppConstants.statusActive) {
        _scheduleNotification(subscriptionToUpdate);
      }
      
      notifyListeners();
    } catch (e) {
      _error = AppConstants.errorSavingSubscription;
      notifyListeners();
    }
  }
  
  // Delete a subscription
  Future<void> deleteSubscription(String id) async {
    try {
      await _repository.deleteSubscription(id);
      _subscriptions.removeWhere((s) => s.id == id);
      
      // Cancel notification
      await _notificationService.cancelNotification(id.hashCode);
      
      notifyListeners();
    } catch (e) {
      _error = AppConstants.errorDeletingSubscription;
      notifyListeners();
    }
  }
  
  // Pause a subscription
  Future<void> pauseSubscription(String id) async {
    final subscription = _subscriptions.firstWhere((s) => s.id == id);
    final updatedSubscription = subscription.pause();
    await updateSubscription(updatedSubscription);
  }
  
  // Resume a subscription
  Future<void> resumeSubscription(String id) async {
    final subscription = _subscriptions.firstWhere((s) => s.id == id);
    final updatedSubscription = subscription.resume();
    await updateSubscription(updatedSubscription);
  }
  
  // Cancel a subscription
  Future<void> cancelSubscription(String id) async {
    final subscription = _subscriptions.firstWhere((s) => s.id == id);
    final updatedSubscription = subscription.cancel();
    await updateSubscription(updatedSubscription);
  }
  
  // Add a payment to a subscription
  Future<void> addPayment(String id, DateTime paymentDate) async {
    final subscription = _subscriptions.firstWhere((s) => s.id == id);
    final updatedSubscription = subscription.addPayment(paymentDate);
    await updateSubscription(updatedSubscription);
  }
  
  // Schedule a notification for a subscription
  void _scheduleNotification(Subscription subscription) {
    if (subscription.renewalDate.isBefore(DateTime.now())) return;
    
    _notificationService.scheduleNotification(
      id: subscription.id.hashCode,
      title: 'Subscription Renewal Reminder',
      body: '${subscription.name} will renew in ${subscription.notificationDays} days',
      scheduledDate: subscription.renewalDate,
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
} 