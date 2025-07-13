import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/core/utils/currency_utils.dart';

/// Service class for managing application settings using Hive storage.
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  
  factory SettingsService() {
    return _instance;
  }
  
  SettingsService._internal();
  
  late Box<dynamic> _settingsBox;
  
  /// Initialize the settings service
  Future<void> init() async {
    _settingsBox = await Hive.openBox(AppConstants.SETTINGS_BOX);
    
    // Set default values if not already set
    if (!_settingsBox.containsKey(AppConstants.THEME_MODE_SETTING)) {
      await _settingsBox.put(AppConstants.THEME_MODE_SETTING, ThemeMode.system.index);
    }
    
    if (!_settingsBox.containsKey(AppConstants.NOTIFICATIONS_ENABLED_SETTING)) {
      await _settingsBox.put(AppConstants.NOTIFICATIONS_ENABLED_SETTING, true);
    }
    
    if (!_settingsBox.containsKey(AppConstants.NOTIFICATION_TIME_SETTING)) {
      // Default notification time: 9:00 AM
      await _settingsBox.put(AppConstants.NOTIFICATION_TIME_SETTING, const TimeOfDay(hour: 9, minute: 0).toString());
    }
    
    if (!_settingsBox.containsKey(AppConstants.CURRENCY_SYMBOL_SETTING)) {
      await _settingsBox.put(AppConstants.CURRENCY_SYMBOL_SETTING, AppConstants.DEFAULT_CURRENCY_SYMBOL);
    }
    
    if (!_settingsBox.containsKey(AppConstants.CURRENCY_CODE_SETTING)) {
      await _settingsBox.put(AppConstants.CURRENCY_CODE_SETTING, AppConstants.DEFAULT_CURRENCY_CODE);
    }
    
    if (!_settingsBox.containsKey(AppConstants.SUBSCRIPTION_SORT_SETTING)) {
      await _settingsBox.put(AppConstants.SUBSCRIPTION_SORT_SETTING, AppConstants.DEFAULT_SORT_OPTION);
    }
    
    if (!_settingsBox.containsKey(AppConstants.AUTO_SYNC_SETTING)) {
      await _settingsBox.put(AppConstants.AUTO_SYNC_SETTING, true);
    }
  }
  
  /// Get the current theme mode
  ThemeMode getThemeMode() {
    try {
      final value = _settingsBox.get(AppConstants.THEME_MODE_SETTING);
      if (value is int && value >= 0 && value < ThemeMode.values.length) {
        return ThemeMode.values[value];
      }
    } catch (e) {
      debugPrint('Error getting theme mode: $e');
    }
    // Default to system theme if anything goes wrong
    return ThemeMode.system;
  }
  
  /// Set the theme mode
  Future<void> setThemeMode(ThemeMode themeMode) async {
    await _settingsBox.put(AppConstants.THEME_MODE_SETTING, themeMode.index);
  }
  
  /// Check if notifications are enabled
  bool areNotificationsEnabled() {
    final value = _settingsBox.get(AppConstants.NOTIFICATIONS_ENABLED_SETTING);
    return value is bool ? value : true;
  }
  
  /// Enable or disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _settingsBox.put(AppConstants.NOTIFICATIONS_ENABLED_SETTING, enabled);
  }
  
  /// Get the notification time
  TimeOfDay getNotificationTime() {
    // Try to get from separate hour and minute fields first (new format)
    final hourValue = _settingsBox.get('${AppConstants.NOTIFICATION_TIME_SETTING}_hour');
    final minuteValue = _settingsBox.get('${AppConstants.NOTIFICATION_TIME_SETTING}_minute');
    
    if (hourValue is int && minuteValue is int) {
      return TimeOfDay(hour: hourValue, minute: minuteValue);
    }
    
    // Fall back to old format if separate fields don't exist
    final timeString = _settingsBox.get(
      AppConstants.NOTIFICATION_TIME_SETTING,
    );
    
    if (timeString is String) {
      // Parse the time string (format: "TimeOfDay(hour: 9, minute: 0)")
      final hourRegex = RegExp(r'hour: (\d+)');
      final minuteRegex = RegExp(r'minute: (\d+)');
      
      final hourMatch = hourRegex.firstMatch(timeString);
      final minuteMatch = minuteRegex.firstMatch(timeString);
      
      if (hourMatch != null && minuteMatch != null) {
        final parsedHour = int.tryParse(hourMatch.group(1)!) ?? 9;
        final parsedMinute = int.tryParse(minuteMatch.group(1)!) ?? 0;
        return TimeOfDay(hour: parsedHour, minute: parsedMinute);
      }
    }
    
    // Default fallback
    return const TimeOfDay(hour: 9, minute: 0);
  }
  
  /// Set the notification time
  Future<void> setNotificationTime(TimeOfDay time) async {
    await _settingsBox.put('${AppConstants.NOTIFICATION_TIME_SETTING}_hour', time.hour);
    await _settingsBox.put('${AppConstants.NOTIFICATION_TIME_SETTING}_minute', time.minute);
    await _settingsBox.put(AppConstants.NOTIFICATION_TIME_SETTING, time.toString());
  }
  
  /// Get the currency symbol
  String getCurrencySymbol() {
    final value = _settingsBox.get(AppConstants.CURRENCY_SYMBOL_SETTING);
    return value is String ? value : AppConstants.DEFAULT_CURRENCY_SYMBOL;
  }
  
  /// Set the currency symbol
  Future<void> setCurrencySymbol(String symbol) async {
    await _settingsBox.put(AppConstants.CURRENCY_SYMBOL_SETTING, symbol);
  }
  
  /// Get the currency code
  String? getCurrencyCode() {
    final value = _settingsBox.get(AppConstants.CURRENCY_CODE_SETTING);
    return value is String ? value : AppConstants.DEFAULT_CURRENCY_CODE;
  }
  
  /// Set the currency code
  Future<void> setCurrencyCode(String code) async {
    await _settingsBox.put(AppConstants.CURRENCY_CODE_SETTING, code);
    
    // Also update the symbol for backward compatibility
    final currency = CurrencyUtils.getCurrencyByCode(code);
    if (currency != null) {
      await setCurrencySymbol(currency.symbol);
    }
  }
  
  /// Check if onboarding is complete
  bool isOnboardingComplete() {
    final value = _settingsBox.get(AppConstants.ONBOARDING_COMPLETE_SETTING);
    return value is bool ? value : false;
  }
  
  /// Set onboarding complete
  Future<void> setOnboardingComplete(bool complete) async {
    await _settingsBox.put(AppConstants.ONBOARDING_COMPLETE_SETTING, complete);
  }
  
  /// Get the subscription sorting preference
  String getSubscriptionSort() {
    final value = _settingsBox.get(AppConstants.SUBSCRIPTION_SORT_SETTING);
    return value is String ? value : AppConstants.DEFAULT_SORT_OPTION;
  }
  
  /// Set the subscription sorting preference
  Future<void> setSubscriptionSort(String sortOption) async {
    await _settingsBox.put(AppConstants.SUBSCRIPTION_SORT_SETTING, sortOption);
  }
  
  /// Check if auto sync is enabled
  bool isAutoSyncEnabled() {
    final value = _settingsBox.get(AppConstants.AUTO_SYNC_SETTING);
    return value is bool ? value : true;
  }
  
  /// Enable or disable auto sync
  Future<void> setAutoSyncEnabled(bool enabled) async {
    await _settingsBox.put(AppConstants.AUTO_SYNC_SETTING, enabled);
  }
  
  /// Get the last signed-in user ID (for user privacy protection)
  String? getLastUserId() {
    final value = _settingsBox.get('last_user_id');
    return value is String ? value : null;
  }
  
  /// Set the last signed-in user ID (for user privacy protection)
  Future<void> setLastUserId(String userId) async {
    await _settingsBox.put('last_user_id', userId);
  }

  /// Close the box
  Future<void> close() async {
    await _settingsBox.close();
  }
} 