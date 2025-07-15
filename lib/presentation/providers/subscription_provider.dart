import 'dart:async';
import 'package:flutter/material.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/core/utils/date_utils.dart';
import 'package:subtrackr/data/repositories/dual_subscription_repository.dart';
import 'package:subtrackr/data/repositories/price_change_repository.dart';
import 'package:subtrackr/data/services/notification_service.dart';
import 'package:subtrackr/data/services/settings_service.dart';
import 'package:subtrackr/data/services/price_history_service.dart';
import 'package:subtrackr/data/services/supabase_cloud_sync_service.dart';
import 'package:subtrackr/domain/entities/subscription.dart';
import 'package:subtrackr/domain/entities/price_change.dart';

class SubscriptionProvider extends ChangeNotifier {
  final DualSubscriptionRepository _repository;
  final PriceChangeRepository _priceChangeRepository;
  final NotificationService _notificationService;
  final SettingsService _settingsService;
  final PriceHistoryService _priceHistoryService;
  final SupabaseCloudSyncService _supabaseCloudSyncService;
  
  List<Subscription> _subscriptions = [];
  bool _isLoading = false;
  bool _isBackgroundSyncing = false; // New: Track background sync status
  String? _error;
  
  SubscriptionProvider({
    required DualSubscriptionRepository repository,
    required PriceChangeRepository priceChangeRepository,
    required NotificationService notificationService,
    required SettingsService settingsService,
    required SupabaseCloudSyncService supabaseCloudSyncService,
  })  : _repository = repository,
        _priceChangeRepository = priceChangeRepository,
        _notificationService = notificationService,
        _settingsService = settingsService,
        _priceHistoryService = PriceHistoryService(),
        _supabaseCloudSyncService = supabaseCloudSyncService {
    // Initialize real-time sync
    _initializeRealTimeSync();
  }
  
  // Getters
  List<Subscription> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;
  bool get isBackgroundSyncing => _isBackgroundSyncing; // New: Expose background sync status
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
      // SPEED OPTIMIZATION: Load local data first for immediate display
      print('📱 Loading local subscriptions for immediate display...');
      var localSubscriptions = await _repository.getAllSubscriptions();
      
      // Show local data immediately
      if (localSubscriptions.isNotEmpty) {
        _subscriptions = localSubscriptions;
        _sortSubscriptions(_subscriptions);
        _isLoading = false;
        notifyListeners(); // Update UI with local data immediately
        print('⚡ Displayed ${localSubscriptions.length} local subscriptions immediately');
      }
      
      // If user is signed in, sync in background without blocking UI
      if (_supabaseCloudSyncService.isUserSignedIn) {
        print('🔄 User is signed in, performing background sync...');
        
        // IMPORTANT: Clear loading state immediately if we have no local data to show
        // This prevents infinite loading when user has no subscriptions
        if (localSubscriptions.isEmpty) {
          _isLoading = false;
          notifyListeners();
          print('✅ Cleared loading state - no local subscriptions to show');
        }
        
        // Don't block UI - sync in background
        _performBackgroundSync();
      } else {
        // User not signed in, ensure we have local data displayed
        if (localSubscriptions.isEmpty) {
          _isLoading = false;
          notifyListeners();
        }
      }
      
    } catch (e) {
      _isLoading = false;
      _error = AppConstants.ERROR_LOADING_SUBSCRIPTIONS;
      notifyListeners();
      print('❌ Error loading subscriptions: $e');
    }
  }
  
  /// Perform background sync without blocking the UI
  Future<void> _performBackgroundSync() async {
    try {
      // Check if already syncing to prevent multiple concurrent syncs
      if (_isBackgroundSyncing) {
        print('⏸️ Background sync already in progress, skipping...');
        return;
      }
      
      _isBackgroundSyncing = true;
      notifyListeners(); // Update UI to show sync indicator
      
      print('🔄 Starting background sync...');
      
      // Add timeout to prevent indefinite syncing
      await Future.any([
        _supabaseCloudSyncService.manualSync(),
        Future.delayed(const Duration(seconds: 30), () => throw TimeoutException('Sync timeout')),
      ]);
      
      // Small delay to ensure sync is complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Reload data after sync (this will show any new data from cloud)
      print('🔄 Reloading data after background sync...');
      var syncedSubscriptions = await _repository.getAllSubscriptions();
      
      // Ensure each subscription has a valid currency code
      for (int i = 0; i < syncedSubscriptions.length; i++) {
        final subscription = syncedSubscriptions[i];
        if (subscription.currencyCode.isEmpty) {
          final updatedSubscription = subscription.copyWith(
            currencyCode: _settingsService.getCurrencyCode() ?? AppConstants.DEFAULT_CURRENCY_CODE,
          );
          syncedSubscriptions[i] = updatedSubscription;
          await _repository.updateSubscription(updatedSubscription);
        }
      }
      
      // Update UI with synced data
      _subscriptions = syncedSubscriptions;
      _sortSubscriptions(_subscriptions);
      
      print('✅ Background sync completed - UI updated with ${_subscriptions.length} subscriptions');
      
      // If still no subscriptions after sync, ensure loading state is cleared
      if (_subscriptions.isEmpty && _isLoading) {
        _isLoading = false;
        print('✅ Cleared loading state after sync - no subscriptions found');
      }
      
    } catch (e) {
      print('⚠️ Background sync failed, keeping local data: $e');
      // Don't update error state since user already has local data displayed
    } finally {
      _isBackgroundSyncing = false;
      print('🔄 Background sync finished - hiding sync indicator');
      notifyListeners(); // Update UI to hide sync indicator
    }
  }
  
  // Add a new subscription
  Future<void> addSubscription(Subscription subscription) async {
    try {
      final isSignedIn = _supabaseCloudSyncService.isUserSignedIn;
      final currentUser = _supabaseCloudSyncService.currentUser;
      
      print('🔍 Adding subscription - Auth check: isSignedIn=$isSignedIn, user=${currentUser?.email ?? 'null'}');
      
      // Optimistically add to UI first with proper sorting to prevent visual delay
      final updatedSubscriptions = [..._subscriptions, subscription];
      _sortSubscriptions(updatedSubscriptions);
      _subscriptions = updatedSubscriptions;
      notifyListeners(); // Update UI immediately with sorted list
      
      try {
        // DualSubscriptionRepository already handles both local and cloud storage
        await _repository.addSubscription(subscription);
        
        // Schedule notification if active (but skip for tutorial examples)
        if (subscription.status == AppConstants.STATUS_ACTIVE && subscription.id != 'tutorial_example') {
          _scheduleNotification(subscription);
        }
      } catch (repositoryError) {
        // If repository operation fails, remove from UI
        _subscriptions = _subscriptions.where((s) => s.id != subscription.id).toList();
        notifyListeners();
        throw repositoryError;
      }
      
    } catch (e) {
      _error = AppConstants.ERROR_ADDING_SUBSCRIPTION;
      notifyListeners();
    }
  }
  
  // Update a subscription
  Future<void> updateSubscription(Subscription subscription) async {
    try {
      // DualSubscriptionRepository already handles both local and cloud storage
      await _repository.updateSubscription(subscription);
      _subscriptions = _subscriptions.map((s) => 
        s.id == subscription.id ? subscription : s
      ).toList();
      _sortSubscriptions(_subscriptions);
      notifyListeners();
      
      // No need for additional auto backup - DualSubscriptionRepository already handles cloud sync
      
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
      // Optimistically remove from UI first for immediate feedback
      final originalSubscriptions = List<Subscription>.from(_subscriptions);
      _subscriptions = _subscriptions.where((s) => s.id != id).toList();
      notifyListeners(); // Update UI immediately
      
      try {
        // Perform deletion and notification cancellation in parallel
        await Future.wait([
          _repository.deleteSubscription(id),
          _notificationService.cancelNotification(id.hashCode),
        ]);
        
        print('✅ Successfully deleted subscription: $id');
      } catch (repositoryError) {
        // If deletion fails, restore the subscription to UI
        _subscriptions = originalSubscriptions;
        notifyListeners();
        throw repositoryError;
      }
      
    } catch (e) {
      _error = AppConstants.ERROR_DELETING_SUBSCRIPTION;
      notifyListeners();
      print('❌ Error deleting subscription: $e');
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
      
      // DualSubscriptionRepository already handles both local and cloud storage
      await _repository.updateSubscription(updatedSubscription);
      
      // No need for additional auto backup - DualSubscriptionRepository already handles cloud sync
      
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
      
      // DualSubscriptionRepository already handles both local and cloud storage
      await _repository.updateSubscription(updatedSubscription);
      await _notificationService.cancelNotification(id.hashCode);
      
      // No need for additional auto backup - DualSubscriptionRepository already handles cloud sync
      
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
      
      // DualSubscriptionRepository already handles both local and cloud storage
      await _repository.updateSubscription(updatedSubscription);
      _scheduleNotification(updatedSubscription);
      
      // No need for additional auto backup - DualSubscriptionRepository already handles cloud sync
      
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
      
      // DualSubscriptionRepository already handles both local and cloud storage
      await _repository.updateSubscription(updatedSubscription);
      await _notificationService.cancelNotification(id.hashCode);
      
      // No need for additional auto backup - DualSubscriptionRepository already handles cloud sync
      
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
        
        final isTrial = subscription.description?.toLowerCase().contains('free trial') ?? false;
        final fallbackTitle = isTrial ? 'Free Trial Expiring' : 'Upcoming Subscription Renewal';
        final fallbackBody = isTrial 
            ? 'Your ${subscription.name} free trial expires ${subscription.notificationDays == 0 ? "today" : "soon"}'
            : '${subscription.name} will renew ${subscription.notificationDays == 0 ? "today" : "soon"}';
        
        _notificationService.scheduleNotification(
          id: subscription.id.hashCode,
          title: fallbackTitle,
          body: fallbackBody,
          scheduledDate: fallbackDate,
        );
      }
      return;
    }
    
          debugPrint('DEBUG: Scheduling notification for ${subscription.name} on $notificationDate');
    
    // Determine if this is a trial or regular subscription
    final isTrial = subscription.description?.toLowerCase().contains('free trial') ?? false;
    
    // Schedule notification with appropriate message
    final title = isTrial ? 'Free Trial Expiring' : 'Subscription Renewal Reminder';
    final body = isTrial 
        ? 'Your ${subscription.name} free trial expires in ${subscription.notificationDays} ${subscription.notificationDays == 1 ? 'day' : 'days'}'
        : '${subscription.name} will renew in ${subscription.notificationDays} ${subscription.notificationDays == 1 ? 'day' : 'days'}';
    
    _notificationService.scheduleNotification(
      id: subscription.id.hashCode,
      title: title,
      body: body,
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
  
  // Debug method to check sync status
  void debugSyncStatus() {
    print('🔍 DEBUG: Sync Status:');
    print('🔍 _isLoading: $_isLoading');
    print('🔍 _isBackgroundSyncing: $_isBackgroundSyncing');
    print('🔍 User signed in: ${_supabaseCloudSyncService.isUserSignedIn}');
    print('🔍 Subscriptions count: ${_subscriptions.length}');
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

  // Sort subscriptions based on current setting
  void _sortSubscriptions(List<Subscription> subscriptions) {
    final sortOption = _settingsService.getSubscriptionSort();
    
    switch (sortOption) {
      case AppConstants.SORT_BY_DATE_ADDED:
        // Sort by creation date descending (most recently added first)
        subscriptions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case AppConstants.SORT_BY_NAME:
        // Sort alphabetically
        subscriptions.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case AppConstants.SORT_BY_AMOUNT:
        // Sort by monthly cost descending (highest first)
        subscriptions.sort((a, b) => b.monthlyCost.compareTo(a.monthlyCost));
        break;
      case AppConstants.SORT_BY_RENEWAL_DATE:
        // Sort by next renewal date ascending (soonest first)
        subscriptions.sort((a, b) => a.renewalDate.compareTo(b.renewalDate));
        break;
      default:
        // Default to date added
        subscriptions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  // Public method to re-sort subscriptions (called when user changes sort preference)
  void resortSubscriptions() {
    _sortSubscriptions(_subscriptions);
    notifyListeners();
  }

  /// Initialize real-time sync for signed-in users
  Future<void> _initializeRealTimeSync() async {
    print('🔄 Initializing real-time sync...');
    
    // Add a small delay to ensure all services are properly initialized
    await Future.delayed(const Duration(milliseconds: 100));
    
    final isSignedIn = _supabaseCloudSyncService.isUserSignedIn;
    final currentUser = _supabaseCloudSyncService.currentUser;
    
    print('🔍 Auth check: isSignedIn=$isSignedIn, user=${currentUser?.email ?? 'null'}');
    
    if (isSignedIn && currentUser != null) {
      print('✅ User is signed in, starting real-time sync');
      
      // Set up callback for real-time updates
      _supabaseCloudSyncService.setRealTimeUpdateCallback(_handleRealTimeUpdate);
      
      // Start the real-time subscription
      await _supabaseCloudSyncService.startSync();
    } else {
      print('❌ User not signed in, skipping real-time sync');
    }
  }

  /// Handle real-time updates from cloud
  Future<void> _handleRealTimeUpdate(List<Subscription> cloudSubscriptions) async {
    print('📡 Real-time update received: ${cloudSubscriptions.length} subscriptions');
    
    // Don't update if we're currently loading to avoid conflicts
    if (_isLoading) {
      print('⏸️ Skipping real-time update - currently loading subscriptions');
      return;
    }
    
    try {
      // For real-time updates, trust the cloud data completely
      // This ensures deletions, additions, and updates all work properly
      _subscriptions = List.from(cloudSubscriptions);
      _sortSubscriptions(_subscriptions);
      
      // IMPORTANT: Also sync real-time changes to local storage
      // This prevents deleted subscriptions from coming back during sign-in sync
      if (_supabaseCloudSyncService.isUserSignedIn) {
        await _syncRealTimeChangesToLocalStorage(cloudSubscriptions);
      }
      
      // Reschedule all notifications to match new data
      await rescheduleAllNotifications();
      
      notifyListeners();
      print('✅ Real-time update applied successfully - now showing ${_subscriptions.length} subscriptions');
    } catch (e) {
      print('❌ Error applying real-time update: $e');
    }
  }
  
  /// Sync real-time changes to local storage to keep them in sync
  Future<void> _syncRealTimeChangesToLocalStorage(List<Subscription> cloudSubscriptions) async {
    try {
      print('🔄 Syncing real-time changes to local storage...');
      
      // Get current local subscriptions
      final localActiveSubscriptions = await _repository.getActiveSubscriptions();
      final localPausedSubscriptions = await _repository.getPausedSubscriptions();
      final localSubscriptions = [...localActiveSubscriptions, ...localPausedSubscriptions];
      
      // Remove local subscriptions that no longer exist in cloud (deletions)
      final cloudSubscriptionNames = cloudSubscriptions.map((s) => s.name.toLowerCase()).toSet();
      for (final localSub in localSubscriptions) {
        if (!cloudSubscriptionNames.contains(localSub.name.toLowerCase())) {
          await _repository.deleteSubscription(localSub.id);
          print('🗑️ Removed from local storage: ${localSub.name}');
        }
      }
      
      // Add cloud subscriptions that don't exist locally (additions)
      final localSubscriptionNames = localSubscriptions.map((s) => s.name.toLowerCase()).toSet();
      for (final cloudSub in cloudSubscriptions) {
        if (!localSubscriptionNames.contains(cloudSub.name.toLowerCase())) {
          await _repository.addSubscription(cloudSub);
          print('✅ Added to local storage: ${cloudSub.name}');
        }
      }
      
      print('✅ Real-time changes synced to local storage');
    } catch (e) {
      print('❌ Failed to sync real-time changes to local storage: $e');
      // Don't fail the whole real-time update if local storage sync fails
    }
  }

  /// Start real-time sync (call this after user signs in)
  Future<void> startRealTimeSync() async {
    print('🔄 Starting real-time sync...');
    
    // Set up callback for real-time updates
    _supabaseCloudSyncService.setRealTimeUpdateCallback(_handleRealTimeUpdate);
    
    // Start the real-time subscription
    await _supabaseCloudSyncService.startSync();
    print('✅ Real-time sync started');
  }

  /// Stop real-time sync (call this when user signs out)
  void stopRealTimeSync() {
    print('⏹️ Stopping real-time sync...');
    _supabaseCloudSyncService.stopSync();
    print('✅ Real-time sync stopped');
  }

  /// Restore subscriptions from cloud backup
  Future<void> restoreFromBackup(List<Subscription> backupSubscriptions) async {
    try {
      // Get current local subscriptions
      final localSubscriptions = await _repository.getAllSubscriptions();
      
      // Merge backup subscriptions with local ones (avoid duplicates by name)
      final mergedSubscriptions = <Subscription>[];
      final backupNames = backupSubscriptions.map((s) => s.name.toLowerCase()).toSet();
      
      // Add all backup subscriptions
      mergedSubscriptions.addAll(backupSubscriptions);
      
      // Add local subscriptions that don't exist in backup
      for (final localSub in localSubscriptions) {
        if (!backupNames.contains(localSub.name.toLowerCase())) {
          mergedSubscriptions.add(localSub);
        }
      }
      
      // Update in-memory list
      _subscriptions = mergedSubscriptions;
      _sortSubscriptions(_subscriptions);
      
      // Reschedule all notifications
      await rescheduleAllNotifications();
      
      notifyListeners();
      print('✅ Successfully restored ${backupSubscriptions.length} subscriptions from backup');
    } catch (e) {
      _error = 'Failed to restore from backup';
      notifyListeners();
      print('❌ Error restoring from backup: $e');
      rethrow;
    }
  }
} 