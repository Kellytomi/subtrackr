import 'package:flutter/material.dart';
import 'package:subtrackr/core/theme/app_theme.dart';
import 'package:subtrackr/data/services/settings_service.dart';

class ThemeProvider extends ChangeNotifier {
  final SettingsService _settingsService;
  
  ThemeProvider({
    required SettingsService settingsService,
  }) : _settingsService = settingsService {
    // Always set to light mode
    _settingsService.setThemeMode(ThemeMode.light);
  }
  
  // Get the current theme mode - always light
  ThemeMode get themeMode => ThemeMode.light;
  
  // Get the current theme data - always light theme
  ThemeData get themeData => AppTheme.lightTheme;
  
  // Check if dark mode is enabled - always false
  bool get isDarkMode => false;
  
  // Set the theme mode - only allows light mode
  Future<void> setThemeMode(ThemeMode themeMode) async {
    // Only allow light mode
    await _settingsService.setThemeMode(ThemeMode.light);
    notifyListeners();
  }
  
  // Toggle between light and dark mode - does nothing now
  Future<void> toggleTheme() async {
    // Do nothing, we only support light mode
    notifyListeners();
  }
} 