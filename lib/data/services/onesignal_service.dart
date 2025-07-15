import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Service for handling promotional push notifications via OneSignal
/// Separate from local notifications (subscription reminders)
class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  
  factory OneSignalService() {
    return _instance;
  }
  
  OneSignalService._internal();

  /// Initialize OneSignal with your app ID
  /// Get your app ID from: https://app.onesignal.com/
  static Future<void> initialize({required String appId}) async {
    try {
      // Debug mode for development
      if (kDebugMode) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      }

      // Initialize OneSignal (without requesting permission yet)
      OneSignal.initialize(appId);

      // Setup notification event handlers
      _setupNotificationHandlers();

      debugPrint('🔔 OneSignal initialized successfully');
    } catch (e) {
      debugPrint('❌ OneSignal initialization failed: $e');
    }
  }

  /// Setup notification event handlers
  static void _setupNotificationHandlers() {
    // When app is in foreground and notification is received
    OneSignal.Notifications.addForegroundWillDisplayListener((OSNotificationWillDisplayEvent event) {
      debugPrint('🔔 Notification received in foreground: ${event.notification.title}');
      // Show notification as dropdown even when app is in foreground
      // Don't prevent - let OneSignal handle the system notification
      event.notification.display();
    });

    // When user taps on notification
    OneSignal.Notifications.addClickListener((OSNotificationClickEvent event) {
      debugPrint('🔔 Notification clicked: ${event.notification.title}');
      // Handle notification tap - navigate to specific screen, etc.
      _handleNotificationTap(event.notification);
    });

    // When user permission changes
    OneSignal.Notifications.addPermissionObserver((bool state) {
      debugPrint('🔔 Notification permission changed: $state');
    });
  }

  /// Handle notification tap actions
  static void _handleNotificationTap(OSNotification notification) {
    final data = notification.additionalData;
    
    if (data != null) {
      // Handle different notification types
      final action = data['action'] as String?;
      
      switch (action) {
        case 'open_app':
          // Just open the app (default behavior)
          break;
        case 'open_settings':
          // Navigate to settings
          // NavigatorService.navigateTo('/settings');
          break;
        case 'open_statistics':
          // Navigate to statistics
          // NavigatorService.navigateTo('/statistics');
          break;
        case 'open_url':
          final url = data['url'] as String?;
          if (url != null) {
            // Open external URL
            // UrlLauncher.launch(url);
          }
          break;
        default:
          debugPrint('🔔 Unknown notification action: $action');
      }
    }
  }

  /// Get the user's OneSignal Player ID (for targeting specific users)
  static Future<String?> getUserId() async {
    try {
      final id = OneSignal.User.pushSubscription.id;
      debugPrint('🔔 OneSignal User ID: $id');
      return id;
    } catch (e) {
      debugPrint('❌ Failed to get OneSignal User ID: $e');
      return null;
    }
  }

  /// Set user tags for segmentation
  static Future<void> setUserTags(Map<String, String> tags) async {
    try {
      OneSignal.User.addTags(tags);
      debugPrint('🔔 OneSignal tags set: $tags');
    } catch (e) {
      debugPrint('❌ Failed to set OneSignal tags: $e');
    }
  }

  /// Set user properties for better targeting
  static Future<void> setUserProperties({
    String? email,
    String? userId,
    int? subscriptionCount,
    double? monthlySpending,
    String? preferredCurrency,
  }) async {
    final tags = <String, String>{};
    
    if (email != null) tags['email'] = email;
    if (userId != null) tags['user_id'] = userId;
    if (subscriptionCount != null) tags['subscription_count'] = subscriptionCount.toString();
    if (monthlySpending != null) tags['monthly_spending'] = monthlySpending.toString();
    if (preferredCurrency != null) tags['preferred_currency'] = preferredCurrency;
    
    if (tags.isNotEmpty) {
      await setUserTags(tags);
    }
  }

  /// Check if user has granted notification permission
  static Future<bool> hasPermission() async {
    try {
      final permission = await OneSignal.Notifications.permission;
      return permission;
    } catch (e) {
      debugPrint('❌ Failed to check OneSignal permission: $e');
      return false;
    }
  }

  /// Request notification permission
  static Future<bool> requestPermission() async {
    try {
      final granted = await OneSignal.Notifications.requestPermission(true);
      debugPrint('🔔 OneSignal permission granted: $granted');
      return granted;
    } catch (e) {
      debugPrint('❌ Failed to request OneSignal permission: $e');
      return false;
    }
  }

  /// Log out user (clear user data)
  static Future<void> logout() async {
    try {
      OneSignal.logout();
      debugPrint('🔔 OneSignal user logged out');
    } catch (e) {
      debugPrint('❌ Failed to logout OneSignal user: $e');
    }
  }

  /// Test method - send a test notification to this device
  static Future<void> sendTestNotification() async {
    final userId = await getUserId();
    if (userId != null) {
      debugPrint('🧪 Test notification - User ID: $userId');
      debugPrint('💡 Use this ID in OneSignal dashboard to send test notifications');
    }
  }

  /// Send a test notification to the current device using OneSignal REST API
  static Future<bool> sendActualTestNotification() async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        debugPrint('❌ No OneSignal User ID available');
        return false;
      }

      // OneSignal REST API to send notification
      const appId = '16a85cc9-6fb3-4990-a922-479d2ad77ea1';
      // NOTE: In production, the REST API key should be stored securely on your backend
      // For testing purposes, we'll use a simplified approach
      
      debugPrint('🔔 Sending test notification to Player ID: $userId');
      
      // For security reasons, we can't include the REST API key in the client app
      // Instead, show instructions for manual testing
      debugPrint('💡 To send a test notification:');
      debugPrint('💡 1. Go to https://app.onesignal.com/');
      debugPrint('💡 2. Navigate to your app > Messages > New Push');
      debugPrint('💡 3. Select "Particular Users" and enter Player ID: $userId');
      debugPrint('💡 4. Create and send your test message');
      
      return true;
    } catch (e) {
      debugPrint('❌ Failed to send test notification: $e');
      return false;
    }
  }
} 