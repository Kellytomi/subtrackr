import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/local_subscription_repository.dart';
import '../repositories/supabase_subscription_repository.dart';
import '../../domain/entities/subscription.dart';

/// Service for automatically syncing local data to Supabase cloud
class AutoSyncService {
  final LocalSubscriptionRepository _localRepository;
  final SupabaseSubscriptionRepository _supabaseRepository;
  
  bool _isSyncing = false;
  StreamController<bool>? _syncCompletionController;
  
  AutoSyncService({
    required LocalSubscriptionRepository localRepository,
    required SupabaseSubscriptionRepository supabaseRepository,
  }) : _localRepository = localRepository,
       _supabaseRepository = supabaseRepository;
  
  /// Whether auto-sync is currently in progress
  bool get isSyncing => _isSyncing;
  
  /// Stream that emits when sync completes
  Stream<bool> get onSyncComplete => _syncCompletionController?.stream ?? const Stream.empty();
  
  /// Start listening for sync completion events
  void startSyncCompletionListener() {
    _syncCompletionController ??= StreamController<bool>.broadcast();
  }
  
  /// Stop listening for sync completion events
  void stopSyncCompletionListener() {
    _syncCompletionController?.close();
    _syncCompletionController = null;
  }
  
  /// Automatically sync local subscriptions to cloud when user signs in
  Future<void> autoSyncOnSignIn() async {
    if (_isSyncing) {
      print('⏳ Auto-sync already in progress, skipping...');
      return;
    }
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user for auto-sync');
        return;
      }
      
      _isSyncing = true;
      print('🔄 Starting auto-sync for user: ${user.email}');
      
      // Get all local subscriptions
      final localSubscriptions = await _localRepository.getActiveSubscriptions();
      print('📱 Found ${localSubscriptions.length} local subscriptions to sync');
      
      if (localSubscriptions.isEmpty) {
        print('✅ No local subscriptions to sync');
        _completeSyncProcess();
        return;
      }
      
      // Get existing cloud subscriptions to avoid duplicates
      final cloudSubscriptions = await _supabaseRepository.getActiveSubscriptions();
      final cloudSubscriptionNames = cloudSubscriptions.map((s) => s.name.toLowerCase()).toSet();
      
      // Filter out subscriptions that already exist in cloud (by name)
      final subscriptionsToSync = localSubscriptions.where((localSub) {
        return !cloudSubscriptionNames.contains(localSub.name.toLowerCase());
      }).toList();
      
      print('☁️ ${subscriptionsToSync.length} new subscriptions to upload to cloud');
      
      // Upload new subscriptions to cloud
      for (final subscription in subscriptionsToSync) {
        try {
          // Create new subscription with user_id for cloud storage
          final cloudSubscription = Subscription(
            id: subscription.id, // Keep original ID for consistency
            name: subscription.name,
            price: subscription.price,
            currency: subscription.currency,
            billingCycle: subscription.billingCycle,
            nextPaymentDate: subscription.nextPaymentDate,
            category: subscription.category,
            logoUrl: subscription.logoUrl,
            isActive: subscription.isActive,
            createdAt: subscription.createdAt,
            updatedAt: DateTime.now(),
          );
          
          await _supabaseRepository.addSubscription(cloudSubscription);
          print('✅ Synced subscription: ${subscription.name}');
        } catch (e) {
          print('❌ Failed to sync subscription ${subscription.name}: $e');
          // Continue with other subscriptions even if one fails
        }
      }
      
      print('🎉 Auto-sync completed successfully');
      _completeSyncProcess();
      
    } catch (e) {
      print('❌ Auto-sync failed: $e');
      _completeSyncProcess();
    }
  }
  
  /// Save cloud data to local storage before sign-out
  Future<void> syncCloudToLocalOnSignOut() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user for cloud-to-local sync');
        return;
      }
      
      print('📥 Syncing cloud subscriptions to local storage before sign-out');
      
      // Get all cloud subscriptions
      final cloudSubscriptions = await _supabaseRepository.getActiveSubscriptions();
      print('☁️ Found ${cloudSubscriptions.length} cloud subscriptions');
      
      // Get current local subscriptions
      final localSubscriptions = await _localRepository.getActiveSubscriptions();
      final localSubscriptionNames = localSubscriptions.map((s) => s.name.toLowerCase()).toSet();
      
      // Add cloud subscriptions that don't exist locally
      for (final cloudSub in cloudSubscriptions) {
        if (!localSubscriptionNames.contains(cloudSub.name.toLowerCase())) {
          try {
            await _localRepository.addSubscription(cloudSub);
            print('✅ Saved to local: ${cloudSub.name}');
          } catch (e) {
            print('❌ Failed to save ${cloudSub.name} locally: $e');
          }
        }
      }
      
      print('✅ Cloud-to-local sync completed');
      
    } catch (e) {
      print('❌ Cloud-to-local sync failed: $e');
    }
  }
  
  /// Complete the sync process and notify listeners
  void _completeSyncProcess() {
    _isSyncing = false;
    _syncCompletionController?.add(true);
    print('✅ Auto-sync process completed');
  }
  
  /// Clean up resources
  void dispose() {
    stopSyncCompletionListener();
  }
} 