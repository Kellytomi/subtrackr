import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service for handling Supabase authentication
class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  /// Get current authenticated user
  User? get currentUser => _supabase.auth.currentUser;
  
  /// Check if user is currently authenticated
  bool get isAuthenticated => currentUser != null;
  
  /// Stream of authentication state changes
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;
  
  /// Sign in with Google using native Google Sign-In
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      print('🔄 Starting Google Sign-In with Supabase...');
      print('🔍 Platform: ${Platform.operatingSystem}');
      print('🔍 GoogleSignIn instance: $_googleSignIn');
      
      // Check if we're on iOS and if so, check current status
      if (Platform.isIOS) {
        try {
          print('🔍 Checking if user is already signed in...');
          final currentUser = await _googleSignIn.signInSilently();
          if (currentUser != null) {
            print('🔍 User already signed in, signing out first...');
            await _googleSignIn.signOut();
          }
        } catch (e) {
          print('🔍 Silent sign-in check error (can be ignored): $e');
        }
      }
      
      // Sign in with Google
      print('🔄 Calling _googleSignIn.signIn()...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn().catchError((error) {
        print('❌ Google Sign-In error: $error');
        print('❌ Error type: ${error.runtimeType}');
        print('❌ Stack trace: ${StackTrace.current}');
        return null;
      });
      if (googleUser == null) {
        print('❌ Google Sign-In cancelled by user');
        return null;
      }
      
      print('✅ Google Sign-In successful: ${googleUser.email}');
      
      // Get Google authentication
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.idToken == null) {
        print('❌ Failed to get Google ID token');
        return null;
      }
      
      print('✅ Google ID token obtained, authenticating with Supabase...');
      
            // Sign in with Supabase - try bypassing nonce validation entirely
      print('🔍 Attempting Supabase authentication...');
      
      try {
        // First attempt: Standard Supabase auth
        final response = await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: googleAuth.idToken!,
          accessToken: googleAuth.accessToken,
        );
        
        if (response.user != null) {
          print('✅ Standard Supabase auth successful: ${response.user!.email}');
          return response;
        }
      } catch (e) {
        print('❌ Standard Supabase auth failed: $e');
        
        // For iOS nonce issues, try creating session directly with access token
        if (Platform.isIOS && e.toString().contains('nonce')) {
          print('🔍 iOS nonce issue detected, trying direct session creation...');
          try {
            // Use access token to create session directly
            final session = await _supabase.auth.setSession(googleAuth.accessToken!);
            
            if (session.user != null) {
              print('✅ Direct session creation successful: ${session.user!.email}');
              return session;
            }
          } catch (e2) {
            print('❌ Direct session creation failed: $e2');
          }
        }
        
        // If all else fails, throw the original error
        throw e;
      }
      
      print('❌ Supabase authentication failed');
      return null;
      
    } catch (e) {
      print('❌ Google Sign-In with Supabase failed: $e');
      return null;
    }
  }
  
  /// Sign in with email and password
  Future<AuthResponse?> signInWithEmailAndPassword(String email, String password) async {
    try {
      print('🔄 Supabase email/password sign-in for: $email');
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        print('✅ Supabase email/password sign-in successful: ${response.user?.id}');
        return response;
      } else {
        print('❌ Supabase email/password sign-in failed');
        return null;
      }
    } on AuthException catch (e) {
      print('❌ Supabase email/password sign-in failed: ${e.message}');
      return null;
    } catch (e) {
      print('❌ Unexpected error during Supabase email/password sign-in: $e');
      return null;
    }
  }
  
  /// Create account with email and password
  Future<AuthResponse?> createAccountWithEmailAndPassword(String email, String password) async {
    try {
      print('🔄 Creating Supabase account for: $email');
      
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        print('✅ Supabase account created successfully: ${response.user?.id}');
        return response;
      } else {
        print('❌ Supabase account creation failed');
        return null;
      }
    } on AuthException catch (e) {
      print('❌ Supabase account creation failed: ${e.message}');
      return null;
    } catch (e) {
      print('❌ Unexpected error during Supabase account creation: $e');
      return null;
    }
  }
  
  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      print('🔄 Sending Supabase password reset email to: $email');
      
      await _supabase.auth.resetPasswordForEmail(email);
      
      print('✅ Supabase password reset email sent successfully');
    } on AuthException catch (e) {
      print('❌ Failed to send Supabase password reset email: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Unexpected error sending Supabase password reset email: $e');
      rethrow;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      print('🔄 Signing out from Supabase...');
      
      // Sign out from Google and Supabase in parallel
      await Future.wait([
        _googleSignIn.signOut(),
        _supabase.auth.signOut(),
      ]);
      
      print('✅ Successfully signed out from Supabase');
    } catch (e) {
      print('❌ Error during Supabase sign-out: $e');
      rethrow;
    }
  }
  
  /// Delete user account and all associated data
  /// This will sign out the user from ALL devices
  Future<void> deleteAccount() async {
    try {
      print('🔄 Starting account deletion process...');
      
      final user = currentUser;
      if (user == null) {
        throw Exception('No user to delete');
      }
      
      final userId = user.id;
      print('🔄 Deleting account for user: $userId');
      
      // Step 1: Delete the user account (this will try to invalidate sessions in SQL)
      print('🔄 Step 1: Deleting user account and data...');
      final response = await _supabase.rpc('delete_user');
      
      print('🔍 Delete response: $response');
      
      // Check if deletion was successful
      if (response == null || response['success'] != true) {
        throw Exception('Failed to delete user account: ${response?['message'] ?? 'Unknown error'}');
      }
      
      print('✅ User account deleted from Supabase');
      print('✅ ${response['subscriptions_deleted']} subscriptions deleted');
      
      // Step 2: Attempt global sign-out to invalidate remaining sessions on other devices
      // Even though the account is deleted, this may help invalidate any cached tokens
      print('🔄 Step 2: Attempting global sign-out to invalidate any remaining sessions...');
      try {
        await _supabase.auth.signOut(scope: SignOutScope.global);
        print('✅ Global sign-out completed - should invalidate sessions on other devices');
      } catch (e) {
        print('⚠️ Global sign-out failed (expected after account deletion): $e');
        print('ℹ️ Account deletion should have invalidated sessions already');
      }
      
      // Step 3: Local cleanup
      print('🔄 Step 3: Performing local cleanup...');
      
      // Sign out from Google
      try {
        await _googleSignIn.signOut();
        print('✅ Google sign-out completed');
      } catch (e) {
        print('⚠️ Google sign out warning: $e');
      }
      
      // Ensure local Supabase session is cleared
      try {
        await _supabase.auth.signOut(scope: SignOutScope.local);
        print('✅ Local Supabase session cleared');
      } catch (e) {
        print('⚠️ Local sign-out warning (expected after account deletion): $e');
      }
      
      print('✅ Account deletion process completed successfully');
      print('ℹ️ Note: Other devices may remain signed in until their tokens expire');
      print('ℹ️ Users should manually sign out from other devices if needed');
      
    } catch (e) {
      print('❌ Error during account deletion: $e');
      rethrow;
    }
  }
  
  /// Get user profile information
  Map<String, dynamic>? get userProfile {
    final user = currentUser;
    if (user == null) return null;
    
    return {
      'id': user.id,
      'email': user.email,
      'name': user.userMetadata?['full_name'] ?? user.userMetadata?['name'],
      'avatar_url': user.userMetadata?['avatar_url'],
      'provider': user.appMetadata['provider'],
      'created_at': user.createdAt,
    };
  }
} 