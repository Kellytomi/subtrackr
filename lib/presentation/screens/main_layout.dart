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
} 