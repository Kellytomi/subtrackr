import 'package:flutter/material.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:restart_app/restart_app.dart';

/// Service responsible for managing over-the-air updates using Shorebird
/// 
/// This service provides functionality to:
/// - Check for available updates
/// - Download updates with user consent
/// - Handle update errors gracefully
/// - Restart the app when updates are ready
class UpdateManager {
  static final UpdateManager _instance = UpdateManager._internal();
  factory UpdateManager() => _instance;
  UpdateManager._internal();

  final ShorebirdUpdater _updater = ShorebirdUpdater();
  
  bool _isCheckingForUpdate = false;
  bool _isDownloadingUpdate = false;

  /// Checks if the device supports Shorebird updates
  Future<bool> isUpdateAvailable() async {
    try {
      final status = await _updater.checkForUpdate();
      return status == UpdateStatus.outdated;
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return false;
    }
  }

  /// Gets the current installed patch version
  Future<int?> getCurrentPatchVersion() async {
    try {
      final patch = await _updater.readCurrentPatch();
      return patch?.number;
    } catch (e) {
      debugPrint('Error reading current patch: $e');
      return null;
    }
  }

  /// Gets detailed patch information including metadata
  Future<Map<String, dynamic>> getPatchInfo() async {
    try {
      final patch = await _updater.readCurrentPatch();
      final hasUpdate = await isUpdateAvailable();
      
      return {
        'hasPatch': patch != null,
        'patchNumber': patch?.number,
        'hasUpdate': hasUpdate,
        'lastChecked': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting patch info: $e');
             return {
         'hasPatch': false,
         'patchNumber': null,
         'hasUpdate': false,
         'lastChecked': DateTime.now().toIso8601String(),
         'error': e.toString(),
       };
    }
  }

  /// Checks for updates and shows user-friendly notifications
  Future<void> checkForUpdatesWithUI({
    required BuildContext context,
    bool showNoUpdateMessage = true,
  }) async {
    if (_isCheckingForUpdate) return;

    _isCheckingForUpdate = true;

    try {
      final hasUpdate = await isUpdateAvailable();
      
      if (!context.mounted) return;

      if (hasUpdate) {
        _showUpdateAvailableBanner(context);
      } else if (showNoUpdateMessage) {
        _showSnackBar(
          context,
          'No updates available',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
      if (context.mounted) {
        _showSnackBar(
          context,
          'Failed to check for updates. Please try again.',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      _isCheckingForUpdate = false;
    }
  }

  /// Downloads available updates with user feedback
  Future<void> downloadUpdate(BuildContext context) async {
    if (_isDownloadingUpdate) return;

    _isDownloadingUpdate = true;
    _hideCurrentBanner(context);
    _showDownloadingBanner(context);

    try {
      await _updater.update();
      
      if (!context.mounted) return;
      
      _hideCurrentBanner(context);
      _showRestartBanner(context);
    } catch (e) {
      debugPrint('Update download failed: $e');
      
      if (!context.mounted) return;
      
      _hideCurrentBanner(context);
      _showSnackBar(
        context,
        'Update failed. Please try again later.',
        backgroundColor: Colors.red,
      );
    } finally {
      _isDownloadingUpdate = false;
    }
  }

  /// Automatically check for updates on app startup
  Future<void> checkForUpdatesOnStartup(BuildContext context) async {
    // Wait a bit for the app to fully initialize
    await Future.delayed(const Duration(seconds: 2));
    
    if (!context.mounted) return;
    
    await checkForUpdatesWithUI(
      context: context,
      showNoUpdateMessage: false,
    );
  }

  /// Shows banner when update is available
  void _showUpdateAvailableBanner(BuildContext context) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        content: Text(
          'A new update is available!',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _hideCurrentBanner(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () => downloadUpdate(context),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  /// Shows banner while downloading update
  void _showDownloadingBanner(BuildContext context) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Downloading update...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
        actions: const [SizedBox.shrink()],
      ),
    );
  }

  /// Shows banner when update is ready to install
  void _showRestartBanner(BuildContext context) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: Colors.green.shade100,
        content: const Text(
          'Update downloaded! Restart to apply changes.',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _hideCurrentBanner(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () => _restartApp(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restart Now'),
          ),
        ],
      ),
    );
  }

  /// Shows a snack bar with a message
  void _showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Hides the current banner
  void _hideCurrentBanner(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
  }

  /// Restarts the application
  void _restartApp() {
    try {
      Restart.restartApp();
    } catch (e) {
      debugPrint('Failed to restart app: $e');
      // Fallback: You might want to show a message asking user to manually restart
    }
  }

  /// Disposes resources
  void dispose() {
    // Clean up any resources if needed
  }
} 