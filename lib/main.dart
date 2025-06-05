import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/core/theme/app_theme.dart';
import 'package:subtrackr/data/repositories/subscription_repository.dart';
import 'package:subtrackr/data/services/logo_service.dart';
import 'package:subtrackr/data/services/notification_service.dart';
import 'package:subtrackr/data/services/settings_service.dart';
import 'package:subtrackr/presentation/blocs/subscription_provider.dart';
import 'package:subtrackr/presentation/blocs/theme_provider.dart';
import 'package:subtrackr/presentation/screens/add_subscription_screen.dart';
import 'package:subtrackr/presentation/screens/edit_subscription_screen.dart';
import 'package:subtrackr/presentation/screens/main_layout.dart';
import 'package:subtrackr/presentation/screens/onboarding_screen.dart';
import 'package:subtrackr/presentation/screens/subscription_details_screen.dart';
import 'package:subtrackr/presentation/screens/settings_screen.dart';
import 'package:subtrackr/presentation/screens/statistics_screen.dart';
import 'package:subtrackr/presentation/screens/onboarding/currency_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set status bar style based on theme
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.light, // iOS: dark icons for light background
    statusBarIconBrightness: Brightness.dark, // Android: dark icons for light background
  ));
  
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
      ? AppConstants.ONBOARDING_ROUTE 
      : (currencyCode == null || currencyCode.isEmpty) 
          ? AppConstants.CURRENCY_SELECTION_ROUTE 
          : AppConstants.HOME_ROUTE;
  
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
            notificationService: notificationService,
            settingsService: settingsService,
          )..loadSubscriptions(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
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
            },
          );
        },
      ),
    );
  }
}
