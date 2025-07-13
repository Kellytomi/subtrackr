import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration and initialization
class SupabaseConfig {
  // Supabase project credentials
  static const String supabaseUrl = 'https://gjrksrgifgkcumcypvdo.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdqcmtzcmdpZmdrY3VtY3lwdmRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE1ODM2MTEsImV4cCI6MjA2NzE1OTYxMX0.3-rBAa4GQJnZEUzzU-FiIZqTnBSjd9iBXd8SB7O0vls';
  
  /// Initialize Supabase client
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: true, // Enable debug mode for development
      );
      print('✅ Supabase initialized successfully');
    } catch (e) {
      print('❌ Supabase initialization failed: $e');
      // Continue without Supabase - app should still work locally
    }
  }
  
  /// Get Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;
  
  /// Check if Supabase is available
  static bool get isAvailable {
    try {
      return Supabase.instance.client.auth.currentUser != null || 
             supabaseUrl.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Database table names
  static const String subscriptionsTable = 'subscriptions';
  static const String priceChangesTable = 'price_changes';
} 