import '../../domain/entities/subscription.dart';
import 'local_subscription_repository.dart';
import 'supabase_subscription_repository.dart';
import '../services/supabase_auth_service.dart';

/// Repository that manages both local and cloud subscription storage
class DualSubscriptionRepository {
  final LocalSubscriptionRepository _localRepository;
  final SupabaseSubscriptionRepository _supabaseRepository;
  final SupabaseAuthService _authService;
  
  DualSubscriptionRepository({
    required LocalSubscriptionRepository localRepository,
    required SupabaseSubscriptionRepository supabaseRepository,
    required SupabaseAuthService authService,
  }) : _localRepository = localRepository,
       _supabaseRepository = supabaseRepository,
       _authService = authService;
  
  /// Initialize both repositories
  Future<void> init() async {
    await _localRepository.init();
    await _supabaseRepository.init();
    print('✅ DualSubscriptionRepository initialized');
  }
  
  /// Get all active subscriptions from the appropriate source
  Future<List<Subscription>> getActiveSubscriptions() async {
    if (_authService.isAuthenticated) {
      // User is authenticated, get from cloud
      return await _supabaseRepository.getActiveSubscriptions();
    } else {
      // User is in guest mode, get from local storage
      return await _localRepository.getActiveSubscriptions();
    }
  }
  
  /// Get all subscriptions (active and paused) from the appropriate source
  Future<List<Subscription>> getAllSubscriptions() async {
    if (_authService.isAuthenticated) {
      try {
        // Get both active and paused subscriptions from cloud
        final activeSubscriptions = await _supabaseRepository.getActiveSubscriptions();
        final pausedSubscriptions = await _supabaseRepository.getPausedSubscriptions();
        final cloudSubscriptions = [...activeSubscriptions, ...pausedSubscriptions];
        
        // If cloud is empty but we might have local data, get local as fallback
        if (cloudSubscriptions.isEmpty) {
          final localActiveSubscriptions = await _localRepository.getActiveSubscriptions();
          final localPausedSubscriptions = await _localRepository.getPausedSubscriptions();
          final localSubscriptions = [...localActiveSubscriptions, ...localPausedSubscriptions];
          
          if (localSubscriptions.isNotEmpty) {
            print('☁️ Cloud empty, found ${localSubscriptions.length} local subscriptions, returning local data');
            return localSubscriptions;
          }
        }
        
        return cloudSubscriptions;
      } catch (e) {
        print('❌ Error getting cloud subscriptions, falling back to local: $e');
        // Fall back to local storage if cloud fails
        final activeSubscriptions = await _localRepository.getActiveSubscriptions();
        final pausedSubscriptions = await _localRepository.getPausedSubscriptions();
        return [...activeSubscriptions, ...pausedSubscriptions];
      }
    } else {
      // Get both active and paused subscriptions from local storage
      final activeSubscriptions = await _localRepository.getActiveSubscriptions();
      final pausedSubscriptions = await _localRepository.getPausedSubscriptions();
      return [...activeSubscriptions, ...pausedSubscriptions];
    }
  }
  
  /// Get all subscriptions from cloud storage (for sync operations)
  Future<List<Subscription>> getCloudSubscriptions() async {
    if (!_authService.isAuthenticated) {
      return [];
    }
    
    // Get cloud subscriptions in parallel for better performance
    final results = await Future.wait([
      _supabaseRepository.getActiveSubscriptions(),
      _supabaseRepository.getPausedSubscriptions(),
    ]);
    return [...results[0], ...results[1]];
  }
  
  /// Get all paused subscriptions from the appropriate source
  Future<List<Subscription>> getPausedSubscriptions() async {
    if (_authService.isAuthenticated) {
      return await _supabaseRepository.getPausedSubscriptions();
    } else {
      return await _localRepository.getPausedSubscriptions();
    }
  }
  
  /// Get cancelled subscriptions from the appropriate source
  Future<List<Subscription>> getCancelledSubscriptions() async {
    if (_authService.isAuthenticated) {
      return await _supabaseRepository.getCancelledSubscriptions();
    } else {
      return await _localRepository.getCancelledSubscriptions();
    }
  }
  
  /// Clear all subscriptions from both local and cloud storage
  Future<void> clearAllSubscriptions() async {
    if (_authService.isAuthenticated) {
      // For authenticated users, clear from both cloud and local in parallel
      await Future.wait([
        _supabaseRepository.clearAllSubscriptions(),
        _localRepository.clearAllSubscriptions(),
      ]);
      print('✅ Cleared all subscriptions from both cloud and local');
    } else {
      // For guest users, only clear from local storage
      await _localRepository.clearAllSubscriptions();
      print('✅ Cleared all subscriptions from local storage');
    }
  }
  
  /// Add a subscription to the appropriate storage
  Future<void> addSubscription(Subscription subscription) async {
    if (_authService.isAuthenticated) {
      // Always save to local storage first (as backup)
      await _localRepository.addSubscription(subscription);
      
      try {
        // Then try to save to cloud storage
        await _supabaseRepository.addSubscription(subscription);
        print('✅ Subscription saved to both local and cloud: ${subscription.name}');
      } catch (e) {
        print('⚠️ Cloud save failed, subscription saved locally: ${subscription.name} - $e');
        // Data is still saved locally, so operation is not a complete failure
      }
    } else {
      // Add to local storage only
      await _localRepository.addSubscription(subscription);
    }
  }
  
  /// Upload subscriptions (used during sync)
  Future<void> uploadSubscriptions(List<Subscription> subscriptions) async {
    if (_authService.isAuthenticated) {
      await _supabaseRepository.uploadSubscriptions(subscriptions);
    } else {
      await _localRepository.uploadSubscriptions(subscriptions);
    }
  }
  
  /// Get subscription by ID from the appropriate source
  Future<Subscription?> getSubscriptionById(String id) async {
    if (_authService.isAuthenticated) {
      return await _supabaseRepository.getSubscriptionById(id);
    } else {
      return await _localRepository.getSubscriptionById(id);
    }
  }
  
  /// Get subscriptions due soon from the appropriate source
  Future<List<Subscription>> getSubscriptionsDueSoon() async {
    if (_authService.isAuthenticated) {
      return await _supabaseRepository.getSubscriptionsDueSoon();
    } else {
      return await _localRepository.getSubscriptionsDueSoon();
    }
  }
  
  /// Get overdue subscriptions from the appropriate source
  Future<List<Subscription>> getOverdueSubscriptions() async {
    if (_authService.isAuthenticated) {
      return await _supabaseRepository.getOverdueSubscriptions();
    } else {
      return await _localRepository.getOverdueSubscriptions();
    }
  }
  
  /// Get all price changes from the appropriate source
  Future<List<dynamic>> getAllPriceChanges() async {
    if (_authService.isAuthenticated) {
      return await _supabaseRepository.getAllPriceChanges();
    } else {
      return await _localRepository.getAllPriceChanges();
    }
  }
  
  /// Update a subscription in the appropriate storage
  Future<void> updateSubscription(Subscription subscription) async {
    if (_authService.isAuthenticated) {
      await _supabaseRepository.updateSubscription(subscription);
    } else {
      await _localRepository.updateSubscription(subscription);
    }
  }
  
  /// Delete a subscription from both local and cloud storage
  Future<void> deleteSubscription(String id) async {
    if (_authService.isAuthenticated) {
      // For authenticated users, delete from both cloud and local in parallel
      await Future.wait([
        _supabaseRepository.deleteSubscription(id),
        _localRepository.deleteSubscription(id),
      ]);
      print('✅ Deleted subscription from both cloud and local: $id');
    } else {
      // For guest users, only delete from local storage
      await _localRepository.deleteSubscription(id);
      print('✅ Deleted subscription from local storage: $id');
    }
  }
  
  /// Close both repositories
  Future<void> close() async {
    await _localRepository.close();
    await _supabaseRepository.close();
  }
} 