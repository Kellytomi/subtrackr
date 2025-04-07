import 'package:hive_flutter/hive_flutter.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/data/models/subscription_model.dart';
import 'package:subtrackr/domain/entities/subscription.dart';

class SubscriptionRepository {
  static final SubscriptionRepository _instance = SubscriptionRepository._internal();
  
  factory SubscriptionRepository() {
    return _instance;
  }
  
  SubscriptionRepository._internal();
  
  late Box<SubscriptionModel> _subscriptionsBox;
  
  // Initialize the repository
  Future<void> init() async {
    // Register the adapter
    if (!Hive.isAdapterRegistered(0)) {
      // Note: The adapter will be generated by build_runner
      // We'll need to run 'flutter pub run build_runner build' after creating the model
      Hive.registerAdapter<SubscriptionModel>(SubscriptionModelAdapter());
    }
    
    // Open the box
    _subscriptionsBox = await Hive.openBox<SubscriptionModel>(AppConstants.subscriptionsBox);
  }
  
  // Get all subscriptions
  List<Subscription> getAllSubscriptions() {
    return _subscriptionsBox.values.map((model) => model.toEntity()).toList();
  }
  
  // Get active subscriptions
  List<Subscription> getActiveSubscriptions() {
    return _subscriptionsBox.values
        .where((model) => model.status == AppConstants.statusActive)
        .map((model) => model.toEntity())
        .toList();
  }
  
  // Get paused subscriptions
  List<Subscription> getPausedSubscriptions() {
    return _subscriptionsBox.values
        .where((model) => model.status == AppConstants.statusPaused)
        .map((model) => model.toEntity())
        .toList();
  }
  
  // Get cancelled subscriptions
  List<Subscription> getCancelledSubscriptions() {
    return _subscriptionsBox.values
        .where((model) => model.status == AppConstants.statusCancelled)
        .map((model) => model.toEntity())
        .toList();
  }
  
  // Get subscription by ID
  Subscription? getSubscriptionById(String id) {
    final models = _subscriptionsBox.values.where((model) => model.id == id);
    if (models.isEmpty) {
      return null;
    }
    return models.first.toEntity();
  }
  
  // Add a new subscription
  Future<void> addSubscription(Subscription subscription) async {
    final model = SubscriptionModel.fromEntity(subscription);
    await _subscriptionsBox.put(subscription.id, model);
  }
  
  // Update an existing subscription
  Future<void> updateSubscription(Subscription subscription) async {
    final model = SubscriptionModel.fromEntity(subscription);
    await _subscriptionsBox.put(subscription.id, model);
  }
  
  // Delete a subscription
  Future<void> deleteSubscription(String id) async {
    await _subscriptionsBox.delete(id);
  }
  
  // Get subscriptions due soon (within the next 3 days)
  List<Subscription> getSubscriptionsDueSoon() {
    final now = DateTime.now();
    final threeDaysLater = now.add(const Duration(days: 3));
    
    return _subscriptionsBox.values
        .where((model) => 
            model.status == AppConstants.statusActive &&
            model.renewalDate.isAfter(now) &&
            model.renewalDate.isBefore(threeDaysLater))
        .map((model) => model.toEntity())
        .toList();
  }
  
  // Get overdue subscriptions
  List<Subscription> getOverdueSubscriptions() {
    final now = DateTime.now();
    
    return _subscriptionsBox.values
        .where((model) => 
            model.status == AppConstants.statusActive &&
            model.renewalDate.isBefore(now))
        .map((model) => model.toEntity())
        .toList();
  }
  
  // Get total monthly spending
  double getTotalMonthlySpending() {
    final activeSubscriptions = getActiveSubscriptions();
    
    return activeSubscriptions.fold<double>(0, (total, subscription) => total + subscription.monthlyCost);
  }
  
  // Get total yearly spending
  double getTotalYearlySpending() {
    final activeSubscriptions = getActiveSubscriptions();
    
    return activeSubscriptions.fold<double>(0, (total, subscription) => total + subscription.yearlyCost);
  }
  
  // Get subscriptions by category
  Map<String?, List<Subscription>> getSubscriptionsByCategory() {
    final subscriptions = getAllSubscriptions();
    
    return groupBy(subscriptions, (Subscription s) => s.category);
  }
  
  // Helper function to group subscriptions by a key
  Map<K, List<T>> groupBy<T, K>(List<T> items, K Function(T) keyFunction) {
    final map = <K, List<T>>{};
    
    for (final item in items) {
      final key = keyFunction(item);
      if (!map.containsKey(key)) {
        map[key] = [];
      }
      map[key]!.add(item);
    }
    
    return map;
  }
  
  // Close the box
  Future<void> close() async {
    await _subscriptionsBox.close();
  }
} 