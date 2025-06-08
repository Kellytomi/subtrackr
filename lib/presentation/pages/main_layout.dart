import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/core/widgets/enhanced_tutorial.dart';
import 'package:subtrackr/core/utils/tips_helper.dart';
import 'package:subtrackr/presentation/providers/theme_provider.dart';
import 'package:subtrackr/domain/entities/subscription.dart';
import 'package:subtrackr/presentation/pages/subscription_details_screen.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/presentation/providers/subscription_provider.dart';
import 'package:subtrackr/presentation/pages/home_screen.dart';
import 'package:subtrackr/presentation/pages/settings_screen.dart';
import 'package:subtrackr/presentation/pages/statistics_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final GlobalKey _fabKey = GlobalKey();
  final GlobalKey _homeNavKey = GlobalKey();
  final GlobalKey _statsNavKey = GlobalKey();
  final GlobalKey _settingsNavKey = GlobalKey();
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const StatisticsScreen(),
    const SettingsScreen(),
  ];
  
  @override
  void initState() {
    super.initState();
  }
  
  // Create example subscription for tutorial
  Subscription _createExampleSubscription() {
    final now = DateTime.now();
    return Subscription(
      id: 'tutorial_example',
      name: 'Netflix',
      logoUrl: 'https://logo.clearbit.com/netflix.com',
      amount: 15.99,
      billingCycle: AppConstants.BILLING_CYCLE_MONTHLY,
      startDate: now.subtract(const Duration(days: 30)),
      renewalDate: now.add(const Duration(days: 15)),
      status: AppConstants.STATUS_ACTIVE,
      currencyCode: 'USD',
      category: AppConstants.CATEGORY_ENTERTAINMENT,
      website: 'https://netflix.com',
      description: 'Streaming service for movies and TV shows',
    );
  }
  
  // Navigate to subscription details for tutorial
  void _navigateToSubscriptionTutorial() async {
    // First, we need to add the example subscription to the provider
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    final exampleSubscription = _createExampleSubscription();
    
    // Add to provider temporarily for tutorial
    await subscriptionProvider.addSubscription(exampleSubscription);
    
    // Navigate with subscription ID
    await Navigator.pushNamed(
      context,
      AppConstants.SUBSCRIPTION_DETAILS_ROUTE,
      arguments: {
        'id': exampleSubscription.id,
        'isTutorialMode': true, // Flag to indicate this is tutorial mode
      },
    );
    
    // Clean up: remove the example subscription after tutorial
    await subscriptionProvider.deleteSubscription(exampleSubscription.id);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        // If we're not on the home tab, switch to it instead of exiting the app
        if (!didPop && _currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: EnhancedTutorial(
        tutorialKey: TipsHelper.mainAppTutorialKey,
        tips: [
          EnhancedTip(
            title: 'Welcome to SubTrackr! 🎉',
            message: 'Your personal subscription tracker. Let\'s get started with a quick tour to show you all the amazing features.',
            icon: Icons.celebration,
            position: const Offset(0.5, 0.4),
            backgroundColor: Colors.blue,
          ),
          EnhancedTip(
            title: 'Track Your Subscriptions 🏠',
            message: 'All your subscriptions appear on the home screen. You\'ll see total cost, upcoming renewals, and can manage everything at a glance.',
            icon: Icons.home,
            position: const Offset(0.5, 0.2),
            targetKey: _homeNavKey,
            backgroundColor: Colors.green,
          ),
          EnhancedTip(
            title: 'Add New Subscriptions ➕',
            message: 'Tap the + button to add a new subscription. Enter details like name, amount, billing cycle, and even add logos!',
            icon: Icons.add_circle,
            position: const Offset(0.5, 0.7),
            targetKey: _fabKey,
            backgroundColor: Colors.purple,
          ),
          EnhancedTip(
            title: 'Subscription Management 📋',
            message: 'Now let\'s see how to manage individual subscriptions! We\'ll show you an example subscription with all the features.',
            icon: Icons.article,
            position: const Offset(0.5, 0.5),
            backgroundColor: Colors.indigo,
            onTipShown: _navigateToSubscriptionTutorial,
          ),
          EnhancedTip(
            title: 'View Your Statistics 📊',
            message: 'See beautiful charts and insights about your spending habits on the Statistics tab. Track trends and patterns.',
            icon: Icons.bar_chart,
            position: const Offset(0.5, 0.2),
            targetKey: _statsNavKey,
            backgroundColor: Colors.orange,
          ),
          EnhancedTip(
            title: 'Customize Your Experience ⚙️',
            message: 'Change currency, theme, notification settings, and access debug features in the Settings tab.',
            icon: Icons.settings,
            position: const Offset(0.5, 0.2),
            targetKey: _settingsNavKey,
            backgroundColor: Colors.teal,
          ),
          EnhancedTip(
            title: 'You\'re All Set! ✨',
            message: 'Welcome to SubTrackr! You\'ve completed the guided tour. Start tracking your subscriptions and take control of your spending!',
            icon: Icons.check_circle,
            position: const Offset(0.5, 0.5),
            backgroundColor: Colors.green,
          ),
        ],
        child: Scaffold(
          body: _screens[_currentIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            indicatorColor: colorScheme.primary.withOpacity(0.2),
            backgroundColor: colorScheme.surface,
            elevation: 0,
            destinations: [
              NavigationDestination(
                key: _homeNavKey,
                icon: Icon(Icons.home_outlined, color: colorScheme.onSurface.withOpacity(0.7)),
                selectedIcon: Icon(Icons.home, color: colorScheme.primary),
                label: 'Home',
              ),
              NavigationDestination(
                key: _statsNavKey,
                icon: Icon(Icons.bar_chart_outlined, color: colorScheme.onSurface.withOpacity(0.7)),
                selectedIcon: Icon(Icons.bar_chart, color: colorScheme.primary),
                label: 'Statistics',
              ),
              NavigationDestination(
                key: _settingsNavKey,
                icon: Icon(Icons.settings_outlined, color: colorScheme.onSurface.withOpacity(0.7)),
                selectedIcon: Icon(Icons.settings, color: colorScheme.primary),
                label: 'Settings',
              ),
            ],
          ),
          floatingActionButton: _currentIndex == 0
              ? FloatingActionButton(
                  key: _fabKey,
                  heroTag: "add_subscription_fab",
                  onPressed: () {
                    Navigator.pushNamed(context, AppConstants.ADD_SUBSCRIPTION_ROUTE);
                  },
                  child: const Icon(Icons.add),
                )
              : null,
        ),
      ),
    );
  }
} 