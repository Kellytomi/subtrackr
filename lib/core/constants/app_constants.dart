class AppConstants {
  // App Information
  static const String appName = 'SubTrackr';
  static const String appVersion = '1.0.0';
  
  // Hive Box Names
  static const String subscriptionsBox = 'subscriptions_box';
  static const String settingsBox = 'settings';
  
  // Settings Keys
  static const String themeModeSetting = 'themeMode';
  static const String notificationsEnabledSetting = 'notificationsEnabled';
  static const String notificationTimeSetting = 'notificationTime';
  static const String currencySymbolSetting = 'currencySymbol';
  static const String currencyCodeSetting = 'currencyCode';
  static const String onboardingCompleteSetting = 'onboardingComplete';
  
  // Notification Channels
  static const String subscriptionReminderChannelId = 'subscription_reminder_channel';
  static const String subscriptionReminderChannelName = 'Subscription Reminders';
  static const String subscriptionReminderChannelDescription = 'Notifications for upcoming subscription renewals';
  
  // Default Values
  static const String defaultCurrencySymbol = '\$';
  static const String defaultCurrencyCode = 'USD';
  static const int defaultNotificationDaysBeforeRenewal = 3;
  
  // Subscription Status
  static const String statusActive = 'active';
  static const String statusPaused = 'paused';
  static const String statusCancelled = 'cancelled';
  
  // Billing Cycles
  static const String billingCycleMonthly = 'monthly';
  static const String billingCycleQuarterly = 'quarterly';
  static const String billingCycleYearly = 'yearly';
  static const String billingCycleCustom = 'custom';
  
  // Routes
  static const String homeRoute = '/';
  static const String onboardingRoute = '/onboarding';
  static const String currencySelectionRoute = '/currency-selection';
  static const String addSubscriptionRoute = '/add-subscription';
  static const String editSubscriptionRoute = '/edit-subscription';
  static const String subscriptionDetailsRoute = '/subscription-details';
  static const String settingsRoute = '/settings';
  static const String statisticsRoute = '/statistics';
  static const String notificationTestRoute = '/notification-test';
  
  // Error Messages
  static const String errorLoadingSubscriptions = 'Failed to load subscriptions';
  static const String errorSavingSubscription = 'Failed to save subscription';
  static const String errorDeletingSubscription = 'Failed to delete subscription';
  
  // Success Messages
  static const String subscriptionAddedSuccess = 'Subscription added successfully';
  static const String subscriptionUpdatedSuccess = 'Subscription updated successfully';
  static const String subscriptionDeletedSuccess = 'Subscription deleted successfully';
  
  // Common Subscription Services (for suggestions)
  static const List<String> commonSubscriptionServices = [
    'Netflix',
    'Spotify',
    'Amazon Prime',
    'Disney+',
    'YouTube Premium',
    'Apple Music',
    'HBO Max',
    'Hulu',
    'Adobe Creative Cloud',
    'Microsoft 365',
    'PlayStation Plus',
    'Xbox Game Pass',
    'Nintendo Switch Online',
    'Dropbox',
    'Google One',
    'iCloud',
    'Audible',
    'Twitch',
    'Patreon',
    'Notion',
    'Slack',
    'Zoom',
    'Canva',
    'Figma',
    'Grammarly',
    'ExpressVPN',
    'NordVPN',
    'Surfshark',
    'Dashlane',
    'LastPass',
    '1Password',
  ];
} 