import '../../data/services/settings_service.dart';

/// AI Service Configuration
class AiConfig {
  static const String claudeApiKey = String.fromEnvironment(
    'CLAUDE_API_KEY',
    defaultValue: '',
  );
  
  static const String claudeApiBaseUrl = 'https://api.anthropic.com/v1/messages';
  static const String claudeModel = 'claude-3-haiku-20240307';
  
  /// Maximum tokens for AI analysis
  static const int maxTokens = 1000;
  
  /// Confidence threshold for AI subscription detection (0.0 - 1.0)
  static const double confidenceThreshold = 0.8;
  
  // NEW: AI-First Mode Configuration
  
  /// Enable AI-first mode (minimal pre-filtering) - dynamic from settings
  static bool aiFirstMode(SettingsService? settingsService) {
    // For now, return true as default - can be enhanced later
    return true;
  }
  
  /// In AI-first mode, only exclude these obvious non-subscription patterns
  static const List<String> minimalExcludePatterns = [
    'unsubscribe successful',
    'account suspended',
    'password reset',
    'login verification',
    'security code',
    'two-factor',
    '2fa code',
    'github.com/notifications', // GitHub notifications
  ];
  
  /// Smart AI analysis - let AI decide with minimal human bias
  static const bool smartAiAnalysis = true;
  
  /// Whether AI-powered email analysis is enabled (dynamic from settings)
  static bool aiAnalysisEnabled(SettingsService? settingsService) {
    // For now, return true as default - can be enhanced later
    return true;
  }
} 