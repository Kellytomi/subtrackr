import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/core/utils/currency_utils.dart';
import 'package:subtrackr/data/services/notification_service.dart';
import 'package:subtrackr/data/services/settings_service.dart';
import 'package:subtrackr/presentation/providers/subscription_provider.dart';
import 'package:subtrackr/presentation/providers/theme_provider.dart';
import 'package:subtrackr/core/utils/tips_helper.dart';
import 'package:subtrackr/data/services/auth_service.dart';
import 'package:subtrackr/data/services/cloud_sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TimeOfDay _notificationTime;
  late String _currencyCode;
  late bool _notificationsEnabled;
  late ThemeMode _themeMode;
  late String _sortOption;
  late bool _autoSyncEnabled;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isSyncing = false;
  
  @override
  void initState() {
    super.initState();
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    _notificationTime = settingsService.getNotificationTime();
    _currencyCode = settingsService.getCurrencyCode() ?? 'USD';
    _notificationsEnabled = settingsService.areNotificationsEnabled();
    _sortOption = settingsService.getSubscriptionSort();
    _autoSyncEnabled = settingsService.isAutoSyncEnabled();
    
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _themeMode = themeProvider.themeMode;
    
    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Get currency details
    final currency = CurrencyUtils.getCurrencyByCode(_currencyCode) ?? 
        CurrencyUtils.getAllCurrencies().first;
    


    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Clean Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 24,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // Settings Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // User Profile Section
                    _buildUserProfileSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Subscription Management
                    _buildModernSection(
                      title: 'Subscription Management',
                      icon: Icons.manage_accounts_rounded,
                      color: colorScheme.primary,
                      children: [
                        _buildModernTile(
                          title: 'Default Currency',
                          subtitle: '${currency.flag} ${currency.code} - ${currency.name}',
                          icon: Icons.currency_exchange_rounded,
                          iconColor: colorScheme.tertiary,
                          onTap: _showCurrencySelector,
                          trailing: Text(
                            currency.symbol,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.tertiary,
                            ),
                          ),
                        ),
                        _buildModernTile(
                          title: 'Sort Subscriptions',
                          subtitle: _getSortOptionText(_sortOption),
                          icon: Icons.sort_rounded,
                          iconColor: colorScheme.primary,
                          onTap: _showSortSelector,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _getSortOptionText(_sortOption),
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        _buildModernTile(
                          title: 'Auto-Categorization',
                          subtitle: 'Automatically categorize new subscriptions',
                          icon: Icons.auto_awesome_rounded,
                          iconColor: Colors.purple,
                          onTap: () {
                            // TODO: Implement auto-categorization settings
                            _showComingSoonSnackBar('Auto-categorization settings');
                          },
                          trailing: Switch(
                            value: true, // TODO: Connect to actual setting
                            onChanged: (value) {
                              // TODO: Implement toggle
                            },
                          ),
                        ),
                        _buildModernTile(
                          title: 'Price Alerts',
                          subtitle: 'Get notified about price changes',
                          icon: Icons.trending_up_rounded,
                          iconColor: Colors.orange,
                          onTap: () {
                            _showComingSoonSnackBar('Price alert settings');
                          },
                          trailing: Switch(
                            value: true, // TODO: Connect to actual setting
                            onChanged: (value) {
                              // TODO: Implement toggle
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Notifications & Reminders
                    _buildModernSection(
                      title: 'Notifications & Reminders',
                      icon: Icons.notifications_active_rounded,
                      color: Colors.blue,
                      children: [
                        _buildModernTile(
                          title: 'Renewal Notifications',
                          subtitle: _notificationsEnabled 
                              ? 'Enabled at ${_formatTimeOfDay(_notificationTime)}' 
                              : 'Disabled',
                          icon: Icons.notification_important_rounded,
                          iconColor: _notificationsEnabled ? Colors.blue : Colors.grey,
                          onTap: () {
                            if (_notificationsEnabled) {
                              _showTimePicker();
                            } else {
                              _toggleNotifications(!_notificationsEnabled);
                            }
                          },
                          trailing: Switch(
                            value: _notificationsEnabled,
                            onChanged: _toggleNotifications,
                          ),
                        ),
                        if (_notificationsEnabled)
                          _buildModernTile(
                            title: 'Notification Time',
                            subtitle: 'When to receive daily reminders',
                            icon: Icons.schedule_rounded,
                            iconColor: Colors.orange,
                            onTap: _showTimePicker,
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Text(
                                _formatTimeOfDay(_notificationTime),
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        _buildModernTile(
                          title: 'Smart Reminders',
                          subtitle: 'AI-powered renewal predictions',
                          icon: Icons.psychology_rounded,
                          iconColor: Colors.purple,
                          onTap: () {
                            _showComingSoonSnackBar('Smart reminders');
                          },
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.purple.withOpacity(0.3)),
                            ),
                            child: Text(
                              'BETA',
                              style: TextStyle(
                                color: Colors.purple.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Smart Features
                    _buildModernSection(
                      title: 'Smart Features',
                      icon: Icons.auto_awesome,
                      color: Colors.orange,
                      children: [
                        _buildModernTile(
                          title: 'Email Detection',
                          subtitle: 'Auto-detect subscriptions from Gmail',
                          icon: Icons.email_outlined,
                          iconColor: Colors.orange,
                          onTap: () {
                            Navigator.pushNamed(context, '/email-detection');
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Cloud Sync & Backup
                    _buildModernSection(
                      title: 'Cloud Sync & Backup',
                      icon: Icons.cloud_sync_rounded,
                      color: Colors.green,
                      children: [
                        _buildModernTile(
                          title: 'Sync Subscriptions',
                          subtitle: 'Manually sync your data with the cloud',
                          icon: Icons.sync_rounded,
                          iconColor: Colors.blue,
                          onTap: _syncWithCloud,
                          trailing: _isSyncing
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                  ),
                                )
                              : Icon(
                                  Icons.sync,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                        ),
                        _buildModernTile(
                          title: 'Auto Sync',
                          subtitle: _autoSyncEnabled 
                              ? 'Automatically sync when data changes'
                              : 'Manual sync only',
                          icon: Icons.sync_alt_rounded,
                          iconColor: _autoSyncEnabled ? Colors.green : Colors.grey,
                          onTap: () {
                            _toggleAutoSync(!_autoSyncEnabled);
                          },
                          trailing: Switch(
                            value: _autoSyncEnabled,
                            onChanged: _toggleAutoSync,
                          ),
                        ),

                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Appearance & Display
                    _buildModernSection(
                      title: 'Appearance & Display',
                      icon: Icons.palette_rounded,
                      color: Colors.teal,
                      children: [
                        _buildModernTile(
                          title: 'Theme',
                          subtitle: _getThemeModeText(_themeMode),
                          icon: _getThemeModeIcon(_themeMode),
                          iconColor: _getThemeModeColor(_themeMode, isDarkMode, colorScheme),
                          onTap: _showThemeSelector,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getThemeModeIcon(_themeMode),
                                  size: 16,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getThemeModeText(_themeMode),
                                  style: TextStyle(
                                    color: colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildModernTile(
                          title: 'Chart Style',
                          subtitle: 'Customize statistics appearance',
                          icon: Icons.bar_chart_rounded,
                          iconColor: Colors.green,
                          onTap: () {
                            _showComingSoonSnackBar('Chart customization');
                          },
                        ),
                        _buildModernTile(
                          title: 'Compact View',
                          subtitle: 'Show more subscriptions per screen',
                          icon: Icons.view_compact_rounded,
                          iconColor: Colors.indigo,
                          onTap: () {
                            _showComingSoonSnackBar('Compact view settings');
                          },
                          trailing: Switch(
                            value: false, // TODO: Connect to actual setting
                            onChanged: (value) {
                              // TODO: Implement toggle
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Help & Support
                    _buildModernSection(
                      title: 'Help & Support',
                      icon: Icons.help_center_rounded,
                      color: Colors.deepPurple,
                      children: [
                        _buildModernTile(
                          title: 'Tutorial & Tips',
                          subtitle: 'Learn how to use SubTrackr effectively',
                          icon: Icons.school_rounded,
                          iconColor: Colors.deepPurple,
                          onTap: _resetAppTips,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Danger Zone
                    _buildModernSection(
                      title: 'Danger Zone',
                      icon: Icons.warning_rounded,
                      color: Colors.red,
                      children: [
                        _buildModernTile(
                          title: 'Clear Cloud Data',
                          subtitle: 'Remove all data from cloud storage',
                          icon: Icons.cloud_off_rounded,
                          iconColor: Colors.red,
                          onTap: _clearCloudData,
                          trailing: Icon(
                            Icons.warning_rounded,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    
                    // Debug Tools (only in debug mode)
                    if (kDebugMode) ...[
                      const SizedBox(height: 24),
                      _buildModernSection(
                        title: 'Debug Tools',
                        icon: Icons.developer_mode_rounded,
                        color: Colors.red,
                        children: [
                          _buildModernTile(
                            title: 'Test Notifications',
                            subtitle: 'Send test notifications',
                            icon: Icons.bug_report_rounded,
                            iconColor: Colors.red,
                            onTap: () => _sendTestNotification(5),
                          ),

                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // App Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'SubTrackr',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Version 1.0.0',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Track your subscriptions with ease',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileSection() {
    return FutureBuilder<Map<String, String>?>(
      future: _getUserInfo(),
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isSignedIn = snapshot.hasData && snapshot.data!['email'] != null;
        final isCloudSyncEnabled = snapshot.hasData && snapshot.data!['isFirebaseSignedIn'] == 'true';
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withOpacity(0.1),
                colorScheme.secondary.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              // Profile Header
              Row(
                children: [
                  // Profile Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: isSignedIn && snapshot.data!['photoUrl'] != null
                          ? Image.network(
                              snapshot.data!['photoUrl']!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(snapshot, colorScheme),
                            )
                          : _buildAvatarFallback(snapshot, colorScheme),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Profile Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSignedIn ? snapshot.data!['name']! : 'Guest User',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isSignedIn ? snapshot.data!['email']! : 'Sign in to sync across devices',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Status Indicator
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCloudSyncEnabled 
                          ? Colors.green.withOpacity(0.1)
                          : isSignedIn 
                              ? Colors.orange.withOpacity(0.1)
                              : colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCloudSyncEnabled 
                            ? Colors.green.withOpacity(0.3)
                            : isSignedIn 
                                ? Colors.orange.withOpacity(0.3)
                                : colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Icon(
                      isCloudSyncEnabled
                          ? Icons.cloud_done_rounded
                          : isSignedIn
                              ? Icons.cloud_sync_rounded
                              : Icons.cloud_off_rounded,
                      color: isCloudSyncEnabled
                          ? Colors.green
                          : isSignedIn
                              ? Colors.orange
                              : colorScheme.outline,
                      size: 20,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Action Buttons
              if (!isSignedIn) ...[
                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _signInWithGoogle,
                    icon: const Icon(Icons.login, size: 20),
                    label: const Text('Sign In with Google'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Status Information
                Row(
                  children: [
                    // Email Access Status
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Email Access',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Connected',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Cloud Sync Status/Action
                    Expanded(
                      child: GestureDetector(
                        onTap: isCloudSyncEnabled ? null : _signInWithGoogle,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCloudSyncEnabled 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCloudSyncEnabled 
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.orange.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Cloud Sync',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isCloudSyncEnabled ? Colors.green : Colors.orange,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isCloudSyncEnabled ? 'Connected' : 'Tap to enable',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Sign Out Button at the bottom
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _showLogoutDialog,
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarFallback(AsyncSnapshot<Map<String, String>?> snapshot, ColorScheme colorScheme) {
    return Center(
      child: snapshot.hasData && snapshot.data!['name'] != null
          ? Text(
              snapshot.data!['name']!.split(' ').map((name) => name[0]).take(2).join().toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            )
          : const Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            ),
    );
  }

  Future<void> _showLogoutDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out? Your data will remain on this device, but cloud sync will be disabled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _signOut();
    }
  }

  Future<void> _signOut() async {
    try {
      final cloudSyncService = Provider.of<CloudSyncService>(context, listen: false);
      await cloudSyncService.signOut();
      
      setState(() {}); // Trigger rebuild
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Successfully signed out'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Error signing out: $error'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<Map<String, String>?> _getUserInfo() async {
    try {
      final authService = AuthService();
      final cloudSyncService = Provider.of<CloudSyncService>(context, listen: false);
      final googleUser = authService.currentUser;
      final firebaseUser = cloudSyncService.currentFirebaseUser;
      
      // Check Google user first, then fall back to Firebase user
      if (googleUser != null) {
        final result = <String, String>{
          'name': googleUser.displayName ?? 'User',
          'email': googleUser.email ?? '',
          'isGoogleSignedIn': 'true',
          'isFirebaseSignedIn': cloudSyncService.isUserSignedIn.toString(),
        };
        if (googleUser.photoUrl != null) {
          result['photoUrl'] = googleUser.photoUrl!;
        }
        return result;
      } else if (firebaseUser != null) {
        // Firebase user exists but Google user is null (due to type cast error)
        final result = <String, String>{
          'name': firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
          'email': firebaseUser.email ?? '',
          'isGoogleSignedIn': 'false', // Google sign-in had issues but auth worked
          'isFirebaseSignedIn': 'true',
        };
        if (firebaseUser.photoURL != null) {
          result['photoUrl'] = firebaseUser.photoURL!;
        }
        return result;
      }
    } catch (e) {
      debugPrint('Error getting user info: $e');
    }
    return null;
  }

  Future<void> _signInWithGoogle() async {
    try {
      final cloudSyncService = Provider.of<CloudSyncService>(context, listen: false);
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Signing in and enabling cloud sync...',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).primaryColor,
          duration: Duration(seconds: 10),
        ),
      );
      
      final success = await cloudSyncService.signInWithGoogle();
      
      // Clear the loading snackbar
      ScaffoldMessenger.of(context).clearSnackBars();
      
      if (success) {
        print('✅ Signed in successfully and linked to Firebase');
        
        // Wait a moment for all services to update their state
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          setState(() {}); // Trigger rebuild
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.cloud_done, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Successfully connected! Cloud sync is now enabled.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        print('❌ Sign in was cancelled or failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sign in was cancelled or failed',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (error) {
      print('❌ Error signing in: $error');
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Error signing in: $error',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _buildModernSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildModernTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing,
              ] else
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurface.withOpacity(0.4),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonSnackBar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.upcoming_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text('$feature coming soon!'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light mode';
      case ThemeMode.dark:
        return 'Dark mode';
    }
  }

  IconData _getThemeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
    }
  }

  Color _getThemeModeColor(ThemeMode mode, bool isDarkMode, ColorScheme colorScheme) {
    switch (mode) {
      case ThemeMode.system:
        return colorScheme.tertiary;
      case ThemeMode.light:
        return colorScheme.primary;
      case ThemeMode.dark:
        return colorScheme.secondary;
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _showThemeSelector() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    final result = await showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 16),
              child: Text(
                'Select Theme',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            _buildThemeOption(ThemeMode.system, 'System default', Icons.brightness_auto, colorScheme),
            const SizedBox(height: 8),
            _buildThemeOption(ThemeMode.light, 'Light mode', Icons.light_mode_rounded, colorScheme),
            const SizedBox(height: 8),
            _buildThemeOption(ThemeMode.dark, 'Dark mode', Icons.dark_mode_rounded, colorScheme),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _themeMode = result;
      });
      
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      await themeProvider.setThemeMode(result);
    }
  }

  Widget _buildThemeOption(ThemeMode mode, String title, IconData icon, ColorScheme colorScheme) {
    final isSelected = _themeMode == mode;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    Color iconColor;
    
    switch (mode) {
      case ThemeMode.system:
        iconColor = colorScheme.tertiary;
        break;
      case ThemeMode.light:
        iconColor = colorScheme.primary;
        break;
      case ThemeMode.dark:
        iconColor = colorScheme.secondary;
        break;
    }
    
    return InkWell(
      onTap: () {
        Navigator.pop(context, mode);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? iconColor : Colors.transparent,
            width: 1.5,
          ),
        ),
      child: Row(
        children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor),
            ),
          const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTimePicker() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final result = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            timePickerTheme: TimePickerThemeData(
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (result != null) {
      // Update local state
      setState(() {
        _notificationTime = result;
      });
      
      // Save to settings
      final settingsService = Provider.of<SettingsService>(context, listen: false);
      await settingsService.setNotificationTime(result);
      
      // Reschedule notifications with the new time
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      await subscriptionProvider.rescheduleAllNotifications();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notification time updated'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    await settingsService.setNotificationsEnabled(value);
    
    // Reschedule or cancel notifications based on the new setting
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    await subscriptionProvider.rescheduleAllNotifications();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Notifications enabled' : 'Notifications disabled'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _toggleAutoSync(bool value) async {
    setState(() {
      _autoSyncEnabled = value;
    });
    
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    await settingsService.setAutoSyncEnabled(value);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Auto sync enabled' : 'Auto sync disabled'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _getSortOptionText(String sortOption) {
    switch (sortOption) {
      case AppConstants.SORT_BY_DATE_ADDED:
        return 'Date Added';
      case AppConstants.SORT_BY_NAME:
        return 'Name';
      case AppConstants.SORT_BY_AMOUNT:
        return 'Amount';
      case AppConstants.SORT_BY_RENEWAL_DATE:
        return 'Renewal Date';
      default:
        return 'Date Added';
    }
  }

  Future<void> _showSortSelector() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Subscriptions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Date Added (Newest First)'),
              subtitle: const Text('Most recently added subscriptions first'),
              value: AppConstants.SORT_BY_DATE_ADDED,
              groupValue: _sortOption,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: const Text('Name (A-Z)'),
              subtitle: const Text('Alphabetical order'),
              value: AppConstants.SORT_BY_NAME,
              groupValue: _sortOption,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: const Text('Amount (Highest First)'),
              subtitle: const Text('By monthly cost'),
              value: AppConstants.SORT_BY_AMOUNT,
              groupValue: _sortOption,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: const Text('Renewal Date (Soonest First)'),
              subtitle: const Text('By next renewal date'),
              value: AppConstants.SORT_BY_RENEWAL_DATE,
              groupValue: _sortOption,
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );
    
    if (result != null && result != _sortOption) {
      setState(() {
        _sortOption = result;
      });
      
      final settingsService = Provider.of<SettingsService>(context, listen: false);
      await settingsService.setSubscriptionSort(result);
      
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      subscriptionProvider.resortSubscriptions();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sorting changed to ${_getSortOptionText(result)}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _showCurrencySelector() async {
    final result = await Navigator.push<Currency>(
      context,
      MaterialPageRoute(
        builder: (context) => CurrencySelectorScreen(initialCurrencyCode: _currencyCode),
      ),
    );
    
    if (result != null) {
      setState(() {
        _currencyCode = result.code;
      });
      
      final settingsService = Provider.of<SettingsService>(context, listen: false);
      await settingsService.setCurrencyCode(result.code);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Currency updated to ${result.name}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _sendTestNotification(int delaySeconds) async {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    if (delaySeconds == 0) {
      // Send immediate notification
      await notificationService.showTestNotification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Test notification sent immediately!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } else {
      // Schedule notification
      final scheduledDate = DateTime.now().add(Duration(seconds: delaySeconds));
      await notificationService.scheduleNotification(
        id: 9999,
        title: 'Test Notification',
        body: 'This test notification was scheduled for ${delaySeconds}s ago!',
        scheduledDate: scheduledDate,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test notification scheduled for ${delaySeconds}s from now!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _resetAppTips() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset App Tips',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: const Text(
          'This will reset all app tips and tutorials. You will see the first-time user guides again when you navigate through the app.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Reset Tips'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      await TipsHelper.resetAllTips();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('App tips have been reset'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // Cloud sync methods
  Future<void> _syncWithCloud() async {
    if (!mounted) return;
    
    setState(() {
      _isSyncing = true;
    });

    try {
      final cloudSyncService = Provider.of<CloudSyncService>(context, listen: false);
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      
      if (!cloudSyncService.isUserSignedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 8),
                Text('Please sign in with Google to sync'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }
      
      // Reload subscriptions to trigger sync
      await subscriptionProvider.loadSubscriptions();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.cloud_done, color: Colors.white),
              const SizedBox(width: 8),
              Text('Sync completed successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Sync failed: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _clearCloudData() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear Cloud Data',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: const Text(
          'This will permanently delete all your subscription data from cloud storage. Your local data will remain unchanged.\n\nThis action cannot be undone.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      try {
        final cloudSyncService = Provider.of<CloudSyncService>(context, listen: false);
        
        if (!cloudSyncService.isUserSignedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Please sign in with Google first'),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          return;
        }
        
        await cloudSyncService.clearCloudData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_off, color: Colors.white),
                const SizedBox(width: 8),
                Text('Cloud data cleared successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Failed to clear cloud data: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }


}

class CurrencySelectorScreen extends StatefulWidget {
  final String initialCurrencyCode;
  
  const CurrencySelectorScreen({
    super.key,
    required this.initialCurrencyCode,
  });

  @override
  State<CurrencySelectorScreen> createState() => _CurrencySelectorScreenState();
}

class _CurrencySelectorScreenState extends State<CurrencySelectorScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late List<Currency> _allCurrencies;
  late List<Currency> _filteredCurrencies;
  late String _selectedCurrencyCode;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _allCurrencies = CurrencyUtils.getAllCurrencies();
    _filteredCurrencies = List.from(_allCurrencies);
    _selectedCurrencyCode = widget.initialCurrencyCode;
    _searchController.addListener(_filterCurrencies);
    
    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_filterCurrencies);
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _filterCurrencies() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCurrencies = List.from(_allCurrencies);
      } else {
        _filteredCurrencies = _allCurrencies
            .where((currency) => 
                currency.code.toLowerCase().contains(query.toLowerCase()) ||
                currency.name.toLowerCase().contains(query.toLowerCase()) ||
                currency.symbol.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
        children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Select Currency',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            
            // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search currencies...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                  ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 1.5,
                    ),
                ),
                filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              onChanged: (value) => _filterCurrencies(),
            ),
          ),
            
            // Currency list
          Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
            child: ListView.builder(
              itemCount: _filteredCurrencies.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final currency = _filteredCurrencies[index];
                final isSelected = currency.code == _selectedCurrencyCode;
                
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      color: isSelected 
                          ? colorScheme.primary.withOpacity(0.1)
                          : theme.colorScheme.surface,
                      child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCurrencyCode = currency.code;
                    });
                    
                    // Return the selected currency to the previous screen
                    Navigator.pop(context, currency);
                  },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  currency.flag,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${currency.code} - ${currency.name}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Symbol: ${currency.symbol}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ),
          ),
        ],
        ),
      ),
    );
  }
} 