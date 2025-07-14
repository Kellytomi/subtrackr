import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/core/utils/currency_utils.dart';
import 'package:subtrackr/data/services/notification_service.dart';
import 'package:subtrackr/data/services/settings_service.dart';
import 'package:subtrackr/presentation/providers/subscription_provider.dart';
import 'package:subtrackr/presentation/providers/theme_provider.dart';
import 'package:subtrackr/core/utils/tips_helper.dart';
import 'package:subtrackr/data/services/supabase_cloud_sync_service.dart';
import 'package:subtrackr/data/services/supabase_auth_service.dart';
import 'package:subtrackr/data/repositories/dual_subscription_repository.dart';
import 'package:subtrackr/data/services/onesignal_service.dart';
import 'package:subtrackr/core/utils/update_manager.dart';
import 'package:restart_app/restart_app.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';


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
      duration: const Duration(milliseconds: 800),
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
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Get currency details
    final currency = CurrencyUtils.getCurrencyByCode(_currencyCode) ?? 
        CurrencyUtils.getAllCurrencies().first;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Modern app bar
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
        child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                      style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your preferences',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
                ),
              ),
            ),
            
            // Settings content
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                  children: [
                    // User Profile Section
                      _buildModernUserProfileSection(),
                    
                    const SizedBox(height: 24),
                    
                      // Quick Actions
                      _buildQuickActions(),
                      
                      const SizedBox(height: 32),
                      
                      // Settings sections
                      _buildSettingSection(
                        title: 'General',
                        icon: Icons.tune_rounded,
                      children: [
                          _buildSettingTile(
                            icon: Icons.palette_outlined,
                            title: 'Appearance',
                            subtitle: _getThemeModeText(_themeMode),
                            onTap: _showThemeSelector,
                            trailing: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getThemeModeIcon(_themeMode),
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ),
                          ),
                          _buildSettingTile(
                            icon: Icons.attach_money_rounded,
                          title: 'Default Currency',
                            subtitle: '${currency.name} (${currency.code})',
                          onTap: _showCurrencySelector,
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                            currency.symbol,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.tertiary,
                            ),
                          ),
                        ),
                          ),
                          _buildSettingTile(
                            icon: Icons.sort_rounded,
                          title: 'Sort Subscriptions',
                          subtitle: _getSortOptionText(_sortOption),
                          onTap: _showSortSelector,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                      _buildSettingSection(
                        title: 'Notifications',
                        icon: Icons.notifications_rounded,
                      children: [
                          _buildSettingTile(
                            icon: Icons.notification_important_outlined,
                            title: 'Renewal Reminders',
                          subtitle: _notificationsEnabled 
                                ? 'Get notified before renewals' 
                                : 'Notifications disabled',
                            onTap: () => _toggleNotifications(!_notificationsEnabled),
                          trailing: Switch(
                            value: _notificationsEnabled,
                            onChanged: _toggleNotifications,
                              activeColor: colorScheme.primary,
                          ),
                        ),
                        if (_notificationsEnabled)
                            _buildSettingTile(
                              icon: Icons.access_time_rounded,
                            title: 'Notification Time',
                              subtitle: 'Daily at ${_formatTimeOfDay(_notificationTime)}',
                            onTap: _showTimePicker,
                            trailing: Container(
                                padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                              ),
                                child: Icon(
                                  Icons.schedule,
                                  color: Colors.orange,
                                  size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                      _buildSettingSection(
                        title: 'Cloud & Backup',
                        icon: Icons.cloud_rounded,
                      children: [
                          _buildSettingTile(
                            icon: Icons.cloud_sync_outlined,
                            title: 'Auto Backup',
                            subtitle: _autoSyncEnabled 
                                ? 'Changes are backed up automatically'
                                : 'Manual backup only',
                            onTap: () => _toggleAutoSync(!_autoSyncEnabled),
                            trailing: Switch(
                              value: _autoSyncEnabled,
                              onChanged: _toggleAutoSync,
                              activeColor: Colors.green,
                            ),
                          ),
                          _buildSettingTile(
                          icon: Icons.sync_rounded,
                            title: 'Sync Now',
                            subtitle: 'Manually sync with cloud',
                          onTap: _syncWithCloud,
                          trailing: _isSyncing
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  Icons.sync,
                                    color: colorScheme.primary,
                                  size: 20,
                                ),
                        ),
                          _buildSettingTile(
                            icon: Icons.cloud_download_outlined,
                          title: 'Restore Backup',
                            subtitle: 'Replace local data with cloud',
                          onTap: _restoreFromCloud,
                            trailing: const Icon(
                              Icons.download,
                              color: Colors.purple,
                              size: 20,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                      _buildSettingSection(
                        title: 'Smart Features',
                        icon: Icons.auto_awesome,
                      children: [
                          _buildSettingTile(
                            icon: Icons.email_outlined,
                            title: 'Email Detection',
                            subtitle: 'Auto-detect subscriptions from Gmail',
                            onTap: () => Navigator.pushNamed(context, '/email-detection'),
                          trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.orange, Colors.deepOrange],
                                ),
                                borderRadius: BorderRadius.circular(8),
                            ),
                              child: const Text(
                                'NEW',
                                  style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                      _buildSettingSection(
                        title: 'Help & About',
                        icon: Icons.help_outline_rounded,
                      children: [
                          _buildSettingTile(
                            icon: Icons.school_outlined,
                          title: 'Tutorial & Tips',
                            subtitle: 'Learn how to use SubTrackr',
                          onTap: _resetAppTips,
                        ),
                          _buildSettingTile(
                            icon: Icons.info_outline,
                            title: 'About SubTrackr',
                            subtitle: 'Version & update info',
                            onTap: _showAboutDialog,
                        ),
                      ],
                    ),
                    
                      // Debug section (only in debug mode)
                      if (kDebugMode) ...[
                        const SizedBox(height: 24),
                        _buildSettingSection(
                          title: 'Debug Tools',
                          icon: Icons.bug_report,
                          children: [
                            _buildSettingTile(
                              icon: Icons.notifications_active,
                              title: 'Test Local Notification',
                              subtitle: 'Send a test subscription reminder',
                              onTap: () => _sendTestNotification(5),
                            ),
                            _buildSettingTile(
                              icon: Icons.campaign_outlined,
                              title: 'Test Push Notification',
                              subtitle: 'Get OneSignal Player ID for testing',
                              onTap: _testOneSignalNotification,
                            ),
                      ],
                    ),
                      ],
                    
                    const SizedBox(height: 24),
                    
                    // Danger Zone
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.withOpacity(0.1),
                              Colors.orange.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                            Icons.warning_rounded,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Danger Zone',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: _deleteAccountAndData,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                        children: [
                                    Icon(
                                      Icons.delete_forever,
                                      color: Colors.red.shade700,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Delete Account & Data',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.red.shade700,
                          ),
                      ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Permanently delete everything',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.red.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.red.shade700,
                                    ),
                      ],
                                ),
                              ),
                            ),
                          ],
                        ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernUserProfileSection() {
    return FutureBuilder<Map<String, String>?>(
      future: _getUserInfo(),
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;
        final isSignedIn = snapshot.hasData && snapshot.data!['email'] != null;
        final isCloudSyncEnabled = snapshot.hasData && snapshot.data!['isSupabaseSignedIn'] == 'true';
        
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [const Color(0xFF1E1E1E), const Color(0xFF2D2D2D)]
                  : [Colors.white, const Color(0xFFF8F9FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
            ),
            ],
          ),
          child: Column(
            children: [
              // Profile info
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: isSignedIn && snapshot.data!['photoUrl'] != null
                          ? Image.network(
                              snapshot.data!['photoUrl']!,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                  _buildAvatarFallback(snapshot, theme.colorScheme),
                            )
                          : _buildAvatarFallback(snapshot, theme.colorScheme),
                    ),
                  ),
                  const SizedBox(width: 20),
                  
                  // User info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                isSignedIn ? snapshot.data!['name']! : 'Guest User',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSignedIn) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _showEditNameDialog(snapshot.data!['name']!),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                  Icons.edit,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isSignedIn ? snapshot.data!['email']! : 'Sign in to sync',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Sync status
                  Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCloudSyncEnabled 
                          ? Colors.green.withOpacity(0.1)
                          : isSignedIn 
                              ? Colors.orange.withOpacity(0.1)
                                    : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCloudSyncEnabled 
                            ? Colors.green.withOpacity(0.3)
                            : isSignedIn 
                                ? Colors.orange.withOpacity(0.3)
                                      : theme.colorScheme.outline.withOpacity(0.2),
                              width: 1,
                      ),
                    ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                      isCloudSyncEnabled
                                    ? Icons.cloud_done
                          : isSignedIn
                                        ? Icons.cloud_sync
                                        : Icons.cloud_off,
                      color: isCloudSyncEnabled
                          ? Colors.green
                          : isSignedIn
                              ? Colors.orange
                                        : theme.colorScheme.outline,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isCloudSyncEnabled
                                    ? 'Cloud sync active'
                                    : isSignedIn
                                        ? 'Email access only'
                                        : 'Offline mode',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isCloudSyncEnabled
                                      ? Colors.green
                                      : isSignedIn
                                          ? Colors.orange
                                          : theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Action button
              if (!isSignedIn) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _signInWithGoogle,
                    icon: Image.asset(
                      'assets/logos/google.png',
                      width: 20,
                      height: 20,
                      errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.login, size: 20),
                    ),
                    label: const Text('Sign in with Google'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ] else if (!isCloudSyncEnabled) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _signInWithGoogle,
                    icon: const Icon(Icons.cloud_sync, size: 20),
                    label: const Text('Enable Cloud Sync'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                      ),
                          ),
                        ),
                            ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
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

    Widget _buildQuickActions() {
    // Both buttons moved to their respective sections - Quick Actions no longer needed
    return const SizedBox.shrink();
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
                    ),
                  ],
                ),
        child: Column(
            children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
          ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      );
  }

  Widget _buildSettingSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(
                  icon,
                size: 20,
                color: theme.colorScheme.primary,
                ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
            ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
              padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                color: theme.colorScheme.primary,
                size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            if (trailing != null)
              trailing
            else
                Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
            ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(AsyncSnapshot<Map<String, String>?> snapshot, ColorScheme colorScheme) {
    return Center(
      child: snapshot.hasData && snapshot.data!['name'] != null
          ? Text(
              snapshot.data!['name']!.split(' ').map((name) => name[0]).take(2).join().toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            )
          : const Icon(
              Icons.person,
              color: Colors.white,
              size: 36,
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

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
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

  // Show theme selector with modern design
  Future<void> _showThemeSelector() async {
    final theme = Theme.of(context);
    
    final result = await showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
        child: Padding(
          padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Choose Theme',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildThemeOption(
                ThemeMode.system,
                'System default',
                'Follow device theme',
                Icons.brightness_auto,
              ),
              const SizedBox(height: 12),
              _buildThemeOption(
                ThemeMode.light,
                'Light mode',
                'Always use light theme',
                Icons.light_mode_rounded,
              ),
              const SizedBox(height: 12),
              _buildThemeOption(
                ThemeMode.dark,
                'Dark mode',
                'Always use dark theme',
                Icons.dark_mode_rounded,
              ),
              const SizedBox(height: 24),
          ],
          ),
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

  Widget _buildThemeOption(
    ThemeMode mode,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isSelected = _themeMode == mode;
    
    return InkWell(
      onTap: () => Navigator.pop(context, mode),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
      child: Row(
        children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
              ),
            ),
          const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Text(
              title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
              ),
            ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
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
    );
  }

  // Show sort selector with modern design
  Future<void> _showSortSelector() async {
    final theme = Theme.of(context);
    
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
              ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Sort Subscriptions By',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildSortOption(
                AppConstants.SORT_BY_DATE_ADDED,
                'Date Added',
                'Newest first',
                Icons.calendar_today,
              ),
              const SizedBox(height: 12),
              _buildSortOption(
                AppConstants.SORT_BY_NAME,
                'Name',
                'Alphabetical order',
                Icons.sort_by_alpha,
              ),
              const SizedBox(height: 12),
              _buildSortOption(
                AppConstants.SORT_BY_AMOUNT,
                'Amount',
                'Highest cost first',
                Icons.attach_money,
              ),
              const SizedBox(height: 12),
              _buildSortOption(
                AppConstants.SORT_BY_RENEWAL_DATE,
                'Renewal Date',
                'Soonest first',
                Icons.event,
          ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _buildSortOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isSelected = _sortOption == value;
    
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
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
    );
  }

  // Currency selector
  Future<void> _showCurrencySelector() async {
    final result = await Navigator.push<Currency>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            ModernCurrencySelectorScreen(initialCurrencyCode: _currencyCode),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.ease;
          
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
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
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  }

  // Time picker
  Future<void> _showTimePicker() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (result != null) {
    setState(() {
        _notificationTime = result;
    });
    
    final settingsService = Provider.of<SettingsService>(context, listen: false);
      await settingsService.setNotificationTime(result);
      
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      await subscriptionProvider.rescheduleAllNotifications();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: const Text('Notification time updated'),
        behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  }

  // Show about dialog
  Future<void> _showAboutDialog() async {
    final theme = Theme.of(context);
    final versionInfo = await _getVersionInfo();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.subscriptions_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('SubTrackr'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${versionInfo['appVersion']}',
              style: theme.textTheme.bodyLarge,
            ),
            if (versionInfo['hasPatch'] == true && versionInfo['patchNumber'] != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Patch #${versionInfo['patchNumber']} applied',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text('Track your subscriptions with ease'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _checkForUpdates,
                icon: const Icon(Icons.update, size: 18),
                label: const Text('Check for Updates'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            // Debug button for testing auto-update functionality
            if (kDebugMode) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _debugAutoUpdate,
                  icon: const Icon(Icons.bug_report, size: 18),
                  label: const Text('Debug Auto-Update'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
    
  // All the method implementations from the original file
  Future<void> _toggleNotifications(bool value) async {
      setState(() {
      _notificationsEnabled = value;
      });
      
      final settingsService = Provider.of<SettingsService>(context, listen: false);
    await settingsService.setNotificationsEnabled(value);
      
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    await subscriptionProvider.rescheduleAllNotifications();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
        content: Text(value ? 'Notifications enabled' : 'Notifications disabled'),
          behavior: SnackBarBehavior.floating,
        backgroundColor: value ? Colors.green : Colors.orange,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        content: Text(value ? 'Auto backup enabled' : 'Auto backup disabled'),
          behavior: SnackBarBehavior.floating,
        backgroundColor: value ? Colors.green : Colors.orange,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

  Future<Map<String, String>?> _getUserInfo() async {
    try {
      final authService = SupabaseAuthService();
      final cloudSyncService = Provider.of<SupabaseCloudSyncService>(context, listen: false);
      final googleUser = authService.currentUser;
      final supabaseUser = cloudSyncService.currentUser;
      
      if (googleUser != null) {
        final manualName = googleUser.userMetadata?['full_name']?.toString();
        final googleName = googleUser.userMetadata?['name']?.toString();
        final fallbackName = googleUser.email?.split('@')[0] ?? 'User';
        
        return {
          'name': manualName ?? googleName ?? fallbackName,
          'email': googleUser.email ?? '',
          'photoUrl': googleUser.userMetadata?['avatar_url']?.toString() ?? '',
          'isSupabaseSignedIn': 'true',
        };
      } else if (supabaseUser != null) {
        final manualName = supabaseUser.userMetadata?['full_name']?.toString();
        final googleName = supabaseUser.userMetadata?['name']?.toString();
        final fallbackName = supabaseUser.email?.split('@')[0] ?? 'User';
        
        return {
          'name': manualName ?? googleName ?? fallbackName,
          'email': supabaseUser.email ?? '',
          'photoUrl': supabaseUser.userMetadata?['avatar_url']?.toString() ?? '',
          'isSupabaseSignedIn': 'true',
        };
      }
      
      return null;
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final cloudSyncService = Provider.of<SupabaseCloudSyncService>(context, listen: false);
    
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Signing in and enabling cloud sync...',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).primaryColor,
          duration: const Duration(seconds: 10),
        ),
      );
      
      final success = await cloudSyncService.signInWithGoogle();
      
      ScaffoldMessenger.of(context).clearSnackBars();
      
      if (success) {
      if (mounted) {
          final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
          await subscriptionProvider.startRealTimeSync();
          await subscriptionProvider.loadSubscriptions();
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            setState(() {});
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.cloud_done, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Successfully connected! Real-time sync is now active.'),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
          }
      }
    } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Sign in was cancelled or failed'),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
      );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Error signing in: $error'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
    }
  }

  Future<void> _showLogoutDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
      final cloudSyncService = Provider.of<SupabaseCloudSyncService>(context, listen: false);
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      
      subscriptionProvider.stopRealTimeSync();
      await cloudSyncService.signOut();
      
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Successfully signed out'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Error signing out: $error'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _syncWithCloud() async {
    if (!mounted) return;
    
    setState(() {
      _isSyncing = true;
    });

    try {
      final cloudSyncService = Provider.of<SupabaseCloudSyncService>(context, listen: false);
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      
      if (!cloudSyncService.isUserSignedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Text('Please sign in with Google to sync'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }
      
      await subscriptionProvider.loadSubscriptions();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.cloud_done, color: Colors.white),
              SizedBox(width: 8),
              Text('Sync completed successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Sync failed: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Future<void> _restoreFromCloud() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Restore from Cloud'),
        content: const Text('This will replace all your local subscriptions with data from your cloud backup. Local changes that haven\'t been backed up will be lost.\n\nAre you sure you want to continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      try {
        final cloudSyncService = Provider.of<SupabaseCloudSyncService>(context, listen: false);
        final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
        
        if (!cloudSyncService.isUserSignedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Please sign in with Google to restore'),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          return;
        }
        
        final repository = Provider.of<DualSubscriptionRepository>(context, listen: false);
        final cloudSubscriptions = await repository.getAllSubscriptions();
        
        await subscriptionProvider.restoreFromBackup(cloudSubscriptions);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cloud_done, color: Colors.white),
                const SizedBox(width: 8),
                Text('Successfully restored ${cloudSubscriptions.length} subscriptions from backup'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Restore failed: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _sendTestNotification(int delaySeconds) async {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    if (delaySeconds == 0) {
      await notificationService.showTestNotification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Test notification sent immediately!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else {
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
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _testOneSignalNotification() async {
    try {
      final userId = await OneSignalService.getUserId();
      final hasPermission = await OneSignalService.hasPermission();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.campaign, color: Colors.blue),
              SizedBox(width: 8),
              Text('OneSignal Test Info'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Permission: ${hasPermission ? "✅ Granted" : "❌ Denied"}'),
              const SizedBox(height: 8),
              const Text('Player ID:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              SelectableText(
                userId ?? 'Not available',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Text(
                'To test push notifications:\n'
                '1. Copy the Player ID above\n'
                '2. Go to OneSignal dashboard\n'
                '3. Send test message to this Player ID',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                if (userId != null) {
                  Clipboard.setData(ClipboardData(text: userId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Player ID copied to clipboard')),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('Copy ID'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OneSignal test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _debugAutoUpdate() async {
    try {
      final updateManager = UpdateManager();
      
      // Test the auto-update flow manually
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.bug_report, color: Colors.orange),
              SizedBox(width: 8),
              Text('Debug Auto-Update'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Testing auto-update flow...'),
            ],
          ),
        ),
      );

      // Call the same method that runs on app startup
      await updateManager.checkForUpdatesOnStartupWithDialog(context);
      
      if (mounted) Navigator.of(context).pop();
      
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debug auto-update failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resetAppTips() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reset App Tips'),
        content: const Text('This will reset all app tips and tutorials. You will see the first-time user guides again when you navigate through the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _deleteAccountAndData() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Delete Account & Data',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: const Text(
          '⚠️ This will permanently:\n\n'
          '• Delete your account\n'
          '• Remove ALL subscription data from cloud\n'
          '• Clear ALL local data\n'
          '• Sign you out from this device\n\n'
          '⚠️ IMPORTANT: Other devices may remain signed in until you manually sign out or the session expires.\n\n'
          'This action cannot be undone!',
        ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      try {
        final cloudSyncService = Provider.of<SupabaseCloudSyncService>(context, listen: false);
        final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
        
        if (!cloudSyncService.isUserSignedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in to delete account'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Deleting account and all data...',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
        
        subscriptionProvider.stopRealTimeSync();
        await cloudSyncService.deleteAccount();
        
        ScaffoldMessenger.of(context).clearSnackBars();
        
        if (mounted) {
          setState(() {});
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Account and all data deleted successfully.'),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEditNameDialog(String currentName) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _EditNameDialog(currentName: currentName),
    );

    if (result != null && result != currentName) {
      await _updateUserName(result);
    }
  }

  Future<void> _updateUserName(String newName) async {
      try {
      final response = await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {'full_name': newName},
            ),
          );

      if (response.user != null) {
        if (mounted) {
          setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Name updated to $newName'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        }
      } else {
        throw Exception('Failed to update user profile');
      }
      } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating name: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _getVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final updateManager = UpdateManager();
      final patchInfo = await updateManager.getPatchInfo();
      
      return {
        'appVersion': '${packageInfo.version}+${packageInfo.buildNumber}',
        'patchNumber': patchInfo['patchNumber'],
        'updateStatus': (patchInfo['hasPatch'] as bool?) == true ? 'Patched' : 'Base Version',
        'hasPatch': (patchInfo['hasPatch'] as bool?) ?? false,
        'hasUpdate': (patchInfo['hasUpdate'] as bool?) ?? false,
      };
    } catch (e) {
      return {
        'appVersion': '1.0.5+7',
        'patchNumber': null,
        'updateStatus': 'Unknown',
        'hasPatch': false,
        'hasUpdate': false,
      };
    }
  }

  Future<void> _checkForUpdates() async {
    final updateManager = UpdateManager();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.system_update, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Checking for Updates'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking for available patches...'),
            ],
          ),
        );
      },
    );

    try {
      final status = await updateManager.getUpdateStatus();
      
      if (mounted) Navigator.of(context).pop();
      
      if (status == UpdateStatus.restartRequired) {
        _showRestartRequiredDialog();
      } else if (status == UpdateStatus.outdated) {
        _showUpdateAvailableDialog();
      } else {
        _showNoUpdatesDialog();
      }
    } catch (error) {
      if (mounted) Navigator.of(context).pop();
      _showUpdateErrorDialog(error.toString());
    }
  }

  void _showUpdateAvailableDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isDownloading = false;
            
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.new_releases, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Patch Available'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('A new patch for SubTrackr is available!'),
                  const SizedBox(height: 16),
                  if (isDownloading) ...[
                    const Text('Downloading patch...'),
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text('This may take a moment'),
                  ] else
                    const Text('Tap "Update Now" to download and apply the patch instantly.'),
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
                    });
                    
                    try {
                      final updateManager = UpdateManager();
                      await updateManager.downloadUpdate(context);
                      
                      if (mounted) Navigator.of(context).pop();
                      _showUpdateCompleteDialog();
                    } catch (e) {
                      if (mounted) Navigator.of(context).pop();
                      _showUpdateErrorDialog('Failed to download patch: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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

  void _showNoUpdatesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Up to Date'),
            ],
          ),
          content: FutureBuilder<Map<String, dynamic>>(
            future: _getVersionInfo(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text('Checking version info...');
              }
              
              final versionData = snapshot.data ?? {};
              final hasPatch = (versionData['hasPatch'] as bool?) ?? false;
              final patchNumber = versionData['patchNumber'];
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('You are using the latest version of SubTrackr!'),
                  const SizedBox(height: 8),
                  if (hasPatch && patchNumber != null)
                    Text(
                      'Current patch: #$patchNumber',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    )
                  else
                    const Text(
                      'Base version (no patches applied)',
                      style: TextStyle(color: Colors.grey),
                    ),
                ],
              );
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Update Check Failed'),
            ],
          ),
          content: Text('Failed to check for updates: $error'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.download_done, color: Colors.green),
              SizedBox(width: 8),
              Text('Patch Applied'),
            ],
          ),
          content: const Text('SubTrackr has been patched successfully! Restart the app to see the latest changes.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Patch applied! Restart manually when convenient.'),
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Restart.restartApp();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
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

  void _showRestartRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
        children: [
              Icon(Icons.restart_alt, color: Colors.orange),
              SizedBox(width: 8),
              Text('Update Ready'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              Text('A patch has been downloaded and is ready to apply!'),
              SizedBox(height: 16),
              Text('The app needs to restart to apply the latest updates.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Restart.restartApp();
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
}

// Modern Currency Selector Screen
class ModernCurrencySelectorScreen extends StatefulWidget {
  final String initialCurrencyCode;
  
  const ModernCurrencySelectorScreen({
    super.key,
    required this.initialCurrencyCode,
  });

  @override
  State<ModernCurrencySelectorScreen> createState() => _ModernCurrencySelectorScreenState();
}

class _ModernCurrencySelectorScreenState extends State<ModernCurrencySelectorScreen> {
  final TextEditingController _searchController = TextEditingController();
  late List<Currency> _allCurrencies;
  late List<Currency> _filteredCurrencies;
  late String _selectedCurrencyCode;
  
  @override
  void initState() {
    super.initState();
    _allCurrencies = CurrencyUtils.getAllCurrencies();
    _filteredCurrencies = List.from(_allCurrencies);
    _selectedCurrencyCode = widget.initialCurrencyCode;
    _searchController.addListener(_filterCurrencies);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_filterCurrencies);
    _searchController.dispose();
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
                currency.code.toLowerCase().contains(query) ||
                currency.name.toLowerCase().contains(query) ||
                currency.symbol.toLowerCase().contains(query))
            .toList();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
        children: [
                  IconButton(
                    icon: Icon(
                          Icons.arrow_back,
                          color: theme.colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                  Text(
                    'Select Currency',
                              style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_allCurrencies.length} currencies available',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
                    ],
                  ),
                  const SizedBox(height: 20),
            // Search bar
                  TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search currencies...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: isDarkMode 
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
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
                          color: theme.colorScheme.primary,
                          width: 2,
                    ),
                ),
              ),
                  ),
                ],
            ),
          ),
            
            // Currency list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCurrencies.length,
                padding: const EdgeInsets.symmetric(horizontal: 24),
              itemBuilder: (context, index) {
                final currency = _filteredCurrencies[index];
                final isSelected = currency.code == _selectedCurrencyCode;
                
                  return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                      color: isSelected 
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                      child: InkWell(
                      onTap: () => Navigator.pop(context, currency),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                              width: 48,
                              height: 48,
                                decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              child: Center(
                                child: Text(
                                  currency.flag,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                    currency.name,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                    '${currency.code} • ${currency.symbol}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
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
        ],
        ),
      ),
    );
  }
}

class _EditNameDialog extends StatefulWidget {
  final String currentName;

  const _EditNameDialog({required this.currentName});

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Edit Name'),
      content: TextField(
        controller: _nameController,
        decoration: InputDecoration(
          hintText: 'Enter your name',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _nameController.text),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
} 