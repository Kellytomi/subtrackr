import 'package:shared_preferences/shared_preferences.dart';

/// Helper utility for managing and displaying first-time user tips
class TipsHelper {
  static const String _tipsShownKey = 'tips_shown';
  static const String _homeScreenTipKey = 'home_screen_tip';
  static const String _quickActionsKey = 'quick_actions_tip';
  static const String _addButtonKey = 'add_button_tip';
  static const String _historyTipKey = 'history_tip';
  static const String _statisticsTipKey = 'statistics_tip';
  static const String _priceChangeKey = 'price_change_tip';
  static const String _menuActionsKey = 'menu_actions_tip';
  static const String _priceHistoryKey = 'price_history_tip';
  static const String _mainAppTutorialKey = 'main_app_tutorial';
  
  /// Check if all tips have been shown
  static Future<bool> allTipsShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tipsShownKey) ?? false;
  }
  
  /// Mark all tips as shown
  static Future<void> markAllTipsAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tipsShownKey, true);
  }
  
  /// Check if a specific tip has been shown
  static Future<bool> isTipShown(String tipKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(tipKey) ?? false;
  }
  
  /// Mark a specific tip as shown
  static Future<void> markTipAsShown(String tipKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(tipKey, true);
    
    // Check if all tips have been shown
    if (await _areAllIndividualTipsShown()) {
      await markAllTipsAsShown();
    }
  }
  
  /// Reset all tips (for testing)
  static Future<void> resetAllTips() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tipsShownKey);
    await prefs.remove(_homeScreenTipKey);
    await prefs.remove(_quickActionsKey);
    await prefs.remove(_addButtonKey);
    await prefs.remove(_historyTipKey);
    await prefs.remove(_statisticsTipKey);
    await prefs.remove(_priceChangeKey);
    await prefs.remove(_menuActionsKey);
    await prefs.remove(_priceHistoryKey);
    await prefs.remove(_mainAppTutorialKey);
  }


  
  /// Check if all individual tips have been shown
  static Future<bool> _areAllIndividualTipsShown() async {
    final homeShown = await isTipShown(_homeScreenTipKey);
    final quickActionsShown = await isTipShown(_quickActionsKey);
    final addButtonShown = await isTipShown(_addButtonKey);
    final historyShown = await isTipShown(_historyTipKey);
    final statisticsShown = await isTipShown(_statisticsTipKey);
    final priceChangeShown = await isTipShown(_priceChangeKey);
    final menuActionsShown = await isTipShown(_menuActionsKey);
    final priceHistoryShown = await isTipShown(_priceHistoryKey);
    
    return homeShown && quickActionsShown && addButtonShown && historyShown && 
           statisticsShown && priceChangeShown && menuActionsShown && priceHistoryShown;
  }
  
  /// Constants for tip keys
  static String get homeScreenTipKey => _homeScreenTipKey;
  static String get quickActionsKey => _quickActionsKey;
  static String get addButtonKey => _addButtonKey;
  static String get historyTipKey => _historyTipKey;
  static String get statisticsTipKey => _statisticsTipKey;
  static String get priceChangeKey => _priceChangeKey;
  static String get menuActionsKey => _menuActionsKey;
  static String get priceHistoryKey => _priceHistoryKey;
  static String get mainAppTutorialKey => _mainAppTutorialKey;
} 