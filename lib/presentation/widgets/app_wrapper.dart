import 'package:flutter/material.dart';
import 'package:subtrackr/core/utils/update_manager.dart';

/// Wrapper widget that handles app-level functionality like update checking
/// 
/// This widget is responsible for:
/// - Checking for updates on app startup
/// - Providing a clean separation between update logic and app navigation
/// - Ensuring updates are handled gracefully without blocking the UI
class AppWrapper extends StatefulWidget {
  final Widget child;
  
  const AppWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> with WidgetsBindingObserver {
  final UpdateManager _updateManager = UpdateManager();
  bool _hasCheckedForUpdates = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Check for updates after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdatesOnStartup();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateManager.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Check for updates when app comes back to foreground
    if (state == AppLifecycleState.resumed && _hasCheckedForUpdates) {
      _checkForUpdatesOnResume();
    }
  }

  /// Checks for updates on app startup
  Future<void> _checkForUpdatesOnStartup() async {
    if (!mounted || _hasCheckedForUpdates) return;
    
    _hasCheckedForUpdates = true;
    
    try {
      await _updateManager.checkForUpdatesOnStartup(context);
    } catch (e) {
      debugPrint('Error checking for updates on startup: $e');
    }
  }

  /// Checks for updates when app resumes from background
  Future<void> _checkForUpdatesOnResume() async {
    if (!mounted) return;
    
    try {
      await _updateManager.checkForUpdatesWithUI(
        context: context,
        showNoUpdateMessage: false,
      );
    } catch (e) {
      debugPrint('Error checking for updates on resume: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
} 