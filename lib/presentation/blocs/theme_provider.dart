import 'package:flutter/material.dart';
import 'package:subtrackr/core/theme/app_theme.dart';
import 'package:subtrackr/data/services/settings_service.dart';

class ThemeProvider extends ChangeNotifier {
  final SettingsService _settingsService;
  late ThemeMode _themeMode;
  
  ThemeProvider({
    required SettingsService settingsService,
  }) : _settingsService = settingsService {
    _themeMode = _settingsService.getThemeMode();
  }
  
  // Get the current theme mode
  ThemeMode get themeMode => _themeMode;
  
  // Get the current theme data
  ThemeData get themeData {
    switch (_themeMode) {
      case ThemeMode.light:
        return AppTheme.lightTheme;
      case ThemeMode.dark:
        return AppTheme.darkTheme;
      case ThemeMode.system:
        final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        return brightness == Brightness.dark ? AppTheme.darkTheme : AppTheme.lightTheme;
    }
  }
  
  // Check if dark mode is enabled
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
  
  // Set the theme mode
  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (_themeMode == themeMode) return;
    
    _themeMode = themeMode;
    await _settingsService.setThemeMode(themeMode);
    notifyListeners();
  }
  
  // Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newThemeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newThemeMode);
  }
} 