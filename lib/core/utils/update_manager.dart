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

  /// Gets the current update status
  Future<UpdateStatus> getUpdateStatus() async {
    try {
      debugPrint('🔍 Checking update status...');
      final status = await _updater.checkForUpdate();
      debugPrint('🔍 Current update status: $status');
      return status;
    } catch (e) {
      debugPrint('❌ Error getting update status: $e');
      return UpdateStatus.unavailable;
    }
  }

  /// Checks if the device supports Shorebird updates
  Future<bool> isUpdateAvailable() async {
    try {
      debugPrint('🔍 Checking for Shorebird updates...');
      final status = await _updater.checkForUpdate();
      debugPrint('🔍 Update status: $status');
      final hasUpdate = status == UpdateStatus.outdated || status == UpdateStatus.restartRequired;
      debugPrint('🔍 Has update available: $hasUpdate');
      return hasUpdate;
    } catch (e) {
      debugPrint('❌ Error checking for updates: $e');
      return false;
    }
  }

  /// Gets the current installed patch version
  Future<int?> getCurrentPatchVersion() async {
    try {
      debugPrint('🔍 Reading current patch version...');
      final patch = await _updater.readCurrentPatch();
      final patchNumber = patch?.number;
      debugPrint('🔍 Current patch: ${patchNumber ?? 'Base version (no patches)'}');
      return patchNumber;
    } catch (e) {
      debugPrint('❌ Error reading current patch: $e');
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
      debugPrint('📥 Starting update download...');
      await _updater.update();
      debugPrint('✅ Update download completed');
      
      if (!context.mounted) return;
      
      // Double-check that the update was actually downloaded
      final status = await getUpdateStatus();
      debugPrint('🔍 Status after download: $status');
      
      _hideCurrentBanner(context);
      
      if (status == UpdateStatus.restartRequired) {
        _showRestartBanner(context);
      } else {
        // Something went wrong with the download
        _showSnackBar(
          context,
          'Update may not have completed. Please try again.',
          backgroundColor: Colors.orange,
        );
      }
    } catch (e) {
      debugPrint('❌ Update download failed: $e');
      
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
    await Future.delayed(const Duration(seconds: 3));
    
    if (!context.mounted) return;
    
    await checkForUpdatesWithUI(
      context: context,
      showNoUpdateMessage: false,
    );
  }

  /// Check for updates silently and show a dismissible notification
  Future<void> checkForUpdatesBackground(BuildContext context) async {
    if (_isCheckingForUpdate) return;

    _isCheckingForUpdate = true;

    try {
      final hasUpdate = await isUpdateAvailable();
      
      if (!context.mounted) return;

      if (hasUpdate) {
        _showUpdateNotificationBanner(context);
      }
    } catch (e) {
      debugPrint('Background update check failed: $e');
    } finally {
      _isCheckingForUpdate = false;
    }
  }

  /// Auto-update flow with prominent dialog and auto-restart
  Future<void> checkForUpdatesOnStartupWithDialog(BuildContext context) async {
    if (_isCheckingForUpdate) return;

    _isCheckingForUpdate = true;

    try {
      // Wait longer for app to fully initialize and for any previous 
      // Shorebird patches to be properly applied
      await Future.delayed(const Duration(seconds: 4));
      
      if (!context.mounted) return;

      debugPrint('🔍 Checking update status on startup...');
      final status = await getUpdateStatus();
      debugPrint('🔍 Startup update status: $status');
      
      if (status == UpdateStatus.restartRequired) {
        debugPrint('🔄 Restart required - showing dialog');
        _showAutoRestartDialog(context);
      } else if (status == UpdateStatus.outdated) {
        debugPrint('📥 Update available - showing dialog');
        _showAutoUpdateDialog(context);
      } else {
        debugPrint('✅ No updates needed at startup');
      }
      // If no updates, don't show anything (silent)
    } catch (e) {
      debugPrint('❌ Auto-update check failed: $e');
    } finally {
      _isCheckingForUpdate = false;
    }
  }

  /// Shows dialog for auto-update with progress and auto-restart
  void _showAutoUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isDownloading = false;
            String statusText = 'A new update is available!';
            
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Icon(Icons.system_update, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  const Text('Update Available'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('SubTrackr has a new update with improvements and bug fixes.'),
                  const SizedBox(height: 16),
                  if (isDownloading) ...[
                    Text(statusText),
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text('Please wait...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ] else
                    const Text('Tap "Update Now" to download and apply the update.'),
                ],
              ),
              actions: [
                if (!isDownloading)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Later'),
                  ),
                ElevatedButton(
                  onPressed: isDownloading ? null : () async {
                    setDialogState(() {
                      isDownloading = true;
                      statusText = 'Downloading update...';
                    });
                    
                    try {
                      await _updater.update();
                      
                      if (context.mounted) {
                        setDialogState(() {
                          statusText = 'Update downloaded! Restarting app...';
                        });
                        
                        // Wait a moment to show the message
                        await Future.delayed(const Duration(seconds: 1));
                        
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          await _restartApp();
                        }
                      }
                    } catch (e) {
                      debugPrint('Auto-update failed: $e');
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        _showSnackBar(
                          context,
                          'Update failed. Please try again later.',
                          backgroundColor: Colors.red,
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isDownloading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Update Now'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Shows dialog when restart is required (patch already downloaded)
  void _showAutoRestartDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.restart_alt, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Update Ready'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('SubTrackr has been updated! The app needs to restart to apply the latest changes.'),
              SizedBox(height: 16),
              Text('This will only take a moment.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _restartApp();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Restart Now'),
            ),
          ],
        );
      },
    );
  }

  /// Shows a dismissible notification banner for updates
  void _showUpdateNotificationBanner(BuildContext context) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        content: Row(
          children: [
            Icon(
              Icons.new_releases,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'New patch available! Tap to update.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _hideCurrentBanner(context),
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Dismiss',
          ),
          TextButton(
            onPressed: () {
              _hideCurrentBanner(context);
              downloadUpdate(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
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
            onPressed: () async => await _restartApp(),
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

  /// Restarts the application with improved reliability
  Future<void> _restartApp() async {
    try {
      debugPrint('🔄 Initiating app restart...');
      
      // Give a small delay to ensure any pending operations complete
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Force a final status check before restart to ensure patch is ready
      final status = await getUpdateStatus();
      debugPrint('🔍 Final status before restart: $status');
      
      Restart.restartApp();
    } catch (e) {
      debugPrint('❌ Failed to restart app: $e');
      // Fallback: You might want to show a message asking user to manually restart
    }
  }

  /// Disposes resources
  void dispose() {
    // Clean up any resources if needed
  }
} 