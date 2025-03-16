import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/presentation/blocs/theme_provider.dart';
import 'package:subtrackr/presentation/screens/home_screen.dart';
import 'package:subtrackr/presentation/screens/settings_screen.dart';
import 'package:subtrackr/presentation/screens/statistics_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  bool _showTips = true;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const StatisticsScreen(),
    const SettingsScreen(),
  ];
  
  @override
  void initState() {
    super.initState();
    // Check if this is the first time the app is opened
    _checkFirstTimeUser();
  }
  
  Future<void> _checkFirstTimeUser() async {
    // In a real app, you would check shared preferences or similar
    // For now, we'll just show tips for everyone
    setState(() {
      _showTips = true;
    });
  }
  
  void _dismissTips() {
    setState(() {
      _showTips = false;
    });
    // In a real app, you would save this preference
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    return WillPopScope(
      onWillPop: () async {
        // If we're not on the home tab, switch to it instead of exiting the app
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showTips) _buildTips(colorScheme),
            NavigationBar(
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
                  icon: Icon(Icons.home_outlined, color: colorScheme.onSurface.withOpacity(0.7)),
                  selectedIcon: Icon(Icons.home, color: colorScheme.primary),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined, color: colorScheme.onSurface.withOpacity(0.7)),
                  selectedIcon: Icon(Icons.bar_chart, color: colorScheme.primary),
                  label: 'Statistics',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined, color: colorScheme.onSurface.withOpacity(0.7)),
                  selectedIcon: Icon(Icons.settings, color: colorScheme.primary),
                  label: 'Settings',
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: _currentIndex == 0
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppConstants.addSubscriptionRoute);
                },
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }
  
  Widget _buildTips(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Tips',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _dismissTips,
                color: colorScheme.primary,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Swipe left on a subscription to see actions',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '• Tap the + button to add a new subscription',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '• Use the bottom navigation to switch between screens',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
} 