import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:subtrackr/core/theme/app_theme.dart';
import 'package:subtrackr/data/services/settings_service.dart';

class ThemeProvider extends ChangeNotifier {
  final SettingsService _settingsService;
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeProvider({
    required SettingsService settingsService,
  }) : _settingsService = settingsService {
    // Initialize theme from saved settings
    loadTheme();
  }
  
  // Get the current theme mode
  ThemeMode get themeMode => _themeMode;
  
  // Get the current theme data
  ThemeData get themeData => _themeMode == ThemeMode.dark 
      ? AppTheme.darkTheme 
      : AppTheme.lightTheme;
  
  // Check if dark mode is enabled
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  // Initialize theme from saved settings
  Future<void> loadTheme() async {
    try {
      final savedThemeMode = _settingsService.getThemeMode();
      _themeMode = savedThemeMode;
      
      // Set initial status bar style based on theme mode
      _updateStatusBarStyle(_themeMode);
      
      notifyListeners();
    } catch (e) {
      // If there's any error, keep using the default theme mode
      debugPrint('Error loading theme settings: $e');
      _updateStatusBarStyle(_themeMode);
    }
  }
  
  // Helper method to update status bar style
  void _updateStatusBarStyle(ThemeMode mode) {
    final isDark = mode == ThemeMode.dark || 
      (mode == ThemeMode.system && 
       WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);
      
    if (isDark) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark, // iOS: light icons for dark background
        statusBarIconBrightness: Brightness.light, // Android: light icons for dark background
      ));
    } else {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light, // iOS: dark icons for light background
        statusBarIconBrightness: Brightness.dark, // Android: dark icons for light background
      ));
    }
  }

  // Set the theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _settingsService.setThemeMode(mode);
    
    // Update status bar style based on theme mode
    _updateStatusBarStyle(mode);
    
    notifyListeners();
  }
  
  // Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newThemeMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    await setThemeMode(newThemeMode);
  }
} 