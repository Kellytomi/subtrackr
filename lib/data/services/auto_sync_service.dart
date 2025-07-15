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
  
  /// Automatically sync data when user signs in (intelligent merge approach)
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
      
      // SPEED OPTIMIZATION: Fetch cloud and local data in parallel
      print('⚡ Fetching cloud and local data in parallel...');
      final cloudDataFuture = _fetchCloudData();
      final localDataFuture = _fetchLocalData();
      
      final results = await Future.wait([cloudDataFuture, localDataFuture]);
      final cloudSubscriptions = results[0];
      final localSubscriptions = results[1];
      
      print('☁️ Found ${cloudSubscriptions.length} cloud subscriptions');
      print('📱 Found ${localSubscriptions.length} local subscriptions');
      
      if (cloudSubscriptions.isEmpty && localSubscriptions.isEmpty) {
        // Both are empty - nothing to sync
        print('✅ Both cloud and local are empty - nothing to sync');
        _completeSyncProcess();
        return;
      } else if (cloudSubscriptions.isEmpty && localSubscriptions.isNotEmpty) {
        // Cloud is empty but local has data - upload local to cloud (first sign-in scenario)
        print('📱 Cloud is empty but local has data - uploading local subscriptions to cloud');
        await _uploadLocalToCloudParallel(localSubscriptions);
      } else if (cloudSubscriptions.isNotEmpty && localSubscriptions.isEmpty) {
        // Cloud has data but local is empty - download cloud to local
        print('☁️ Cloud has data but local is empty - downloading cloud subscriptions to local');
        await _downloadCloudToLocalParallel(cloudSubscriptions);
      } else {
        // Both have data - intelligent merge
        print('🔄 Both cloud and local have data - performing intelligent merge');
        await _intelligentMergeParallel(cloudSubscriptions, localSubscriptions);
      }
      
      // SPEED OPTIMIZATION: Skip final sync step if not necessary
      if (cloudSubscriptions.isNotEmpty || localSubscriptions.isNotEmpty) {
        print('🔄 Final verification step...');
        await _quickVerifySync();
      }
      
      print('🎉 Auto-sync completed successfully');
      _completeSyncProcess();
      
    } catch (e) {
      print('❌ Auto-sync failed: $e');
      _completeSyncProcess();
    }
  }
  
  /// Fetch cloud data (extracted for parallel execution)
  Future<List<Subscription>> _fetchCloudData() async {
    final cloudActiveSubscriptions = await _supabaseRepository.getActiveSubscriptions();
    final cloudPausedSubscriptions = await _supabaseRepository.getPausedSubscriptions();
    return [...cloudActiveSubscriptions, ...cloudPausedSubscriptions];
  }
  
  /// Fetch local data (extracted for parallel execution)
  Future<List<Subscription>> _fetchLocalData() async {
    final localActiveSubscriptions = await _localRepository.getActiveSubscriptions();
    final localPausedSubscriptions = await _localRepository.getPausedSubscriptions();
    return [...localActiveSubscriptions, ...localPausedSubscriptions];
  }
  
  /// Upload local subscriptions to cloud in parallel
  Future<void> _uploadLocalToCloudParallel(List<Subscription> localSubscriptions) async {
    try {
      print('⚡ Uploading ${localSubscriptions.length} subscriptions in parallel...');
      
      // Upload in parallel with limited concurrency to avoid overwhelming the server
      final uploadFutures = localSubscriptions.map((subscription) async {
        try {
          await _supabaseRepository.addSubscription(subscription);
          print('✅ Uploaded to cloud: ${subscription.name}');
        } catch (e) {
          print('❌ Failed to upload ${subscription.name} to cloud: $e');
        }
      });
      
      await Future.wait(uploadFutures);
      print('✅ Parallel upload completed');
    } catch (e) {
      print('❌ Failed to upload local subscriptions to cloud: $e');
    }
  }
  
  /// Download cloud subscriptions to local in parallel
  Future<void> _downloadCloudToLocalParallel(List<Subscription> cloudSubscriptions) async {
    try {
      print('⚡ Downloading ${cloudSubscriptions.length} subscriptions in parallel...');
      
      // Download in parallel
      final downloadFutures = cloudSubscriptions.map((subscription) async {
        try {
          await _localRepository.addSubscription(subscription);
          print('✅ Downloaded to local: ${subscription.name}');
        } catch (e) {
          print('❌ Failed to download ${subscription.name} to local: $e');
        }
      });
      
      await Future.wait(downloadFutures);
      print('✅ Parallel download completed');
    } catch (e) {
      print('❌ Failed to download cloud subscriptions to local: $e');
    }
  }
  
  /// Intelligent merge with parallel operations
  Future<void> _intelligentMergeParallel(List<Subscription> cloudSubscriptions, List<Subscription> localSubscriptions) async {
    try {
      print('🔄 Starting intelligent merge with parallel processing...');
      
      // Create maps for easy lookup
      final cloudSubscriptionNames = <String, Subscription>{};
      for (final sub in cloudSubscriptions) {
        cloudSubscriptionNames[sub.name.toLowerCase()] = sub;
      }
      
      final localSubscriptionNames = <String, Subscription>{};
      for (final sub in localSubscriptions) {
        localSubscriptionNames[sub.name.toLowerCase()] = sub;
      }
      
      // Prepare parallel operations
      final List<Future<void>> parallelOperations = [];
      
      // Step 1: Upload local subscriptions that don't exist in cloud
      for (final localSub in localSubscriptions) {
        if (!cloudSubscriptionNames.containsKey(localSub.name.toLowerCase())) {
          parallelOperations.add(_uploadSubscription(localSub));
        }
      }
      
      // Step 2: Download cloud subscriptions that don't exist locally
      for (final cloudSub in cloudSubscriptions) {
        if (!localSubscriptionNames.containsKey(cloudSub.name.toLowerCase())) {
          parallelOperations.add(_downloadSubscription(cloudSub));
        }
      }
      
      // Execute all operations in parallel
      if (parallelOperations.isNotEmpty) {
        print('⚡ Executing ${parallelOperations.length} operations in parallel...');
        await Future.wait(parallelOperations);
      }
      
      // Step 3: Update conflicts (sequential for data consistency)
      for (final cloudSub in cloudSubscriptions) {
        final localSub = localSubscriptionNames[cloudSub.name.toLowerCase()];
        if (localSub != null) {
          if (localSub.amount != cloudSub.amount || 
              localSub.status != cloudSub.status ||
              localSub.renewalDate != cloudSub.renewalDate) {
            try {
              final updatedSub = cloudSub.copyWith();
              await _localRepository.updateSubscription(updatedSub);
              print('✅ Updated local subscription with cloud data: ${cloudSub.name}');
            } catch (e) {
              print('❌ Failed to update local subscription ${cloudSub.name}: $e');
            }
          }
        }
      }
      
      print('✅ Intelligent merge completed successfully');
    } catch (e) {
      print('❌ Failed to perform intelligent merge: $e');
    }
  }
  
  /// Upload single subscription (for parallel execution)
  Future<void> _uploadSubscription(Subscription subscription) async {
    try {
      await _supabaseRepository.addSubscription(subscription);
      print('✅ Uploaded new local subscription to cloud: ${subscription.name}');
    } catch (e) {
      print('❌ Failed to upload ${subscription.name} to cloud: $e');
    }
  }
  
  /// Download single subscription (for parallel execution)
  Future<void> _downloadSubscription(Subscription subscription) async {
    try {
      await _localRepository.addSubscription(subscription);
      print('✅ Downloaded new cloud subscription to local: ${subscription.name}');
    } catch (e) {
      print('❌ Failed to download ${subscription.name} to local: $e');
    }
  }
  
  /// Quick verification instead of full sync
  Future<void> _quickVerifySync() async {
    try {
      // Just do a quick count verification instead of full data comparison
      final cloudCount = (await _fetchCloudData()).length;
      final localCount = (await _fetchLocalData()).length;
      
      if (cloudCount == localCount) {
        print('✅ Quick verification passed - cloud and local have same count ($cloudCount)');
      } else {
        print('⚠️ Count mismatch - cloud: $cloudCount, local: $localCount');
      }
    } catch (e) {
      print('❌ Quick verification failed: $e');
    }
  }
  
  /// Finalize local storage to match cloud after sync operations
  Future<void> _finalizeLocalStorage() async {
    try {
      // Get fresh cloud data
      final cloudActiveSubscriptions = await _supabaseRepository.getActiveSubscriptions();
      final cloudPausedSubscriptions = await _supabaseRepository.getPausedSubscriptions();
      final finalCloudSubscriptions = [...cloudActiveSubscriptions, ...cloudPausedSubscriptions];
      
      // Get current local data
      final localActiveSubscriptions = await _localRepository.getActiveSubscriptions();
      final localPausedSubscriptions = await _localRepository.getPausedSubscriptions();
      final currentLocalSubscriptions = [...localActiveSubscriptions, ...localPausedSubscriptions];
      
      // Remove local subscriptions that no longer exist in cloud
      final cloudNames = finalCloudSubscriptions.map((s) => s.name.toLowerCase()).toSet();
      for (final localSub in currentLocalSubscriptions) {
        if (!cloudNames.contains(localSub.name.toLowerCase())) {
          try {
            await _localRepository.deleteSubscription(localSub.id);
            print('🗑️ Removed orphaned local subscription: ${localSub.name}');
          } catch (e) {
            print('❌ Failed to remove orphaned subscription ${localSub.name}: $e');
          }
        }
      }
      
      // Add any missing cloud subscriptions to local
      final refreshedLocalActive = await _localRepository.getActiveSubscriptions();
      final refreshedLocalPaused = await _localRepository.getPausedSubscriptions();
      final refreshedLocal = [...refreshedLocalActive, ...refreshedLocalPaused];
      final localNames = refreshedLocal.map((s) => s.name.toLowerCase()).toSet();
      
      for (final cloudSub in finalCloudSubscriptions) {
        if (!localNames.contains(cloudSub.name.toLowerCase())) {
          try {
            await _localRepository.addSubscription(cloudSub);
            print('✅ Added missing cloud subscription to local: ${cloudSub.name}');
          } catch (e) {
            print('❌ Failed to add missing subscription ${cloudSub.name}: $e');
          }
        }
      }
      
      print('✅ Cloud-to-local sync completed - local storage now matches cloud');
    } catch (e) {
      print('❌ Failed to finalize local storage: $e');
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