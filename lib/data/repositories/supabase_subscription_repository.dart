import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/subscription.dart';

/// Repository for handling Supabase cloud subscription storage
class SupabaseSubscriptionRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Initialize the Supabase repository
  Future<void> init() async {
    print('✅ SupabaseSubscriptionRepository initialized');
  }
  
  /// Get all active subscriptions from Supabase
  Future<List<Subscription>> getActiveSubscriptions() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user for Supabase query');
        return [];
      }
      
      final response = await _supabase
          .from('subscriptions')
          .select()
          .eq('user_id', user.id)
          .eq('is_active', true);
      
      final subscriptions = <Subscription>[];
      for (final data in response) {
        try {
          // Convert Supabase data to Subscription entity
          final subscription = Subscription(
            id: data['id'] ?? '',
            name: data['name'] ?? '',
            amount: (data['price'] ?? 0.0).toDouble(),
            billingCycle: data['billing_cycle'] ?? 'monthly',
            startDate: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
            renewalDate: DateTime.parse(data['next_payment_date'] ?? DateTime.now().toIso8601String()),
            status: data['is_active'] == true ? 'active' : 'paused',
            description: data['description'],
            website: data['website'],
            logoUrl: data['logo_url'],
            category: data['category'],
            currencyCode: data['currency'] ?? 'USD',
          );
          subscriptions.add(subscription);
        } catch (e) {
          print('❌ Error parsing subscription from Supabase: $e');
          // Continue with other subscriptions
        }
      }
      
      return subscriptions;
    } catch (e) {
      print('❌ Error getting active subscriptions from Supabase: $e');
      return [];
    }
  }
  
  /// Get all paused subscriptions from Supabase
  Future<List<Subscription>> getPausedSubscriptions() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user for Supabase query');
        return [];
      }
      
      final response = await _supabase
          .from('subscriptions')
          .select()
          .eq('user_id', user.id)
          .eq('is_active', false);
      
      final subscriptions = <Subscription>[];
      for (final data in response) {
        try {
          // Convert Supabase data to Subscription entity
          final subscription = Subscription(
            id: data['id'] ?? '',
            name: data['name'] ?? '',
            amount: (data['price'] ?? 0.0).toDouble(),
            billingCycle: data['billing_cycle'] ?? 'monthly',
            startDate: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
            renewalDate: DateTime.parse(data['next_payment_date'] ?? DateTime.now().toIso8601String()),
            status: 'paused',
            description: data['description'],
            website: data['website'],
            logoUrl: data['logo_url'],
            category: data['category'],
            currencyCode: data['currency'] ?? 'USD',
          );
          subscriptions.add(subscription);
        } catch (e) {
          print('❌ Error parsing subscription from Supabase: $e');
          // Continue with other subscriptions
        }
      }
      
      return subscriptions;
    } catch (e) {
      print('❌ Error getting paused subscriptions from Supabase: $e');
      return [];
    }
  }
  
  /// Get cancelled subscriptions (placeholder)
  Future<List<Subscription>> getCancelledSubscriptions() async {
    // For now, return empty list - this can be implemented later
    return [];
  }
  
  /// Add a subscription to Supabase
  Future<void> addSubscription(Subscription subscription) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user for Supabase insert');
      }
      
      final subscriptionData = {
        'id': subscription.id,
        'user_id': user.id,
        'name': subscription.name,
        'price': subscription.amount,
        'currency': subscription.currencyCode,
        'billing_cycle': subscription.billingCycle,
        'next_payment_date': subscription.renewalDate.toIso8601String(),
        'category': subscription.category,
        'logo_url': subscription.logoUrl,
        'is_active': subscription.status == 'active',
        'created_at': subscription.startDate.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await _supabase.from('subscriptions').insert(subscriptionData);
      print('✅ Added subscription to Supabase: ${subscription.name}');
    } catch (e) {
      print('❌ Error adding subscription to Supabase: $e');
      rethrow;
    }
  }
  
  /// Upload multiple subscriptions (batch operation)
  Future<void> uploadSubscriptions(List<Subscription> subscriptions) async {
    for (final subscription in subscriptions) {
      await addSubscription(subscription);
    }
  }
  
  /// Get subscription by ID from Supabase
  Future<Subscription?> getSubscriptionById(String id) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user for Supabase query');
        return null;
      }
      
      final response = await _supabase
          .from('subscriptions')
          .select()
          .eq('user_id', user.id)
          .eq('id', id)
          .single();
      
      if (response != null) {
        return Subscription(
          id: response['id'] ?? '',
          name: response['name'] ?? '',
          amount: (response['price'] ?? 0.0).toDouble(),
          billingCycle: response['billing_cycle'] ?? 'monthly',
          startDate: DateTime.parse(response['created_at'] ?? DateTime.now().toIso8601String()),
          renewalDate: DateTime.parse(response['next_payment_date'] ?? DateTime.now().toIso8601String()),
          status: response['is_active'] == true ? 'active' : 'paused',
          description: response['description'],
          website: response['website'],
          logoUrl: response['logo_url'],
          category: response['category'],
          currencyCode: response['currency'] ?? 'USD',
        );
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting subscription by ID from Supabase: $e');
      return null;
    }
  }
  
  /// Get subscriptions due soon
  Future<List<Subscription>> getSubscriptionsDueSoon() async {
    final activeSubscriptions = await getActiveSubscriptions();
    final now = DateTime.now();
    final threeDaysFromNow = now.add(const Duration(days: 3));
    
    return activeSubscriptions.where((subscription) {
      return subscription.renewalDate.isBefore(threeDaysFromNow) &&
             subscription.renewalDate.isAfter(now);
    }).toList();
  }
  
  /// Get overdue subscriptions
  Future<List<Subscription>> getOverdueSubscriptions() async {
    final activeSubscriptions = await getActiveSubscriptions();
    final now = DateTime.now();
    
    return activeSubscriptions.where((subscription) {
      return subscription.renewalDate.isBefore(now);
    }).toList();
  }
  
  /// Get all price changes (placeholder)
  Future<List<dynamic>> getAllPriceChanges() async {
    // This would query the price_changes table
    return [];
  }
  
  /// Update a subscription in Supabase
  Future<void> updateSubscription(Subscription subscription) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user for Supabase update');
      }
      
      final subscriptionData = {
        'name': subscription.name,
        'price': subscription.amount,
        'currency': subscription.currencyCode,
        'billing_cycle': subscription.billingCycle,
        'next_payment_date': subscription.renewalDate.toIso8601String(),
        'category': subscription.category,
        'logo_url': subscription.logoUrl,
        'is_active': subscription.status == 'active',
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await _supabase
          .from('subscriptions')
          .update(subscriptionData)
          .eq('user_id', user.id)
          .eq('id', subscription.id);
      
      print('✅ Updated subscription in Supabase: ${subscription.name}');
    } catch (e) {
      print('❌ Error updating subscription in Supabase: $e');
      rethrow;
    }
  }
  
  /// Delete a subscription from Supabase
  Future<void> deleteSubscription(String id) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user for Supabase delete');
      }
      
      await _supabase
          .from('subscriptions')
          .delete()
          .eq('user_id', user.id)
          .eq('id', id);
      
      print('✅ Deleted subscription from Supabase: $id');
    } catch (e) {
      print('❌ Error deleting subscription from Supabase: $e');
      rethrow;
    }
  }
  
  /// Close the repository
  Future<void> close() async {
    // Nothing to close for Supabase client
  }
} 