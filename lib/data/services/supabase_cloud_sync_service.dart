import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_auth_service.dart';
import 'auto_sync_service.dart';
import '../repositories/dual_subscription_repository.dart';

/// Service for handling Supabase cloud sync operations
class SupabaseCloudSyncService {
  final SupabaseAuthService _authService;
  final AutoSyncService _autoSyncService;
  final DualSubscriptionRepository _repository;
  
  StreamSubscription<AuthState>? _authSubscription;
  
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
        print('✅ User signed in, starting auto-sync...');
        _autoSyncService.autoSyncOnSignIn();
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
  
  /// Get current user
  User? get currentUser => _authService.currentUser;
  
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
    _autoSyncService.dispose();
    print('✅ SupabaseCloudSyncService disposed');
  }
} 