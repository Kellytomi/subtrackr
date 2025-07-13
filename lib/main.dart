import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/core/theme/app_theme.dart';
import 'package:subtrackr/core/config/supabase_config.dart';

import 'package:subtrackr/presentation/widgets/app_wrapper.dart';
import 'package:subtrackr/data/repositories/subscription_repository.dart';
import 'package:subtrackr/data/repositories/price_change_repository.dart';
import 'package:subtrackr/data/repositories/local_subscription_repository.dart';
import 'package:subtrackr/data/repositories/supabase_subscription_repository.dart';
import 'package:subtrackr/data/repositories/dual_subscription_repository.dart';
import 'package:subtrackr/data/services/supabase_auth_service.dart';
import 'package:subtrackr/data/services/supabase_cloud_sync_service.dart';
import 'package:subtrackr/data/services/auto_sync_service.dart';
import 'package:subtrackr/data/services/logo_service.dart';
import 'package:subtrackr/data/services/notification_service.dart';
import 'package:subtrackr/data/services/settings_service.dart';
import 'package:subtrackr/presentation/providers/subscription_provider.dart';
import 'package:subtrackr/presentation/providers/theme_provider.dart';
import 'package:subtrackr/presentation/pages/add_subscription_screen.dart';
import 'package:subtrackr/presentation/pages/edit_subscription_screen.dart';
import 'package:subtrackr/presentation/pages/main_layout.dart';
import 'package:subtrackr/presentation/pages/onboarding_screen.dart';
import 'package:subtrackr/presentation/pages/subscription_details_screen.dart';
import 'package:subtrackr/presentation/pages/settings_screen.dart';
import 'package:subtrackr/presentation/pages/statistics_screen.dart';
import 'package:subtrackr/presentation/pages/onboarding/currency_selection_screen.dart';
import 'package:subtrackr/presentation/pages/email_detection_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseConfig.initialize();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize services
  final settingsService = SettingsService();
  await settingsService.init();
  
  final notificationService = NotificationService();
  await notificationService.init();
  
  final logoService = LogoService();
  
  // Initialize repositories
  final priceChangeRepository = PriceChangeRepository();
  await priceChangeRepository.init();
  
  // Initialize Supabase-based services
  final supabaseAuthService = SupabaseAuthService();
  final localSubscriptionRepository = LocalSubscriptionRepository();
  final supabaseSubscriptionRepository = SupabaseSubscriptionRepository();
  final dualSubscriptionRepository = DualSubscriptionRepository(
    localRepository: localSubscriptionRepository,
    supabaseRepository: supabaseSubscriptionRepository,
    authService: supabaseAuthService,
  );
  
  final autoSyncService = AutoSyncService(
    localRepository: localSubscriptionRepository,
    supabaseRepository: supabaseSubscriptionRepository,
  );
  
  final supabaseCloudSyncService = SupabaseCloudSyncService(
    authService: supabaseAuthService,
    autoSyncService: autoSyncService,
    repository: dualSubscriptionRepository,
  );
  
  // Initialize repositories
  await localSubscriptionRepository.init();
  await supabaseSubscriptionRepository.init();
  await dualSubscriptionRepository.init();
  
  // Initialize cloud sync service
  try {
    await supabaseCloudSyncService.initialize();
    print('✅ SupabaseCloudSyncService initialized successfully');
  } catch (e) {
    print('⚠️ SupabaseCloudSyncService initialization failed: $e');
    // Continue without cloud sync - app should still work
  }
  
  // Check if onboarding is complete and currency is set
  final onboardingComplete = settingsService.isOnboardingComplete();
  final currencyCode = settingsService.getCurrencyCode();
  final initialRoute = !onboardingComplete 
      ? AppConstants.ONBOARDING_ROUTE 
      : (currencyCode == null || currencyCode.isEmpty) 
          ? AppConstants.CURRENCY_SELECTION_ROUTE 
          : AppConstants.HOME_ROUTE;
  
  // Set initial system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: AppTheme.lightTheme.scaffoldBackgroundColor,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(MyApp(
    settingsService: settingsService,
    notificationService: notificationService,
    logoService: logoService,
    subscriptionRepository: dualSubscriptionRepository,
    priceChangeRepository: priceChangeRepository,
    supabaseCloudSyncService: supabaseCloudSyncService,
    supabaseAuthService: supabaseAuthService,
    initialRoute: initialRoute,
  ));
}

class MyApp extends StatelessWidget {
  final SettingsService settingsService;
  final NotificationService notificationService;
  final LogoService logoService;
  final DualSubscriptionRepository subscriptionRepository;
  final PriceChangeRepository priceChangeRepository;
  final SupabaseCloudSyncService supabaseCloudSyncService;
  final SupabaseAuthService supabaseAuthService;
  final String initialRoute;
  
  const MyApp({
    super.key,
    required this.settingsService,
    required this.notificationService,
    required this.logoService,
    required this.subscriptionRepository,
    required this.priceChangeRepository,
    required this.supabaseCloudSyncService,
    required this.supabaseAuthService,
    required this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SettingsService>.value(value: settingsService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<LogoService>.value(value: logoService),
        Provider<SupabaseCloudSyncService>.value(value: supabaseCloudSyncService),
        Provider<SupabaseAuthService>.value(value: supabaseAuthService),
        ChangeNotifierProvider(
          create: (_) {
            final provider = ThemeProvider(
              settingsService: settingsService,
            );
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => SubscriptionProvider(
            repository: subscriptionRepository,
            priceChangeRepository: priceChangeRepository,
            notificationService: notificationService,
            settingsService: settingsService,
            supabaseCloudSyncService: supabaseCloudSyncService,
          )..loadSubscriptions(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return AppWrapper(
            child: MaterialApp(
              title: AppConstants.APP_NAME,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              debugShowCheckedModeBanner: false,
              initialRoute: initialRoute,
              routes: {
                AppConstants.ONBOARDING_ROUTE: (_) => const OnboardingScreen(),
                AppConstants.CURRENCY_SELECTION_ROUTE: (_) => const CurrencySelectionScreen(),
                AppConstants.HOME_ROUTE: (_) => const MainLayout(),
                AppConstants.ADD_SUBSCRIPTION_ROUTE: (_) => const AddSubscriptionScreen(),
                AppConstants.EDIT_SUBSCRIPTION_ROUTE: (_) => const EditSubscriptionScreen(),
                AppConstants.SUBSCRIPTION_DETAILS_ROUTE: (_) => const SubscriptionDetailsScreen(),
                AppConstants.SETTINGS_ROUTE: (_) => const SettingsScreen(),
                AppConstants.STATISTICS_ROUTE: (_) => const StatisticsScreen(),
                AppConstants.EMAIL_DETECTION_ROUTE: (_) => const EmailDetectionPage(),

              },
            ),
          );
        },
      ),
    );
  }
}
