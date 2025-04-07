import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();
  
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  // Android notification channel
  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'Subscription Reminders',
    description: 'This channel is used for subscription renewal reminders',
    importance: Importance.high,
    enableVibration: true,
    enableLights: true,
    showBadge: true,
  );
  
  Future<void> init() async {
    // Initialize timezone
    tz_data.initializeTimeZones();
    
    // Initialize notification settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final DarwinInitializationSettings initializationSettingsIOS =
        const DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );
    
    // Create the Android notification channel
    if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }
  }
  
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final bool? result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
      
      // Request notification permission for Android 13+
      final bool? granted = await androidImplementation?.requestNotificationsPermission();
      debugPrint('Android notification permissions granted: $granted');
      
      return granted ?? false;
    }
    return false;
  }
  
  Future<bool> openAlarmPermissionSettings() async {
    if (Platform.isAndroid) {
      try {
        // For Android 12+, we need to open the system settings for the user to grant permission
        // This URI opens the app's settings page where the user can grant the SCHEDULE_EXACT_ALARM permission
        final Uri uri = Uri.parse('package:com.example.subtrackr');
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          return true;
        } else {
          // Fallback to opening the app settings
          final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
              _flutterLocalNotificationsPlugin
                  .resolvePlatformSpecificImplementation<
                      AndroidFlutterLocalNotificationsPlugin>();
          
          await androidImplementation?.createNotificationChannel(_channel);
          return false;
        }
      } catch (e) {
        debugPrint('Error opening alarm permission settings: $e');
        return false;
      }
    }
    return true; // iOS doesn't need this permission
  }
  
  Future<bool> canScheduleExactAlarms() async {
    if (Platform.isAndroid) {
      // We'll try to schedule with exact alarms and catch the exception if not permitted
      // This is a workaround since the method to check permission directly isn't available
      return true;
    }
    return true; // iOS doesn't need this permission
  }
  
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      debugPrint('Scheduling notification for: ${scheduledDate.toString()}');
      
      // Create notification details
      final androidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        fullScreenIntent: true,
      );

      final iosDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule the notification
      try {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(scheduledDate, tz.local),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
        );
        debugPrint('Notification scheduled successfully');
      } catch (e) {
        if (e is PlatformException && e.code == 'exact_alarms_not_permitted') {
          debugPrint('Exact alarms not permitted, requesting permission...');
          final permissionOpened = await openAlarmPermissionSettings();
          
          if (permissionOpened) {
            // Show a message to the user that they need to grant permission
            debugPrint('Opened settings for exact alarm permission');
            
            // Fall back to inexact alarms for now
            await _flutterLocalNotificationsPlugin.zonedSchedule(
              id,
              title,
              body,
              tz.TZDateTime.from(scheduledDate, tz.local),
              notificationDetails,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              payload: payload,
            );
            debugPrint('Notification scheduled with inexact timing (fallback)');
          } else {
            // Fall back to inexact alarms
            await _flutterLocalNotificationsPlugin.zonedSchedule(
              id,
              title,
              body,
              tz.TZDateTime.from(scheduledDate, tz.local),
              notificationDetails,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              payload: payload,
            );
            debugPrint('Notification scheduled with inexact timing (fallback)');
          }
        } else {
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
      rethrow;
    }
  }
  
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }
  
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
  
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }
  
  // For testing purposes
  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Subscription Reminders',
      channelDescription: 'This channel is used for subscription renewal reminders',
      importance: Importance.max,
      priority: Priority.high,
      // No action buttons
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Test Notification',
      'This is a test notification',
      notificationDetails,
    );
  }
} 