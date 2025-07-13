import 'dart:async';
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
  
  /// Sign in with Google
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      print('🔄 Starting Google Sign-In with Supabase...');
      
      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
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
      
      // Sign in with Supabase using the Google ID token
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      
      if (response.user != null) {
        print('✅ Supabase authentication successful: ${response.user!.email}');
        return response;
      } else {
        print('❌ Supabase authentication failed');
        return null;
      }
      
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
      
      // Sign out from Google
      await _googleSignIn.signOut();
      
      // Sign out from Supabase
      await _supabase.auth.signOut();
      
      print('✅ Successfully signed out from Supabase');
    } catch (e) {
      print('❌ Error during Supabase sign-out: $e');
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