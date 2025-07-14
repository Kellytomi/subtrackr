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
          .eq('status', 'active');
      
      final subscriptions = <Subscription>[];
      for (final data in response) {
        try {
          // Convert Supabase data to Subscription entity
          final subscription = Subscription(
            id: (data['id'] as String?) ?? '',
            name: (data['name'] as String?) ?? '',
            amount: ((data['price'] as num?) ?? 0.0).toDouble(),
            billingCycle: (data['billing_cycle'] as String?) ?? 'monthly',
            startDate: DateTime.parse((data['start_date'] as String?) ?? DateTime.now().toIso8601String()),
            renewalDate: DateTime.parse((data['next_billing_date'] as String?) ?? DateTime.now().toIso8601String()),
            status: (data['status'] as String?) ?? 'active',
            description: data['description'] as String?,
            website: data['website'] as String?,
            logoUrl: data['logo_url'] as String?,
            category: data['category'] as String?,
            currencyCode: (data['currency_code'] as String?) ?? 'USD',
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
          .eq('status', 'paused');
      
      final subscriptions = <Subscription>[];
      for (final data in response) {
        try {
          // Convert Supabase data to Subscription entity
          final subscription = Subscription(
            id: (data['id'] as String?) ?? '',
            name: (data['name'] as String?) ?? '',
            amount: ((data['price'] as num?) ?? 0.0).toDouble(),
            billingCycle: (data['billing_cycle'] as String?) ?? 'monthly',
            startDate: DateTime.parse((data['start_date'] as String?) ?? DateTime.now().toIso8601String()),
            renewalDate: DateTime.parse((data['next_billing_date'] as String?) ?? DateTime.now().toIso8601String()),
            status: 'paused',
            description: data['description'] as String?,
            website: data['website'] as String?,
            logoUrl: data['logo_url'] as String?,
            category: data['category'] as String?,
            currencyCode: (data['currency_code'] as String?) ?? 'USD',
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
        'currency_code': subscription.currencyCode,
        'billing_cycle': subscription.billingCycle,
        'next_billing_date': subscription.renewalDate.toIso8601String(),
        'category': subscription.category,
        'logo_url': subscription.logoUrl,
        'status': subscription.status,
        'description': subscription.description,
        'website': subscription.website,
        'start_date': subscription.startDate.toIso8601String(),
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
          id: (response['id'] as String?) ?? '',
          name: (response['name'] as String?) ?? '',
          amount: ((response['price'] as num?) ?? 0.0).toDouble(),
          billingCycle: (response['billing_cycle'] as String?) ?? 'monthly',
          startDate: DateTime.parse((response['start_date'] as String?) ?? DateTime.now().toIso8601String()),
          renewalDate: DateTime.parse((response['next_billing_date'] as String?) ?? DateTime.now().toIso8601String()),
          status: (response['status'] as String?) ?? 'active',
          description: response['description'] as String?,
          website: response['website'] as String?,
          logoUrl: response['logo_url'] as String?,
          category: response['category'] as String?,
          currencyCode: (response['currency_code'] as String?) ?? 'USD',
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
        'currency_code': subscription.currencyCode,
        'billing_cycle': subscription.billingCycle,
        'next_billing_date': subscription.renewalDate.toIso8601String(),
        'category': subscription.category,
        'logo_url': subscription.logoUrl,
        'status': subscription.status,
        'description': subscription.description,
        'website': subscription.website,
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
      
      final response = await _supabase
          .from('subscriptions')
          .delete()
          .eq('user_id', user.id)
          .eq('id', id)
          .select(); // Get the deleted row to confirm it existed
      
      if (response.isEmpty) {
        print('⚠️ No subscription found to delete with ID: $id (may have been already deleted)');
      } else {
        print('✅ Deleted subscription from Supabase: $id');
      }
    } catch (e) {
      print('❌ Error deleting subscription from Supabase: $e');
      rethrow;
    }
  }
  
  /// Clear all subscriptions from Supabase for the current user
  Future<void> clearAllSubscriptions() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user for Supabase clear');
      }
      
      await _supabase
          .from('subscriptions')
          .delete()
          .eq('user_id', user.id);
      
      print('✅ Cleared all subscriptions from Supabase');
    } catch (e) {
      print('❌ Error clearing all subscriptions from Supabase: $e');
      rethrow;
    }
  }
  
  /// Close the repository
  Future<void> close() async {
    // Nothing to close for Supabase client
  }
} 