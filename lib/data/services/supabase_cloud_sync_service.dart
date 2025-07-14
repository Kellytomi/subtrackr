import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_auth_service.dart';
import 'auto_sync_service.dart';
import '../repositories/dual_subscription_repository.dart';
import '../../domain/entities/subscription.dart';
import 'settings_service.dart';

/// Service for handling Supabase cloud sync operations
class SupabaseCloudSyncService {
  final SupabaseAuthService _authService;
  final AutoSyncService _autoSyncService;
  final DualSubscriptionRepository _repository;
  
  // Callback for real-time updates
  void Function(List<Subscription>)? _onRealTimeUpdate;
  
  // Current user ID for filtering real-time events
  String? _currentUserId;
  
  StreamSubscription<AuthState>? _authSubscription;
  RealtimeChannel? _realtimeChannel;
  Timer? _periodicSyncTimer;
  
  SupabaseCloudSyncService({
    required SupabaseAuthService authService,
    required AutoSyncService autoSyncService,
    required DualSubscriptionRepository repository,
  }) : _authService = authService,
       _autoSyncService = autoSyncService,
       _repository = repository;
  
  /// Initialize the cloud sync service
  Future<void> initialize() async {
    print('🔄 Initializing SupabaseCloudSyncService...');
    
    // Start sync completion listener
    _autoSyncService.startSyncCompletionListener();
    
    // Listen to auth state changes
    _authSubscription = _authService.onAuthStateChange.listen((authState) {
      _handleAuthStateChange(authState);
    });
    
    print('✅ SupabaseCloudSyncService initialized');
  }
  
  /// Handle authentication state changes
  void _handleAuthStateChange(AuthState authState) {
    print('🔄 Auth state changed: ${authState.event}');
    
    switch (authState.event) {
      case AuthChangeEvent.signedIn:
        print('✅ User signed in: ${authState.session?.user.email}');
        _handleUserSignIn(authState.session?.user);
        break;
        
      case AuthChangeEvent.signedOut:
        print('👋 User signed out, syncing cloud to local...');
        _autoSyncService.syncCloudToLocalOnSignOut();
        break;
        
      case AuthChangeEvent.tokenRefreshed:
        print('🔄 Token refreshed');
        break;
        
      default:
        print('ℹ️ Auth event: ${authState.event}');
    }
  }

  /// Handle user sign-in with proper user isolation
  Future<void> _handleUserSignIn(User? user) async {
    if (user == null) return;
    
    try {
      // Check if this is a different user than the last one
      final lastUserId = await _getLastUserId();
      final currentUserId = user.id;
      
      print('🔍 User check: lastUser=$lastUserId, currentUser=$currentUserId');
      
      if (lastUserId != null && lastUserId != currentUserId) {
        // Different user signing in - clear local data for privacy
        print('🚨 Different user detected! Clearing local data for privacy protection');
        await _clearLocalDataForUserSwitch();
      }
      
      // Save current user ID
      await _saveLastUserId(currentUserId);
      
      // Now safely start auto-sync
      print('✅ Starting auto-sync for user: ${user.email}');
      await _autoSyncService.autoSyncOnSignIn();
      
    } catch (e) {
      print('❌ Error handling user sign-in: $e');
      // Still try to sync even if user checking fails
      await _autoSyncService.autoSyncOnSignIn();
    }
  }

  /// Clear local data when switching users for privacy protection
  Future<void> _clearLocalDataForUserSwitch() async {
    try {
      print('🗑️ Clearing local subscriptions for user privacy...');
      await _autoSyncService.clearLocalDataForUserSwitch();
      print('✅ Local data cleared successfully');
    } catch (e) {
      print('❌ Error clearing local data: $e');
    }
  }

  /// Get the last signed-in user ID from local storage
  Future<String?> _getLastUserId() async {
    try {
      final settingsService = SettingsService();
      return settingsService.getLastUserId();
    } catch (e) {
      print('❌ Error getting last user ID: $e');
      return null;
    }
  }

  /// Save the current user ID to local storage
  Future<void> _saveLastUserId(String userId) async {
    try {
      final settingsService = SettingsService();
      await settingsService.setLastUserId(userId);
      print('💾 Saved user ID for future reference: $userId');
    } catch (e) {
      print('❌ Error saving user ID: $e');
    }
  }
  
  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      print('🔄 Starting Google Sign-In...');
      
      final response = await _authService.signInWithGoogle();
      
      if (response?.user != null) {
        print('✅ Google Sign-In successful');
        return true;
      } else {
        print('❌ Google Sign-In failed');
        return false;
      }
    } catch (e) {
      print('❌ Google Sign-In error: $e');
      return false;
    }
  }
  
  /// Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      print('🔄 Starting email/password sign-in...');
      
      final response = await _authService.signInWithEmailAndPassword(email, password);
      
      if (response?.user != null) {
        print('✅ Email/password sign-in successful');
        return true;
      } else {
        print('❌ Email/password sign-in failed');
        return false;
      }
    } catch (e) {
      print('❌ Email/password sign-in error: $e');
      return false;
    }
  }
  
  /// Create account with email and password
  Future<bool> signUpWithEmailAndPassword(String email, String password) async {
    try {
      print('🔄 Starting account creation...');
      
      final response = await _authService.createAccountWithEmailAndPassword(email, password);
      
      if (response?.user != null) {
        print('✅ Account creation successful');
        return true;
      } else {
        print('❌ Account creation failed');
        return false;
      }
    } catch (e) {
      print('❌ Account creation error: $e');
      return false;
    }
  }
  
  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      print('✅ Password reset email sent');
    } catch (e) {
      print('❌ Password reset error: $e');
      rethrow;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      print('🔄 Starting sign out...');
      
      // Sync cloud data to local before signing out
      await _autoSyncService.syncCloudToLocalOnSignOut();
      
      // Sign out from Supabase
      await _authService.signOut();
      
      print('✅ Sign out completed');
    } catch (e) {
      print('❌ Sign out error: $e');
      rethrow;
    }
  }
  
  /// Get current user information
  Map<String, dynamic>? get userProfile => _authService.userProfile;
  
  /// Check if user is authenticated
  bool get isAuthenticated => _authService.isAuthenticated;
  
  /// Check if user is signed in (alias for isAuthenticated)
  bool get isUserSignedIn => _authService.isAuthenticated;
  
  /// Get current user
  User? get currentUser => _authService.currentUser;
  
  /// Sync subscriptions (placeholder for compatibility)
  Future<List<Subscription>> syncSubscriptions(List<Subscription> localSubscriptions) async {
    if (!isAuthenticated) {
      print('❌ Cannot sync - user not authenticated');
      return localSubscriptions;
    }
    
    // For now, just return the local subscriptions
    // The actual sync logic is handled by AutoSyncService
    return localSubscriptions;
  }
  
  /// Auto backup a subscription (placeholder for compatibility)
  Future<void> autoBackupSubscription(Subscription subscription) async {
    if (!isAuthenticated) {
      print('❌ Cannot auto backup - user not authenticated');
      return;
    }
    
    try {
      // Use the repository to add the subscription to cloud storage
      await _repository.addSubscription(subscription);
      print('✅ Auto backup completed for: ${subscription.name}');
    } catch (e) {
      print('❌ Auto backup failed for ${subscription.name}: $e');
    }
  }
  
  /// Auto backup subscription deletion (placeholder for compatibility)
  Future<void> autoBackupDeleteSubscription(String subscriptionId) async {
    if (!isAuthenticated) {
      print('❌ Cannot auto backup deletion - user not authenticated');
      return;
    }
    
    try {
      // Use the repository to delete the subscription from cloud storage
      await _repository.deleteSubscription(subscriptionId);
      print('✅ Auto backup deletion completed for: $subscriptionId');
    } catch (e) {
      print('❌ Auto backup deletion failed for $subscriptionId: $e');
    }
  }
  
  /// Set callback for real-time updates
  void setRealTimeUpdateCallback(void Function(List<Subscription>) callback) {
    _onRealTimeUpdate = callback;
  }
  
  /// Start sync - Set up real-time subscription to subscriptions table
  Future<void> startSync() async {
    if (!isAuthenticated) {
      print('❌ Cannot start sync - user not authenticated');
      return;
    }
    
    final user = currentUser;
    if (user == null) {
      print('❌ No current user for real-time sync');
      return;
    }
    
    // Stop any existing subscription
    stopSync();
    
    // Store current user ID for filtering
    _currentUserId = user.id;
    
    try {
      print('🔄 Setting up real-time subscription for user: ${user.email}');
      
      // Create real-time channel for subscriptions table
      // Note: We subscribe to ALL events and filter in the callback because
      // DELETE events don't work well with filters (row is already gone)
      _realtimeChannel = Supabase.instance.client
          .channel('subscriptions_realtime_${user.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'subscriptions',
                         callback: _handleRealtimeChange,
          )
          .subscribe();
      
      // Wait for subscription to be established
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Start periodic sync as a fallback (every 5 seconds for debugging)
      _startPeriodicSync();
      
      print('✅ Real-time sync started successfully');
    } catch (e) {
      print('❌ Error starting real-time sync: $e');
    }
  }
  
  /// Stop sync - Clean up real-time subscription
  void stopSync() {
    if (_realtimeChannel != null) {
      print('🔄 Stopping real-time subscription...');
      Supabase.instance.client.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
      print('✅ Real-time sync stopped');
    }
    
    _stopPeriodicSync();
  }
  
  /// Start periodic sync as fallback for real-time
  void _startPeriodicSync() {
    _stopPeriodicSync(); // Stop any existing timer
    
    _periodicSyncTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!isAuthenticated || _onRealTimeUpdate == null) {
        timer.cancel();
        return;
      }
      
      try {
        print('⏰ Periodic sync check...');
        await _refreshSubscriptionsData();
      } catch (e) {
        print('❌ Periodic sync failed: $e');
      }
    });
    
    print('⏰ Periodic sync started (5s intervals for debugging)');
  }
  
  /// Stop periodic sync
  void _stopPeriodicSync() {
    if (_periodicSyncTimer != null) {
      _periodicSyncTimer!.cancel();
      _periodicSyncTimer = null;
      print('⏰ Periodic sync stopped');
    }
  }
  
  /// Handle real-time changes from Supabase
  void _handleRealtimeChange(PostgresChangePayload payload) async {
    try {
      print('📡 Real-time change received: ${payload.eventType}');
      print('📡 Table: ${payload.table}');
      print('📡 Old Record: ${payload.oldRecord}');
      print('📡 New Record: ${payload.newRecord}');
      
      // Filter events for current user only
      String? eventUserId;
      
      if (payload.eventType == 'DELETE') {
        // For DELETE events, user_id is in oldRecord
        eventUserId = payload.oldRecord?['user_id']?.toString();
      } else {
        // For INSERT/UPDATE events, user_id is in newRecord
        eventUserId = payload.newRecord?['user_id']?.toString();
      }
      
      if (eventUserId != _currentUserId) {
        print('📡 Ignoring event - not for current user ($eventUserId vs $_currentUserId)');
        return;
      }
      
      print('📡 Processing event for current user');
      
      // Always fetch fresh data after any change to ensure consistency
      await _refreshSubscriptionsData();
      
    } catch (e) {
      print('❌ Error handling real-time change: $e');
    }
  }
  
  /// Refresh subscriptions data and notify callback
  Future<void> _refreshSubscriptionsData() async {
    try {
      if (!isAuthenticated || _onRealTimeUpdate == null) return;
      
      // Fetch latest subscriptions ONLY from cloud (no local fallback)
      // This prevents local data from overriding real-time deletions
      final cloudSubscriptions = await _repository.getCloudSubscriptions();
      
      // Notify the callback with fresh data
      _onRealTimeUpdate!(cloudSubscriptions);
      print('📡 Real-time update notification sent with ${cloudSubscriptions.length} subscriptions');
      
    } catch (e) {
      print('❌ Error refreshing subscriptions data: $e');
    }
  }
  
  /// Manually trigger sync (for testing/debugging)
  Future<void> manualSync() async {
    if (_authService.isAuthenticated) {
      print('🔄 Manual sync triggered');
      await _autoSyncService.autoSyncOnSignIn();
    } else {
      print('❌ Cannot sync - user not authenticated');
    }
  }
  
  /// Dispose and clean up resources
  void dispose() {
    _authSubscription?.cancel();
    stopSync(); // Clean up real-time subscription and periodic sync
    _autoSyncService.dispose();
    print('✅ SupabaseCloudSyncService disposed');
  }
} 