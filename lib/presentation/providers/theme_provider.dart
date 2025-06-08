import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:subtrackr/core/theme/app_theme.dart';
import 'package:subtrackr/data/services/settings_service.dart';

class ThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  final SettingsService _settingsService;
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeProvider({
    required SettingsService settingsService,
  }) : _settingsService = settingsService {
    // Initialize theme from saved settings
    loadTheme();
    // Listen for system theme changes
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangePlatformBrightness() {
    // Update system UI overlay style when system brightness changes
    if (_themeMode == ThemeMode.system) {
      _updateStatusBarStyle(_themeMode);
    }
    super.didChangePlatformBrightness();
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
  
  // Helper method to update system UI overlay style
  void _updateStatusBarStyle(ThemeMode mode) {
    final isDark = mode == ThemeMode.dark || 
      (mode == ThemeMode.system && 
       WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);
      
    if (isDark) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark, // iOS: light icons for dark background
        statusBarIconBrightness: Brightness.light, // Android: light icons for dark background
        systemNavigationBarColor: AppTheme.darkTheme.scaffoldBackgroundColor, // Match dark theme background
        systemNavigationBarIconBrightness: Brightness.light, // Light icons for dark nav bar
        systemNavigationBarDividerColor: Colors.transparent,
      ));
    } else {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light, // iOS: dark icons for light background
        statusBarIconBrightness: Brightness.dark, // Android: dark icons for light background
        systemNavigationBarColor: AppTheme.lightTheme.scaffoldBackgroundColor, // Match light theme background
        systemNavigationBarIconBrightness: Brightness.dark, // Dark icons for light nav bar
        systemNavigationBarDividerColor: Colors.transparent,
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