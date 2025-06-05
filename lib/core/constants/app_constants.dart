/// Application-wide constants for the SubTrackr app.
class AppConstants {
  /// Private constructor to prevent instantiation
  AppConstants._();

  /// The name of the application
  static const String APP_NAME = 'SubTrackr';
  
  /// The version number of the application
  static const String APP_VERSION = '1.0.0';

  // Navigation routes
  /// Route for the main layout screen
  static const String MAIN_LAYOUT_ROUTE = '/main';
  
  /// Route for adding a new subscription
  static const String ADD_SUBSCRIPTION_ROUTE = '/add-subscription';
  
  /// Route for editing an existing subscription
  static const String EDIT_SUBSCRIPTION_ROUTE = '/edit-subscription';
  
  /// Route for viewing subscription details
  static const String SUBSCRIPTION_DETAILS_ROUTE = '/subscription-details';
  
  /// Route for the settings screen
  static const String SETTINGS_ROUTE = '/settings';

  // Hive box names
  /// Hive box name for storing subscriptions
  static const String SUBSCRIPTIONS_BOX = 'subscriptions';
  
  /// Hive box name for storing application settings
  static const String SETTINGS_BOX = 'settings';
  
  /// Hive box name for storing tips data
  static const String TIPS_BOX = 'tips';

  // Subscription billing cycles
  /// Monthly billing cycle identifier
  static const String BILLING_CYCLE_MONTHLY = 'monthly';
  
  /// Quarterly billing cycle identifier
  static const String BILLING_CYCLE_QUARTERLY = 'quarterly';
  
  /// Yearly billing cycle identifier
  static const String BILLING_CYCLE_YEARLY = 'yearly';
  
  /// Custom billing cycle identifier
  static const String BILLING_CYCLE_CUSTOM = 'custom';

  // Subscription statuses
  /// Active subscription status
  static const String STATUS_ACTIVE = 'active';
  
  /// Paused subscription status
  static const String STATUS_PAUSED = 'paused';
  
  /// Cancelled subscription status
  static const String STATUS_CANCELLED = 'cancelled';

  // Settings keys
  /// Setting key for theme mode preference
  static const String THEME_MODE_SETTING = 'themeMode';
  
  /// Setting key for notifications enabled preference
  static const String NOTIFICATIONS_ENABLED_SETTING = 'notificationsEnabled';
  
  /// Setting key for notification time preference
  static const String NOTIFICATION_TIME_SETTING = 'notificationTime';
  
  /// Setting key for currency symbol preference
  static const String CURRENCY_SYMBOL_SETTING = 'currencySymbol';
  
  /// Setting key for currency code preference
  static const String CURRENCY_CODE_SETTING = 'currencyCode';
  
  /// Setting key for onboarding completion status
  static const String ONBOARDING_COMPLETE_SETTING = 'onboardingComplete';

  // Default values
  /// Default currency symbol (US Dollar)
  static const String DEFAULT_CURRENCY_SYMBOL = r'$';
  
  /// Default currency code (US Dollar)
  static const String DEFAULT_CURRENCY_CODE = 'USD';
  
  /// Default number of days before renewal to send notifications
  static const int DEFAULT_NOTIFICATION_DAYS_BEFORE_RENEWAL = 3;

  // UI Messages
  /// Success message shown when a subscription is added
  static const String SUBSCRIPTION_ADDED_SUCCESS = 'Subscription added successfully!';
  
  /// Success message shown when a subscription is updated
  static const String SUBSCRIPTION_UPDATED_SUCCESS = 'Subscription updated successfully!';
  
  /// Success message shown when a subscription is deleted
  static const String SUBSCRIPTION_DELETED_SUCCESS = 'Subscription deleted successfully!';

  // Categories
  /// Entertainment subscription category
  static const String CATEGORY_ENTERTAINMENT = 'Entertainment';
  
  /// Productivity subscription category
  static const String CATEGORY_PRODUCTIVITY = 'Productivity';
  
  /// News subscription category
  static const String CATEGORY_NEWS = 'News';
  
  /// Music subscription category
  static const String CATEGORY_MUSIC = 'Music';
  
  /// Gaming subscription category
  static const String CATEGORY_GAMING = 'Gaming';
  
  /// Software subscription category
  static const String CATEGORY_SOFTWARE = 'Software';
  
  /// Finance subscription category
  static const String CATEGORY_FINANCE = 'Finance';
  
  /// Health & Fitness subscription category
  static const String CATEGORY_HEALTH_FITNESS = 'Health & Fitness';
  
  /// Education subscription category
  static const String CATEGORY_EDUCATION = 'Education';
  
  /// Shopping subscription category
  static const String CATEGORY_SHOPPING = 'Shopping';
  
  /// Other subscription category
  static const String CATEGORY_OTHER = 'Other';

  // Feature flags
  /// Flag to enable or disable tips feature
  static const bool ENABLE_TIPS_FEATURE = true;
  
  /// Flag to enable or disable debug features
  static const bool ENABLE_DEBUG_FEATURES = false;

  /// List of all available subscription categories
  static const List<String> SUBSCRIPTION_CATEGORIES = [
    CATEGORY_ENTERTAINMENT,
    CATEGORY_PRODUCTIVITY,
    CATEGORY_NEWS,
    CATEGORY_MUSIC,
    CATEGORY_GAMING,
    CATEGORY_SOFTWARE,
    CATEGORY_FINANCE,
    CATEGORY_HEALTH_FITNESS,
    CATEGORY_EDUCATION,
    CATEGORY_SHOPPING,
    CATEGORY_OTHER,
  ];

  // Notification Channels
  /// Notification channel ID for subscription reminders
  static const String SUBSCRIPTION_REMINDER_CHANNEL_ID = 'subscription_reminder_channel';
  
  /// Display name for subscription reminder notification channel
  static const String SUBSCRIPTION_REMINDER_CHANNEL_NAME = 'Subscription Reminders';
  
  /// Description for subscription reminder notification channel
  static const String SUBSCRIPTION_REMINDER_CHANNEL_DESCRIPTION = 'Notifications for upcoming subscription renewals';
  
  // Routes
  /// Route for the home screen
  static const String HOME_ROUTE = '/';
  
  /// Route for the onboarding screen
  static const String ONBOARDING_ROUTE = '/onboarding';
  
  /// Route for currency selection during onboarding
  static const String CURRENCY_SELECTION_ROUTE = '/currency-selection';
  
  /// Route for the statistics screen
  static const String STATISTICS_ROUTE = '/statistics';
  
  // Error Messages
  /// Error message for failed subscription loading
  static const String ERROR_LOADING_SUBSCRIPTIONS = 'Error loading subscriptions';
  
  /// Error message for failed subscription creation
  static const String ERROR_ADDING_SUBSCRIPTION = 'Error adding subscription';
  
  /// Error message for failed subscription updates
  static const String ERROR_UPDATING_SUBSCRIPTION = 'Error updating subscription';
  
  /// Error message for failed subscription deletion
  static const String ERROR_DELETING_SUBSCRIPTION = 'Error deleting subscription';
  
  /// List of common subscription services for auto-completion and suggestions
  static const List<String> COMMON_SUBSCRIPTION_SERVICES = [
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