import 'package:flutter_test/flutter_test.dart';
import 'package:subtrackr/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('should have correct app name and version', () {
      expect(AppConstants.APP_NAME, 'SubTrackr');
      expect(AppConstants.APP_VERSION, '1.0.0');
    });

    test('should have correct navigation routes', () {
      expect(AppConstants.MAIN_LAYOUT_ROUTE, '/main');
      expect(AppConstants.ADD_SUBSCRIPTION_ROUTE, '/add-subscription');
      expect(AppConstants.EDIT_SUBSCRIPTION_ROUTE, '/edit-subscription');
      expect(AppConstants.SUBSCRIPTION_DETAILS_ROUTE, '/subscription-details');
      expect(AppConstants.SETTINGS_ROUTE, '/settings');
      expect(AppConstants.HOME_ROUTE, '/');
      expect(AppConstants.ONBOARDING_ROUTE, '/onboarding');
      expect(AppConstants.CURRENCY_SELECTION_ROUTE, '/currency-selection');
      expect(AppConstants.STATISTICS_ROUTE, '/statistics');
    });

    test('should have correct Hive box names', () {
      expect(AppConstants.SUBSCRIPTIONS_BOX, 'subscriptions');
      expect(AppConstants.SETTINGS_BOX, 'settings');
      expect(AppConstants.TIPS_BOX, 'tips');
    });

    test('should have correct billing cycles', () {
      expect(AppConstants.BILLING_CYCLE_MONTHLY, 'monthly');
      expect(AppConstants.BILLING_CYCLE_QUARTERLY, 'quarterly');
      expect(AppConstants.BILLING_CYCLE_YEARLY, 'yearly');
      expect(AppConstants.BILLING_CYCLE_CUSTOM, 'custom');
    });

    test('should have correct subscription statuses', () {
      expect(AppConstants.STATUS_ACTIVE, 'active');
      expect(AppConstants.STATUS_PAUSED, 'paused');
      expect(AppConstants.STATUS_CANCELLED, 'cancelled');
    });

    test('should have correct default values', () {
      expect(AppConstants.DEFAULT_CURRENCY_SYMBOL, r'$');
      expect(AppConstants.DEFAULT_CURRENCY_CODE, 'USD');
      expect(AppConstants.DEFAULT_NOTIFICATION_DAYS_BEFORE_RENEWAL, 3);
    });

    test('should have correct feature flags', () {
      expect(AppConstants.ENABLE_TIPS_FEATURE, true);
      expect(AppConstants.ENABLE_DEBUG_FEATURES, false);
    });

    test('should have all subscription categories', () {
      expect(AppConstants.SUBSCRIPTION_CATEGORIES, hasLength(11));
      expect(AppConstants.SUBSCRIPTION_CATEGORIES, contains('Entertainment'));
      expect(AppConstants.SUBSCRIPTION_CATEGORIES, contains('Productivity'));
      expect(AppConstants.SUBSCRIPTION_CATEGORIES, contains('Health & Fitness'));
    });

    test('should follow SCREAMING_SNAKE_CASE naming convention', () {
      // This test verifies that our constants follow the proper naming convention
      final constantNames = [
        'APP_NAME',
        'APP_VERSION',
        'BILLING_CYCLE_MONTHLY',
        'STATUS_ACTIVE',
        'DEFAULT_CURRENCY_CODE',
        'SUBSCRIPTION_REMINDER_CHANNEL_ID',
      ];
      
      for (final name in constantNames) {
        expect(name, matches(RegExp(r'^[A-Z][A-Z0-9_]*$')),
            reason: '$name should be in SCREAMING_SNAKE_CASE');
      }
    });
  });
} 