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
  
  /// Add a subscription to the appropriate storage
  Future<void> addSubscription(Subscription subscription) async {
    if (_authService.isAuthenticated) {
      // Add to cloud storage
      await _supabaseRepository.addSubscription(subscription);
    } else {
      // Add to local storage
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
  
  /// Delete a subscription from the appropriate storage
  Future<void> deleteSubscription(String id) async {
    if (_authService.isAuthenticated) {
      await _supabaseRepository.deleteSubscription(id);
    } else {
      await _localRepository.deleteSubscription(id);
    }
  }
  
  /// Close both repositories
  Future<void> close() async {
    await _localRepository.close();
    await _supabaseRepository.close();
  }
} 