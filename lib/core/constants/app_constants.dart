/// Application-wide constants for the SubTrackr app.
class AppConstants {
  /// Private constructor to prevent instantiation
  AppConstants._();

  /// The name of the application
  static const String appName = 'SubTrackr';
  
  /// The version number of the application
  static const String appVersion = '1.0.0';

  // Navigation routes
  /// Route for the main layout screen
  static const String mainLayoutRoute = '/main';
  
  /// Route for adding a new subscription
  static const String addSubscriptionRoute = '/add-subscription';
  
  /// Route for editing an existing subscription
  static const String editSubscriptionRoute = '/edit-subscription';
  
  /// Route for viewing subscription details
  static const String subscriptionDetailsRoute = '/subscription-details';
  
  /// Route for the settings screen
  static const String settingsRoute = '/settings';

  // Hive box names
  /// Hive box name for storing subscriptions
  static const String subscriptionsBox = 'subscriptions';
  
  /// Hive box name for storing application settings
  static const String settingsBox = 'settings';
  
  /// Hive box name for storing tips data
  static const String tipsBox = 'tips';

  // Subscription billing cycles
  /// Monthly billing cycle identifier
  static const String billingCycleMonthly = 'monthly';
  
  /// Quarterly billing cycle identifier
  static const String billingCycleQuarterly = 'quarterly';
  
  /// Yearly billing cycle identifier
  static const String billingCycleYearly = 'yearly';
  
  /// Custom billing cycle identifier
  static const String billingCycleCustom = 'custom';

  // Subscription statuses
  /// Active subscription status
  static const String statusActive = 'active';
  
  /// Paused subscription status
  static const String statusPaused = 'paused';
  
  /// Cancelled subscription status
  static const String statusCancelled = 'cancelled';

  // Settings keys
  /// Setting key for theme mode preference
  static const String themeModeSetting = 'themeMode';
  
  /// Setting key for notifications enabled preference
  static const String notificationsEnabledSetting = 'notificationsEnabled';
  
  /// Setting key for notification time preference
  static const String notificationTimeSetting = 'notificationTime';
  
  /// Setting key for currency symbol preference
  static const String currencySymbolSetting = 'currencySymbol';
  
  /// Setting key for currency code preference
  static const String currencyCodeSetting = 'currencyCode';
  
  /// Setting key for onboarding completion status
  static const String onboardingCompleteSetting = 'onboardingComplete';

  // Default values
  /// Default currency symbol (US Dollar)
  static const String defaultCurrencySymbol = r'$';
  
  /// Default currency code (US Dollar)
  static const String defaultCurrencyCode = 'USD';
  
  /// Default number of days before renewal to send notifications
  static const int defaultNotificationDaysBeforeRenewal = 3;

  // UI Messages
  /// Success message shown when a subscription is added
  static const String subscriptionAddedSuccess = 'Subscription added successfully!';
  
  /// Success message shown when a subscription is updated
  static const String subscriptionUpdatedSuccess = 'Subscription updated successfully!';
  
  /// Success message shown when a subscription is deleted
  static const String subscriptionDeletedSuccess = 'Subscription deleted successfully!';

  // Categories
  /// Entertainment subscription category
  static const String categoryEntertainment = 'Entertainment';
  
  /// Productivity subscription category
  static const String categoryProductivity = 'Productivity';
  
  /// News subscription category
  static const String categoryNews = 'News';
  
  /// Music subscription category
  static const String categoryMusic = 'Music';
  
  /// Gaming subscription category
  static const String categoryGaming = 'Gaming';
  
  /// Software subscription category
  static const String categorySoftware = 'Software';
  
  /// Finance subscription category
  static const String categoryFinance = 'Finance';
  
  /// Health & Fitness subscription category
  static const String categoryHealthFitness = 'Health & Fitness';
  
  /// Education subscription category
  static const String categoryEducation = 'Education';
  
  /// Shopping subscription category
  static const String categoryShopping = 'Shopping';
  
  /// Other subscription category
  static const String categoryOther = 'Other';

  // Feature flags
  /// Flag to enable or disable tips feature
  static const bool enableTipsFeature = true;
  
  /// Flag to enable or disable debug features
  static const bool enableDebugFeatures = false;

  /// List of all available subscription categories
  static const List<String> subscriptionCategories = [
    categoryEntertainment,
    categoryProductivity,
    categoryNews,
    categoryMusic,
    categoryGaming,
    categorySoftware,
    categoryFinance,
    categoryHealthFitness,
    categoryEducation,
    categoryShopping,
    categoryOther,
  ];

  // Notification Channels
  /// Notification channel ID for subscription reminders
  static const String subscriptionReminderChannelId = 'subscription_reminder_channel';
  
  /// Display name for subscription reminder notification channel
  static const String subscriptionReminderChannelName = 'Subscription Reminders';
  
  /// Description for subscription reminder notification channel
  static const String subscriptionReminderChannelDescription = 'Notifications for upcoming subscription renewals';
  
  // Routes
  /// Route for the home screen
  static const String homeRoute = '/';
  
  /// Route for the onboarding screen
  static const String onboardingRoute = '/onboarding';
  
  /// Route for currency selection during onboarding
  static const String currencySelectionRoute = '/currency-selection';
  
  /// Route for the statistics screen
  static const String statisticsRoute = '/statistics';
  
  // Error Messages
  /// Error message for failed subscription loading
  static const String errorLoadingSubscriptions = 'Error loading subscriptions';
  
  /// Error message for failed subscription creation
  static const String errorAddingSubscription = 'Error adding subscription';
  
  /// Error message for failed subscription updates
  static const String errorUpdatingSubscription = 'Error updating subscription';
  
  /// Error message for failed subscription deletion
  static const String errorDeletingSubscription = 'Error deleting subscription';
  
  /// List of common subscription services for auto-completion and suggestions
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