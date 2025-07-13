import '../../domain/entities/subscription.dart';
import './subscription_repository.dart';

/// Repository for handling local subscription storage with Hive persistence
class LocalSubscriptionRepository {
  late SubscriptionRepository _subscriptionRepository;
  
  /// Initialize the local repository with Hive persistence
  Future<void> init() async {
    _subscriptionRepository = SubscriptionRepository();
    await _subscriptionRepository.init();
    print('✅ LocalSubscriptionRepository initialized with Hive persistence');
  }
  
  /// Get all active subscriptions from local storage
  Future<List<Subscription>> getActiveSubscriptions() async {
    try {
      return _subscriptionRepository.getActiveSubscriptions();
    } catch (e) {
      print('❌ Error getting active subscriptions from local storage: $e');
      return [];
    }
  }
  
  /// Get all paused subscriptions from local storage
  Future<List<Subscription>> getPausedSubscriptions() async {
    try {
      return _subscriptionRepository.getPausedSubscriptions();
    } catch (e) {
      print('❌ Error getting paused subscriptions from local storage: $e');
      return [];
    }
  }
  
  /// Get cancelled subscriptions from local storage
  Future<List<Subscription>> getCancelledSubscriptions() async {
    try {
      return _subscriptionRepository.getCancelledSubscriptions();
    } catch (e) {
      print('❌ Error getting cancelled subscriptions from local storage: $e');
    return [];
    }
  }
  
  /// Add a subscription to local storage
  Future<void> addSubscription(Subscription subscription) async {
    try {
      await _subscriptionRepository.addSubscription(subscription);
      print('✅ Added subscription to local storage: ${subscription.name}');
    } catch (e) {
      print('❌ Error adding subscription to local storage: $e');
      rethrow;
    }
  }
  
  /// Upload subscriptions to local storage
  Future<void> uploadSubscriptions(List<Subscription> subscriptions) async {
    try {
    for (final subscription in subscriptions) {
        await _subscriptionRepository.addSubscription(subscription);
      }
      print('✅ Uploaded ${subscriptions.length} subscriptions to local storage');
    } catch (e) {
      print('❌ Error uploading subscriptions to local storage: $e');
      rethrow;
    }
  }
  
  /// Get subscription by ID
  Future<Subscription?> getSubscriptionById(String id) async {
    try {
      return _subscriptionRepository.getSubscriptionById(id);
    } catch (e) {
      print('❌ Error getting subscription by ID from local storage: $e');
      return null;
    }
  }
  
  /// Get subscriptions due soon
  Future<List<Subscription>> getSubscriptionsDueSoon() async {
    try {
      return _subscriptionRepository.getSubscriptionsDueSoon();
    } catch (e) {
      print('❌ Error getting subscriptions due soon from local storage: $e');
      return [];
    }
  }
  
  /// Get overdue subscriptions
  Future<List<Subscription>> getOverdueSubscriptions() async {
    try {
      return _subscriptionRepository.getOverdueSubscriptions();
    } catch (e) {
      print('❌ Error getting overdue subscriptions from local storage: $e');
      return [];
    }
  }
  
  /// Get all price changes
  Future<List<dynamic>> getAllPriceChanges() async {
    try {
      // This would need to be implemented with PriceChangeRepository
      return [];
    } catch (e) {
      print('❌ Error getting price changes from local storage: $e');
    return [];
    }
  }
  
  /// Update a subscription in local storage
  Future<void> updateSubscription(Subscription subscription) async {
    try {
      await _subscriptionRepository.updateSubscription(subscription);
        print('✅ Updated subscription in local storage: ${subscription.name}');
    } catch (e) {
      print('❌ Error updating subscription in local storage: $e');
      rethrow;
    }
  }
  
  /// Delete a subscription from local storage
  Future<void> deleteSubscription(String id) async {
    try {
      await _subscriptionRepository.deleteSubscription(id);
      print('✅ Deleted subscription from local storage: $id');
    } catch (e) {
      print('❌ Error deleting subscription from local storage: $e');
      rethrow;
    }
  }
  
  /// Clear all subscriptions from local storage
  Future<void> clearAllSubscriptions() async {
    try {
      await _subscriptionRepository.clearAllSubscriptions();
    print('✅ Cleared all subscriptions from local storage');
    } catch (e) {
      print('❌ Error clearing all subscriptions from local storage: $e');
      rethrow;
    }
  }
  
  /// Close the repository
  Future<void> close() async {
    // The underlying SubscriptionRepository uses Hive boxes which can be closed
    // but it's typically handled by the Hive system
    print('📱 LocalSubscriptionRepository closed');
  }
} 