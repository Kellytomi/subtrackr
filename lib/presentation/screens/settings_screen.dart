import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/core/utils/currency_utils.dart';
import 'package:subtrackr/core/widgets/custom_app_bar.dart';
import 'package:subtrackr/data/services/notification_service.dart';
import 'package:subtrackr/data/services/settings_service.dart';
import 'package:subtrackr/presentation/blocs/subscription_provider.dart';
import 'package:subtrackr/presentation/blocs/theme_provider.dart';
import 'package:subtrackr/presentation/screens/add_subscription_screen.dart';
import 'package:subtrackr/presentation/screens/onboarding/currency_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TimeOfDay _notificationTime;
  late String _currencyCode;
  late bool _notificationsEnabled;
  late ThemeMode _themeMode;
  
  @override
  void initState() {
    super.initState();
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    _notificationTime = settingsService.getNotificationTime();
    _currencyCode = settingsService.getCurrencyCode() ?? 'USD';
    _notificationsEnabled = settingsService.areNotificationsEnabled();
    
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _themeMode = themeProvider.themeMode;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Get currency details
    final currency = CurrencyUtils.getCurrencyByCode(_currencyCode) ?? 
        CurrencyUtils.getAllCurrencies().first;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Settings list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Notifications section
                  _buildSectionHeader('Notifications', Icons.notifications, colorScheme),
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surface,
                    child: SwitchListTile(
                      title: Text(
                        'Enable Notifications',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white 
                              : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        'Get reminders for upcoming renewals',
                        style: TextStyle(
                          color: (Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white 
                              : Colors.black).withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                      value: _notificationsEnabled,
                      onChanged: _toggleNotifications,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white 
                              : Colors.black).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                          color: _notificationsEnabled 
                              ? colorScheme.primary 
                              : Colors.grey,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                  
                  if (_notificationsEnabled) ...[
                    const SizedBox(height: 16),
                    _buildSettingCard(
                      title: 'Notification Time',
                      subtitle: _formatTimeOfDay(_notificationTime),
                      icon: Icons.access_time,
                      iconColor: colorScheme.primary,
                      onTap: _showTimePicker,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 16),
                    _buildSettingCard(
                      title: 'Test Notification',
                      subtitle: 'Send a test notification to verify settings',
                      icon: Icons.send,
                      iconColor: colorScheme.tertiary,
                      onTap: _sendTestNotification,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 16),
                    _buildSettingCard(
                      title: 'Notification Test Screen',
                      subtitle: 'Advanced notification testing options',
                      icon: Icons.notifications_active,
                      iconColor: colorScheme.secondary,
                      onTap: () {
                        Navigator.pushNamed(context, AppConstants.notificationTestRoute);
                      },
                      colorScheme: colorScheme,
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Currency section
                  _buildSectionHeader('Currency', Icons.attach_money, colorScheme),
                  _buildSettingCard(
                    title: 'Default Currency',
                    subtitle: '${currency.flag} ${currency.code} - ${currency.name} (${currency.symbol})',
                    icon: Icons.currency_exchange,
                    iconColor: colorScheme.tertiary,
                    onTap: _showCurrencySelector,
                    colorScheme: colorScheme,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Data management section
                  _buildSectionHeader('Data Management', Icons.storage, colorScheme),
                  _buildSettingCard(
                    title: 'Export Data',
                    subtitle: 'Export your subscriptions as JSON',
                    icon: Icons.file_download,
                    iconColor: colorScheme.primary,
                    onTap: () {
                      // TODO: Implement export functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Export functionality coming soon')),
                      );
                    },
                    colorScheme: colorScheme,
                  ),
                  _buildSettingCard(
                    title: 'Import Data',
                    subtitle: 'Import subscriptions from JSON',
                    icon: Icons.file_upload,
                    iconColor: colorScheme.secondary,
                    onTap: () {
                      // TODO: Implement import functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Import functionality coming soon')),
                      );
                    },
                    colorScheme: colorScheme,
                  ),
                  _buildSettingCard(
                    title: 'Clear All Data',
                    subtitle: 'Delete all subscriptions and reset settings',
                    icon: Icons.delete_forever,
                    iconColor: Colors.red,
                    onTap: _showClearDataConfirmation,
                    colorScheme: colorScheme,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // About section
                  _buildSectionHeader('About', Icons.info, colorScheme),
                  _buildSettingCard(
                    title: 'Version',
                    subtitle: AppConstants.appVersion,
                    icon: Icons.android,
                    iconColor: colorScheme.tertiary,
                    onTap: null,
                    colorScheme: colorScheme,
                  ),
                  _buildSettingCard(
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy policy',
                    icon: Icons.privacy_tip,
                    iconColor: colorScheme.primary,
                    onTap: () {
                      // TODO: Open privacy policy
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy policy coming soon')),
                      );
                    },
                    colorScheme: colorScheme,
                  ),
                  _buildSettingCard(
                    title: 'Terms of Service',
                    subtitle: 'Read our terms of service',
                    icon: Icons.description,
                    iconColor: colorScheme.secondary,
                    onTap: () {
                      // TODO: Open terms of service
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Terms of service coming soon')),
                      );
                    },
                    colorScheme: colorScheme,
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 8),
      child: Row(
        children: [
          Icon(
            icon, 
            size: 20, 
            color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback? onTap,
    required ColorScheme colorScheme,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      color: theme.colorScheme.surface,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
            fontSize: 13,
          ),
        ),
        trailing: onTap != null 
            ? Icon(
                Icons.chevron_right, 
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.5)
              ) 
            : null,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
        return Icons.brightness_7;
      case ThemeMode.dark:
        return Icons.brightness_3;
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
    final result = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Theme'),
        children: [
          _buildThemeOption(ThemeMode.system, 'System default', Icons.brightness_auto),
          _buildThemeOption(ThemeMode.light, 'Light mode', Icons.brightness_7),
          _buildThemeOption(ThemeMode.dark, 'Dark mode', Icons.brightness_3),
        ],
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

  Widget _buildThemeOption(ThemeMode mode, String title, IconData icon) {
    return SimpleDialogOption(
      onPressed: () {
        Navigator.pop(context, mode);
      },
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 16),
          Text(title),
          if (_themeMode == mode) ...[
            const Spacer(),
            Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
          ],
        ],
      ),
    );
  }

  Future<void> _showTimePicker() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );
    
    if (result != null) {
      setState(() {
        _notificationTime = result;
      });
      
      final settingsService = Provider.of<SettingsService>(context, listen: false);
      await settingsService.setNotificationTime(result);
      
      // Reschedule notifications with the new time
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      await subscriptionProvider.rescheduleAllNotifications();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification time updated')),
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
      ),
    );
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
        SnackBar(content: Text('Currency updated to ${result.name}')),
      );
    }
  }

  Future<void> _sendTestNotification() async {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    await notificationService.showTestNotification();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test notification sent')),
    );
  }

  Future<void> _showClearDataConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to delete all subscriptions and reset settings? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text(
              'Clear All Data',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    
    if (result == true) {
      // TODO: Implement clear all data functionality
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared')),
      );
    }
  }
}

class CurrencySelectorScreen extends StatefulWidget {
  final String initialCurrencyCode;
  
  const CurrencySelectorScreen({
    Key? key,
    required this.initialCurrencyCode,
  }) : super(key: key);

  @override
  State<CurrencySelectorScreen> createState() => _CurrencySelectorScreenState();
}

class _CurrencySelectorScreenState extends State<CurrencySelectorScreen> {
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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Currency'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search currencies...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              onChanged: (value) => _filterCurrencies(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCurrencies.length,
              itemBuilder: (context, index) {
                final currency = _filteredCurrencies[index];
                final isSelected = currency.code == _selectedCurrencyCode;
                
                return ListTile(
                  leading: Text(
                    currency.flag,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    '${currency.code} - ${currency.name}',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(currency.symbol),
                  trailing: isSelected 
                      ? Icon(Icons.check_circle, color: colorScheme.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedCurrencyCode = currency.code;
                    });
                    
                    // Return the selected currency to the previous screen
                    Navigator.pop(context, currency);
                  },
                  tileColor: isSelected ? colorScheme.primaryContainer.withOpacity(0.2) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 