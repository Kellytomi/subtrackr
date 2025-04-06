import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/core/theme/app_theme.dart';
import 'package:subtrackr/data/repositories/subscription_repository.dart';
import 'package:subtrackr/data/services/logo_service.dart';
import 'package:subtrackr/data/services/notification_service.dart';
import 'package:subtrackr/data/services/settings_service.dart';
import 'package:subtrackr/presentation/blocs/subscription_provider.dart';
import 'package:subtrackr/presentation/blocs/theme_provider.dart';
import 'package:subtrackr/presentation/screens/home_screen.dart';
import 'package:subtrackr/presentation/screens/add_subscription_screen.dart';
import 'package:subtrackr/presentation/screens/main_layout.dart';
import 'package:subtrackr/presentation/screens/notification_test_screen.dart';
import 'package:subtrackr/presentation/screens/onboarding_screen.dart';
import 'package:subtrackr/presentation/screens/subscription_details_screen.dart';
import 'package:subtrackr/presentation/screens/settings_screen.dart';
import 'package:subtrackr/presentation/screens/statistics_screen.dart';
import 'package:subtrackr/presentation/screens/onboarding/currency_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize services
  final settingsService = SettingsService();
  await settingsService.init();
  
  final notificationService = NotificationService();
  await notificationService.init();
  
  final logoService = LogoService();
  
  final subscriptionRepository = SubscriptionRepository();
  await subscriptionRepository.init();
  
  // Check if onboarding is complete and currency is set
  final onboardingComplete = settingsService.isOnboardingComplete();
  final currencyCode = settingsService.getCurrencyCode();
  final initialRoute = !onboardingComplete 
      ? AppConstants.onboardingRoute 
      : (currencyCode == null || currencyCode.isEmpty) 
          ? AppConstants.currencySelectionRoute 
          : AppConstants.homeRoute;
  
  runApp(MyApp(
    settingsService: settingsService,
    notificationService: notificationService,
    logoService: logoService,
    subscriptionRepository: subscriptionRepository,
    initialRoute: initialRoute,
  ));
}

class MyApp extends StatelessWidget {
  final SettingsService settingsService;
  final NotificationService notificationService;
  final LogoService logoService;
  final SubscriptionRepository subscriptionRepository;
  final String initialRoute;
  
  const MyApp({
    super.key,
    required this.settingsService,
    required this.notificationService,
    required this.logoService,
    required this.subscriptionRepository,
    required this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SettingsService>.value(value: settingsService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<LogoService>.value(value: logoService),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(
            settingsService: settingsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SubscriptionProvider(
            repository: subscriptionRepository,
            notificationService: notificationService,
            settingsService: settingsService,
          )..loadSubscriptions(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            theme: themeProvider.themeData,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            initialRoute: initialRoute,
            routes: {
              AppConstants.onboardingRoute: (_) => const OnboardingScreen(),
              AppConstants.currencySelectionRoute: (_) => const CurrencySelectionScreen(),
              AppConstants.homeRoute: (_) => const MainLayout(),
              AppConstants.addSubscriptionRoute: (_) => const AddSubscriptionScreen(),
              AppConstants.subscriptionDetailsRoute: (_) => const SubscriptionDetailsScreen(),
              AppConstants.settingsRoute: (_) => const SettingsScreen(),
              AppConstants.statisticsRoute: (_) => const StatisticsScreen(),
              AppConstants.notificationTestRoute: (_) => const NotificationTestScreen(),
            },
          );
        },
      ),
    );
  }
}
