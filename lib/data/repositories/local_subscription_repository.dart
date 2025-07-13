import '../../domain/entities/subscription.dart';

/// Repository for handling local subscription storage
/// This is a stub implementation that will be enhanced with proper storage
class LocalSubscriptionRepository {
  final List<Subscription> _localSubscriptions = [];
  
  /// Initialize the local repository
  Future<void> init() async {
    // Initialize local storage - for now just use in-memory list
    print('✅ LocalSubscriptionRepository initialized');
  }
  
  /// Get all active subscriptions from local storage
  Future<List<Subscription>> getActiveSubscriptions() async {
    try {
      return _localSubscriptions.where((sub) => sub.status == 'active').toList();
    } catch (e) {
      print('❌ Error getting active subscriptions from local storage: $e');
      return [];
    }
  }
  
  /// Get all paused subscriptions from local storage
  Future<List<Subscription>> getPausedSubscriptions() async {
    try {
      return _localSubscriptions.where((sub) => sub.status != 'active').toList();
    } catch (e) {
      print('❌ Error getting paused subscriptions from local storage: $e');
      return [];
    }
  }
  
  /// Get cancelled subscriptions (placeholder for future implementation)
  Future<List<Subscription>> getCancelledSubscriptions() async {
    // For now, return empty list - this can be implemented later
    return [];
  }
  
  /// Add a subscription to local storage
  Future<void> addSubscription(Subscription subscription) async {
    try {
      _localSubscriptions.add(subscription);
      print('✅ Added subscription to local storage: ${subscription.name}');
    } catch (e) {
      print('❌ Error adding subscription to local storage: $e');
      rethrow;
    }
  }
  
  /// Upload subscriptions (placeholder - local storage doesn't upload)
  Future<void> uploadSubscriptions(List<Subscription> subscriptions) async {
    // This is a local repository, so we just add them locally
    for (final subscription in subscriptions) {
      await addSubscription(subscription);
    }
  }
  
  /// Get subscription by ID
  Future<Subscription?> getSubscriptionById(String id) async {
    try {
      return _localSubscriptions.where((sub) => sub.id == id).firstOrNull;
    } catch (e) {
      print('❌ Error getting subscription by ID from local storage: $e');
      return null;
    }
  }
  
  /// Get subscriptions due soon (placeholder for future implementation)
  Future<List<Subscription>> getSubscriptionsDueSoon() async {
    final activeSubscriptions = await getActiveSubscriptions();
    final now = DateTime.now();
    final threeDaysFromNow = now.add(const Duration(days: 3));
    
    return activeSubscriptions.where((subscription) {
      return subscription.renewalDate.isBefore(threeDaysFromNow) &&
             subscription.renewalDate.isAfter(now);
    }).toList();
  }
  
  /// Get overdue subscriptions (placeholder for future implementation)
  Future<List<Subscription>> getOverdueSubscriptions() async {
    final activeSubscriptions = await getActiveSubscriptions();
    final now = DateTime.now();
    
    return activeSubscriptions.where((subscription) {
      return subscription.renewalDate.isBefore(now);
    }).toList();
  }
  
  /// Get all price changes (placeholder for future implementation)
  Future<List<dynamic>> getAllPriceChanges() async {
    // This would need to be implemented with a separate price changes box
    return [];
  }
  
  /// Update a subscription in local storage
  Future<void> updateSubscription(Subscription subscription) async {
    try {
      final index = _localSubscriptions.indexWhere((sub) => sub.id == subscription.id);
      if (index != -1) {
        _localSubscriptions[index] = subscription;
        print('✅ Updated subscription in local storage: ${subscription.name}');
      }
    } catch (e) {
      print('❌ Error updating subscription in local storage: $e');
      rethrow;
    }
  }
  
  /// Delete a subscription from local storage
  Future<void> deleteSubscription(String id) async {
    try {
      _localSubscriptions.removeWhere((sub) => sub.id == id);
      print('✅ Deleted subscription from local storage: $id');
    } catch (e) {
      print('❌ Error deleting subscription from local storage: $e');
      rethrow;
    }
  }
  
  /// Close the repository
  Future<void> close() async {
    // Nothing to close for in-memory storage
  }
} 