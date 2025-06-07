import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/core/widgets/feature_tutorial.dart';
import 'package:subtrackr/presentation/providers/theme_provider.dart';
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
      child: FeatureTutorial(
        tutorialKey: 'main_app_tutorial',
        tips: [
          TutorialTip(
            title: 'Welcome to SubTrackr!',
            message: 'Your personal subscription tracker. Let\'s get started with a quick tour.',
            icon: Icons.celebration,
            position: const Offset(0.5, 0.4),
          ),
          TutorialTip(
            title: 'Track Your Subscriptions',
            message: 'All your subscriptions appear on the home screen. You\'ll see total cost and upcoming renewals at a glance.',
            icon: Icons.home,
            position: const Offset(0.5, 0.4),
            targetKey: _homeNavKey,
          ),
          TutorialTip(
            title: 'Add New Subscriptions',
            message: 'Tap the + button to add a new subscription. Enter details like name, amount, and billing cycle.',
            icon: Icons.add_circle,
            position: const Offset(0.5, 0.7),
            targetKey: _fabKey,
          ),
          TutorialTip(
            title: 'View Your Statistics',
            message: 'See charts and insights about your spending habits on the Statistics tab.',
            icon: Icons.bar_chart,
            position: const Offset(0.5, 0.4),
            targetKey: _statsNavKey,
          ),
          TutorialTip(
            title: 'Customize Your Experience',
            message: 'Change currency, theme, and notification settings in the Settings tab.',
            icon: Icons.settings,
            position: const Offset(0.5, 0.4),
            targetKey: _settingsNavKey,
          ),
          TutorialTip(
            title: 'You\'re All Set!',
            message: 'Start tracking your subscriptions now. If you need to see these tips again, you can reset them in Settings.',
            icon: Icons.check_circle,
            position: const Offset(0.5, 0.5),
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