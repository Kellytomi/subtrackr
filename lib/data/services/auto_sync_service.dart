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
  
  /// Automatically sync data when user signs in (cloud-authoritative approach)
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
      
      // Get cloud subscriptions first (authoritative source)
      final cloudActiveSubscriptions = await _supabaseRepository.getActiveSubscriptions();
      final cloudPausedSubscriptions = await _supabaseRepository.getPausedSubscriptions();
      final cloudSubscriptions = [...cloudActiveSubscriptions, ...cloudPausedSubscriptions];
      print('☁️ Found ${cloudSubscriptions.length} cloud subscriptions');
      
      // Get local subscriptions
      final localActiveSubscriptions = await _localRepository.getActiveSubscriptions();
      final localPausedSubscriptions = await _localRepository.getPausedSubscriptions();
      final localSubscriptions = [...localActiveSubscriptions, ...localPausedSubscriptions];
      print('📱 Found ${localSubscriptions.length} local subscriptions');
      
      if (cloudSubscriptions.isNotEmpty) {
        // Cloud has data - treat cloud as authoritative and sync local to match
        print('☁️ Cloud has data - syncing local storage to match cloud (cloud-authoritative)');
        await _syncLocalToMatchCloud(cloudSubscriptions, localSubscriptions);
      } else if (localSubscriptions.isNotEmpty) {
        // Cloud is empty but local has data - upload local to cloud (first sign-in scenario)
        print('📱 Cloud is empty but local has data - uploading local subscriptions to cloud');
        await _uploadLocalToCloud(localSubscriptions);
      } else {
        // Both are empty - nothing to sync
        print('✅ Both cloud and local are empty - nothing to sync');
      }
      
      print('🎉 Auto-sync completed successfully');
      _completeSyncProcess();
      
    } catch (e) {
      print('❌ Auto-sync failed: $e');
      _completeSyncProcess();
    }
  }
  
  /// Sync local storage to match cloud data (cloud-authoritative)
  Future<void> _syncLocalToMatchCloud(List<Subscription> cloudSubscriptions, List<Subscription> localSubscriptions) async {
    try {
      // Step 1: Remove local subscriptions that don't exist in cloud
      final cloudSubscriptionNames = cloudSubscriptions.map((s) => s.name.toLowerCase()).toSet();
      for (final localSub in localSubscriptions) {
        if (!cloudSubscriptionNames.contains(localSub.name.toLowerCase())) {
          await _localRepository.deleteSubscription(localSub.id);
          print('🗑️ Removed from local: ${localSub.name}');
        }
      }
      
      // Step 2: Add cloud subscriptions that don't exist locally
      final localSubscriptionNames = localSubscriptions.map((s) => s.name.toLowerCase()).toSet();
      for (final cloudSub in cloudSubscriptions) {
        if (!localSubscriptionNames.contains(cloudSub.name.toLowerCase())) {
          await _localRepository.addSubscription(cloudSub);
          print('✅ Added to local: ${cloudSub.name}');
        }
      }
      
      print('✅ Local storage synced to match cloud');
    } catch (e) {
      print('❌ Failed to sync local to match cloud: $e');
    }
  }
  
  /// Upload local subscriptions to cloud (first sign-in scenario)
  Future<void> _uploadLocalToCloud(List<Subscription> localSubscriptions) async {
    try {
      for (final subscription in localSubscriptions) {
        try {
          await _supabaseRepository.addSubscription(subscription);
          print('✅ Uploaded to cloud: ${subscription.name}');
        } catch (e) {
          print('❌ Failed to upload ${subscription.name} to cloud: $e');
          // Continue with other subscriptions even if one fails
        }
      }
      print('✅ Local subscriptions uploaded to cloud');
    } catch (e) {
      print('❌ Failed to upload local subscriptions to cloud: $e');
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
      
      // Get all cloud subscriptions (active + paused)
      final cloudActiveSubscriptions = await _supabaseRepository.getActiveSubscriptions();
      final cloudPausedSubscriptions = await _supabaseRepository.getPausedSubscriptions();
      final cloudSubscriptions = [...cloudActiveSubscriptions, ...cloudPausedSubscriptions];
      print('☁️ Found ${cloudSubscriptions.length} cloud subscriptions');
      
      // Get current local subscriptions (active + paused)
      final localActiveSubscriptions = await _localRepository.getActiveSubscriptions();
      final localPausedSubscriptions = await _localRepository.getPausedSubscriptions();
      final localSubscriptions = [...localActiveSubscriptions, ...localPausedSubscriptions];
      print('📱 Found ${localSubscriptions.length} local subscriptions');
      
      // REPLACE local storage with cloud data (proper sync)
      // Step 1: Remove all local subscriptions that don't exist in cloud
      final cloudSubscriptionNames = cloudSubscriptions.map((s) => s.name.toLowerCase()).toSet();
      for (final localSub in localSubscriptions) {
        if (!cloudSubscriptionNames.contains(localSub.name.toLowerCase())) {
          try {
            await _localRepository.deleteSubscription(localSub.id);
            print('🗑️ Removed from local: ${localSub.name}');
          } catch (e) {
            print('❌ Failed to remove ${localSub.name} from local: $e');
          }
        }
      }
      
      // Step 2: Add cloud subscriptions that don't exist locally (get fresh local list after deletions)
      final updatedLocalActiveSubscriptions = await _localRepository.getActiveSubscriptions();
      final updatedLocalPausedSubscriptions = await _localRepository.getPausedSubscriptions();
      final updatedLocalSubscriptions = [...updatedLocalActiveSubscriptions, ...updatedLocalPausedSubscriptions];
      final updatedLocalSubscriptionNames = updatedLocalSubscriptions.map((s) => s.name.toLowerCase()).toSet();
      
      for (final cloudSub in cloudSubscriptions) {
        if (!updatedLocalSubscriptionNames.contains(cloudSub.name.toLowerCase())) {
          try {
            await _localRepository.addSubscription(cloudSub);
            print('✅ Added to local: ${cloudSub.name}');
          } catch (e) {
            print('❌ Failed to add ${cloudSub.name} to local: $e');
          }
        }
      }
      
      print('✅ Cloud-to-local sync completed - local storage now matches cloud');
      
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
  
  /// Clear local data when switching users for privacy protection
  Future<void> clearLocalDataForUserSwitch() async {
    try {
      print('🗑️ Clearing all local subscriptions...');
      final localSubscriptions = await _localRepository.getActiveSubscriptions();
      
      for (final subscription in localSubscriptions) {
        await _localRepository.deleteSubscription(subscription.id);
        print('🗑️ Cleared local subscription: ${subscription.name}');
      }
      
      print('✅ All local data cleared for user switch');
    } catch (e) {
      print('❌ Error clearing local data: $e');
      rethrow;
    }
  }

  /// Clean up resources
  void dispose() {
    stopSyncCompletionListener();
  }
} 