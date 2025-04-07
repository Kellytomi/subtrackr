import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/core/utils/currency_utils.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  
  factory SettingsService() {
    return _instance;
  }
  
  SettingsService._internal();
  
  late Box<dynamic> _settingsBox;
  
  // Initialize the settings service
  Future<void> init() async {
    _settingsBox = await Hive.openBox(AppConstants.settingsBox);
    
    // Set default values if not already set
    if (!_settingsBox.containsKey(AppConstants.themeModeSetting)) {
      await _settingsBox.put(AppConstants.themeModeSetting, ThemeMode.system.index);
    }
    
    if (!_settingsBox.containsKey(AppConstants.notificationsEnabledSetting)) {
      await _settingsBox.put(AppConstants.notificationsEnabledSetting, true);
    }
    
    if (!_settingsBox.containsKey(AppConstants.notificationTimeSetting)) {
      // Default notification time: 9:00 AM
      await _settingsBox.put(AppConstants.notificationTimeSetting, const TimeOfDay(hour: 9, minute: 0).toString());
    }
    
    if (!_settingsBox.containsKey(AppConstants.currencySymbolSetting)) {
      await _settingsBox.put(AppConstants.currencySymbolSetting, AppConstants.defaultCurrencySymbol);
    }
    
    if (!_settingsBox.containsKey(AppConstants.currencyCodeSetting)) {
      await _settingsBox.put(AppConstants.currencyCodeSetting, AppConstants.defaultCurrencyCode);
    }
  }
  
  // Get the current theme mode
  ThemeMode getThemeMode() {
    final themeModeIndex = _settingsBox.get(AppConstants.themeModeSetting, defaultValue: ThemeMode.system.index);
    return ThemeMode.values[themeModeIndex];
  }
  
  // Set the theme mode
  Future<void> setThemeMode(ThemeMode themeMode) async {
    await _settingsBox.put(AppConstants.themeModeSetting, themeMode.index);
  }
  
  // Check if notifications are enabled
  bool areNotificationsEnabled() {
    return _settingsBox.get(AppConstants.notificationsEnabledSetting, defaultValue: true);
  }
  
  // Enable or disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _settingsBox.put(AppConstants.notificationsEnabledSetting, enabled);
  }
  
  // Get the notification time
  TimeOfDay getNotificationTime() {
    // Try to get from separate hour and minute fields first (new format)
    final hour = _settingsBox.get(AppConstants.notificationTimeSetting + '_hour');
    final minute = _settingsBox.get(AppConstants.notificationTimeSetting + '_minute');
    
    if (hour != null && minute != null) {
      return TimeOfDay(hour: hour, minute: minute);
    }
    
    // Fall back to old format if separate fields don't exist
    final timeString = _settingsBox.get(
      AppConstants.notificationTimeSetting,
      defaultValue: const TimeOfDay(hour: 9, minute: 0).toString(),
    );
    
    // Parse the time string (format: "TimeOfDay(hour: 9, minute: 0)")
    final hourRegex = RegExp(r'hour: (\d+)');
    final minuteRegex = RegExp(r'minute: (\d+)');
    
    final hourMatch = hourRegex.firstMatch(timeString);
    final minuteMatch = minuteRegex.firstMatch(timeString);
    
    final parsedHour = hourMatch != null ? int.parse(hourMatch.group(1)!) : 9;
    final parsedMinute = minuteMatch != null ? int.parse(minuteMatch.group(1)!) : 0;
    
    return TimeOfDay(hour: parsedHour, minute: parsedMinute);
  }
  
  // Set the notification time
  Future<void> setNotificationTime(TimeOfDay time) async {
    await _settingsBox.put(AppConstants.notificationTimeSetting + '_hour', time.hour);
    await _settingsBox.put(AppConstants.notificationTimeSetting + '_minute', time.minute);
    await _settingsBox.put(AppConstants.notificationTimeSetting, time.toString());
  }
  
  // Get the currency symbol
  String getCurrencySymbol() {
    return _settingsBox.get(
      AppConstants.currencySymbolSetting,
      defaultValue: AppConstants.defaultCurrencySymbol,
    );
  }
  
  // Set the currency symbol
  Future<void> setCurrencySymbol(String symbol) async {
    await _settingsBox.put(AppConstants.currencySymbolSetting, symbol);
  }
  
  // Get the currency code
  String? getCurrencyCode() {
    return _settingsBox.get(
      AppConstants.currencyCodeSetting,
      defaultValue: AppConstants.defaultCurrencyCode,
    );
  }
  
  // Set the currency code
  Future<void> setCurrencyCode(String code) async {
    await _settingsBox.put(AppConstants.currencyCodeSetting, code);
    
    // Also update the symbol for backward compatibility
    final currency = CurrencyUtils.getCurrencyByCode(code);
    if (currency != null) {
      await setCurrencySymbol(currency.symbol);
    }
  }
  
  // Check if onboarding is complete
  bool isOnboardingComplete() {
    return _settingsBox.get(AppConstants.onboardingCompleteSetting, defaultValue: false);
  }
  
  // Set onboarding complete
  Future<void> setOnboardingComplete(bool complete) async {
    await _settingsBox.put(AppConstants.onboardingCompleteSetting, complete);
  }
  
  // Close the box
  Future<void> close() async {
    await _settingsBox.close();
  }
} 