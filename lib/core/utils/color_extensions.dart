import 'dart:ui';

/// Extension on [Color] to provide modern alternatives to deprecated methods.
extension ColorExtensions on Color {
  /// Modern replacement for deprecated `withOpacity` method.
  /// Uses `withValues` to maintain precision.
  Color withOpacityValue(double opacity) {
    return withValues(alpha: opacity);
  }
} 