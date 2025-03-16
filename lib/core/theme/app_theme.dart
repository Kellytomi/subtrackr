import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern color scheme - Blue palette
  static const Color _primaryColorLight = Color(0xFF2196F3); // Blue
  static const Color _primaryColorDark = Color(0xFF42A5F5);  // Lighter blue
  
  static const Color _secondaryColorLight = Color(0xFF03DAC6); // Teal
  static const Color _secondaryColorDark = Color(0xFF4ECDC4);  // Mint
  
  static const Color _tertiaryColorLight = Color(0xFFFF9800); // Orange
  static const Color _tertiaryColorDark = Color(0xFFFFAB40);  // Light orange
  
  static const Color _errorColorLight = Color(0xFFFF3B30); // iOS red
  static const Color _errorColorDark = Color(0xFFFF6B6B);  // Soft red
  
  static const Color _backgroundColorLight = Color(0xFFF8F9FA); // Light gray
  static const Color _backgroundColorDark = Color(0xFF121212);  // Dark gray
  
  static const Color _surfaceColorLight = Colors.white;
  static const Color _surfaceColorDark = Color(0xFF1E1E1E);
  
  static const Color _onPrimaryLight = Colors.white;
  static const Color _onPrimaryDark = Colors.white;
  
  static const Color _onSecondaryLight = Colors.black;
  static const Color _onSecondaryDark = Colors.black;
  
  static const Color _onBackgroundLight = Colors.black;
  static const Color _onBackgroundDark = Colors.white;
  
  static const Color _onSurfaceLight = Colors.black;
  static const Color _onSurfaceDark = Colors.white;
  
  // Custom colors for our app
  static const Color _subscriptionCardLight = Color(0xFFE3F2FD); // Light blue
  static const Color _subscriptionCardDark = Color(0xFF0D47A1);  // Deep blue
  
  static const Color _activeSubscriptionLight = Color(0xFF34C759); // iOS green
  static const Color _activeSubscriptionDark = Color(0xFF4CD964);  // Bright green
  
  static const Color _pausedSubscriptionLight = Color(0xFFFF9500); // iOS orange
  static const Color _pausedSubscriptionDark = Color(0xFFFFCC00);  // iOS yellow
  
  static const Color _cancelledSubscriptionLight = Color(0xFFFF3B30); // iOS red
  static const Color _cancelledSubscriptionDark = Color(0xFFFF6B6B);  // Soft red

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: _primaryColorLight,
      secondary: _secondaryColorLight,
      tertiary: _tertiaryColorLight,
      error: _errorColorLight,
      background: _backgroundColorLight,
      surface: _surfaceColorLight,
      onPrimary: _onPrimaryLight,
      onSecondary: _onSecondaryLight,
      onBackground: _onBackgroundLight,
      onSurface: _onSurfaceLight,
      outline: Colors.grey.shade300,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryColorLight,
      foregroundColor: _onPrimaryLight,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryColorLight,
      foregroundColor: _onPrimaryLight,
    ),
    cardTheme: const CardTheme(
      color: _surfaceColorLight,
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: _onPrimaryLight,
        backgroundColor: _primaryColorLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColorLight,
        side: const BorderSide(color: _primaryColorLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColorLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryColorLight, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _errorColorLight),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _errorColorLight, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    extensions: [
      CustomColorsExtension(
        subscriptionCard: _subscriptionCardLight,
        activeSubscription: _activeSubscriptionLight,
        pausedSubscription: _pausedSubscriptionLight,
        cancelledSubscription: _cancelledSubscriptionLight,
      ),
    ],
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: _primaryColorDark,
      secondary: _secondaryColorDark,
      tertiary: _tertiaryColorDark,
      error: _errorColorDark,
      background: _backgroundColorDark,
      surface: _surfaceColorDark,
      onPrimary: _onPrimaryDark,
      onSecondary: _onSecondaryDark,
      onBackground: _onBackgroundDark,
      onSurface: _onSurfaceDark,
      outline: Colors.grey.shade700,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: _backgroundColorDark,
      foregroundColor: _onBackgroundDark,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryColorDark,
      foregroundColor: _onPrimaryDark,
    ),
    cardTheme: const CardTheme(
      color: _surfaceColorDark,
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: _onPrimaryDark,
        backgroundColor: _primaryColorDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColorDark,
        side: const BorderSide(color: _primaryColorDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColorDark,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryColorDark, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _errorColorDark),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _errorColorDark, width: 2),
      ),
      filled: true,
      fillColor: _surfaceColorDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    extensions: [
      CustomColorsExtension(
        subscriptionCard: _subscriptionCardDark,
        activeSubscription: _activeSubscriptionDark,
        pausedSubscription: _pausedSubscriptionDark,
        cancelledSubscription: _cancelledSubscriptionDark,
      ),
    ],
  );
}

// Custom colors extension to access our custom colors from the theme
class CustomColorsExtension extends ThemeExtension<CustomColorsExtension> {
  final Color subscriptionCard;
  final Color activeSubscription;
  final Color pausedSubscription;
  final Color cancelledSubscription;

  CustomColorsExtension({
    required this.subscriptionCard,
    required this.activeSubscription,
    required this.pausedSubscription,
    required this.cancelledSubscription,
  });

  @override
  ThemeExtension<CustomColorsExtension> copyWith({
    Color? subscriptionCard,
    Color? activeSubscription,
    Color? pausedSubscription,
    Color? cancelledSubscription,
  }) {
    return CustomColorsExtension(
      subscriptionCard: subscriptionCard ?? this.subscriptionCard,
      activeSubscription: activeSubscription ?? this.activeSubscription,
      pausedSubscription: pausedSubscription ?? this.pausedSubscription,
      cancelledSubscription: cancelledSubscription ?? this.cancelledSubscription,
    );
  }

  @override
  ThemeExtension<CustomColorsExtension> lerp(
    covariant ThemeExtension<CustomColorsExtension>? other,
    double t,
  ) {
    if (other is! CustomColorsExtension) {
      return this;
    }

    return CustomColorsExtension(
      subscriptionCard: Color.lerp(subscriptionCard, other.subscriptionCard, t)!,
      activeSubscription: Color.lerp(activeSubscription, other.activeSubscription, t)!,
      pausedSubscription: Color.lerp(pausedSubscription, other.pausedSubscription, t)!,
      cancelledSubscription: Color.lerp(cancelledSubscription, other.cancelledSubscription, t)!,
    );
  }
}

// Extension method to easily access custom colors from the theme
extension CustomColorsExtensionX on ThemeData {
  CustomColorsExtension get customColors => extension<CustomColorsExtension>()!;
} 