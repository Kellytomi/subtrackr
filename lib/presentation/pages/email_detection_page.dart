import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/cloud_sync_service.dart';
import '../../data/services/email_scanner_service.dart';
import '../../presentation/providers/subscription_provider.dart';
import '../../domain/entities/subscription.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../../data/services/logo_service.dart';

class EmailDetectionPage extends StatefulWidget {
  const EmailDetectionPage({super.key});

  @override
  State<EmailDetectionPage> createState() => _EmailDetectionPageState();
}

class _EmailDetectionPageState extends State<EmailDetectionPage> {
  final AuthService _authService = AuthService();
  final EmailScannerService _emailService = EmailScannerService();
  
  bool _isLoading = false;
  bool _isScanning = false;
  bool _isAddingSubscriptions = false;
  GoogleSignInAccount? _currentUser;
  List<DetectedSubscription> _detectedSubscriptions = [];
  Set<int> _selectedSubscriptions = {};
  String? _errorMessage;
  
  // Progress tracking
  double _scanProgress = 0.0;
  String _scanStatus = '';

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh auth state when coming back from settings
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    setState(() => _isLoading = true);
    
    try {
      await _authService.initialize();
      
      // Check both AuthService and CloudSyncService for authentication
      final cloudSyncService = Provider.of<CloudSyncService>(context, listen: false);
      final isGoogleSignedIn = _authService.isSignedIn;
      final isFirebaseSignedIn = cloudSyncService.isUserSignedIn;
      
      setState(() {
        _currentUser = _authService.currentUser;
      });
      
      // If AuthService doesn't have current user but Firebase is signed in, try to get it
      if (_currentUser == null && isFirebaseSignedIn) {
        try {
          // Try to refresh AuthService authentication
          final refreshed = await _authService.refreshAuthentication();
          if (refreshed) {
            setState(() {
              _currentUser = _authService.currentUser;
            });
          }
        } catch (e) {
          print('⚠️ Could not refresh Google authentication: $e');
        }
      }
      
      // Debug: Print authentication state
      print('🔍 EmailDetectionPage Auth Debug:');
      print('   AuthService.isSignedIn: $isGoogleSignedIn');
      print('   AuthService.currentUser: ${_authService.currentUser?.email}');
      print('   AuthService.gmailApi: ${_authService.gmailApi != null ? "initialized" : "null"}');
      print('   CloudSyncService.isUserSignedIn: $isFirebaseSignedIn');
      print('   Final _currentUser: ${_currentUser?.email}');
      
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to initialize authentication: $error';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }



  Future<void> _scanEmails() async {
    if (_currentUser == null) {
      setState(() {
        _errorMessage = 'Please sign in with Google first';
      });
      return;
    }
    
    setState(() {
      _isScanning = true;
      _scanProgress = 0.0;
      _scanStatus = 'Starting email scan...';
    });
    
    try {
      // Debug: Check authentication state before scanning
      print('🔍 Pre-scan debug:');
      print('   _currentUser: ${_currentUser?.email}');
      print('   AuthService.isSignedIn: ${_authService.isSignedIn}');
      print('   AuthService.gmailApi: ${_authService.gmailApi != null ? "initialized" : "null"}');
      
      // Check if Gmail API is initialized, if not, try to initialize it
      if (_authService.gmailApi == null && _currentUser != null) {
        setState(() {
          _scanProgress = 3.0;
          _scanStatus = 'Initializing Gmail access...';
        });
        
        // Try to reinitialize Gmail API
        await _authService.initialize();
        
        // If still null, try refreshing authentication
        if (_authService.gmailApi == null) {
          setState(() {
            _scanProgress = 5.0;
            _scanStatus = 'Refreshing authentication...';
          });
          
          final refreshed = await _authService.refreshAuthentication();
          if (!refreshed) {
            setState(() {
              _errorMessage = 'Failed to initialize Gmail access. Please sign out and sign in again.';
            });
            return;
          }
        }
      }
      
      // Check if we have Gmail permissions
      setState(() {
        _scanProgress = 8.0;
        _scanStatus = 'Checking permissions...';
      });
      
      final hasPermissions = await _authService.hasGmailPermissions();
      if (!hasPermissions) {
        setState(() {
          _scanProgress = 12.0;
          _scanStatus = 'Requesting Gmail permissions...';
        });
        
        final granted = await _authService.requestGmailPermissions();
        if (!granted) {
          setState(() {
            _errorMessage = 'Gmail permissions are required to scan emails';
          });
          return;
        }
      }
      
      // Scan emails for subscriptions with progress callback
      setState(() {
        _scanProgress = 15.0;
        _scanStatus = 'Starting email scan...';
      });
      
      final subscriptions = await _emailService.scanForSubscriptions(
        maxResults: 50,
        daysBack: 90,
        onProgress: (progress, status) {
          setState(() {
            // Scale progress from 15-100 to account for initial setup
            _scanProgress = 15.0 + (progress * 0.85);
            _scanStatus = status;
          });
        },
      );
      
      setState(() {
        _detectedSubscriptions = subscriptions;
        _selectedSubscriptions = Set.from(List.generate(subscriptions.length, (index) => index));
        _errorMessage = null;
      });
      
      if (subscriptions.isEmpty) {
        _showSnackBar('No subscriptions found in your recent emails', isError: false);
      } else {
        _showSnackBar('Found ${subscriptions.length} potential subscriptions!', isError: false);
      }
    } catch (error) {
      String errorMessage = 'Error scanning emails: $error';
      
      // Provide more helpful error messages for common issues
      if (error.toString().contains('401') || error.toString().contains('authentication')) {
        errorMessage = 'Authentication failed. Please sign out and sign in again to refresh your Gmail permissions.';
      } else if (error.toString().contains('403')) {
        errorMessage = 'Gmail access was denied. Please ensure you grant Gmail permissions when signing in.';
      } else if (error.toString().contains('network') || error.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      }
      
      setState(() {
        _errorMessage = errorMessage;
      });
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _addSelectedSubscriptions() async {
    if (_selectedSubscriptions.isEmpty) {
      _showSnackBar('Please select at least one subscription to add', isError: true);
      return;
    }

    setState(() => _isAddingSubscriptions = true);

    try {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      int addedCount = 0;

      for (final index in _selectedSubscriptions) {
        if (index < _detectedSubscriptions.length) {
          final detected = _detectedSubscriptions[index];
          
          // Convert detected subscription to Subscription entity
          final subscription = await _convertDetectedToSubscription(detected);
          
          // Check if subscription already exists (by name and amount)
          final existingSubscriptions = subscriptionProvider.subscriptions;
          final isDuplicate = existingSubscriptions.any((existing) =>
              existing.name.toLowerCase() == subscription.name.toLowerCase() &&
              existing.amount == subscription.amount);

          if (!isDuplicate) {
            await subscriptionProvider.addSubscription(subscription);
            addedCount++;
          } else {
            print('⚠️ Duplicate subscription skipped: ${subscription.name} - ${subscription.currencyCode}${subscription.amount}');
          }
        }
      }

      if (addedCount > 0) {
        final skippedCount = _selectedSubscriptions.length - addedCount;
        if (skippedCount > 0) {
          _showSnackBar('Added $addedCount subscription(s)! Skipped $skippedCount duplicate(s).', isError: false);
        } else {
          _showSnackBar('Successfully added $addedCount subscription(s)!', isError: false);
        }
        
        // Navigate back to homepage (pop all routes back to root)
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        _showSnackBar('All selected subscriptions already exist in your app', isError: true);
      }
    } catch (error) {
      _showSnackBar('Error adding subscriptions: $error', isError: true);
    } finally {
      setState(() => _isAddingSubscriptions = false);
    }
  }

  Future<Subscription> _convertDetectedToSubscription(DetectedSubscription detected) async {
    final now = DateTime.now();
    
    // For free trials, we need to handle dates carefully
    DateTime startDate;
    DateTime renewalDate;
    
    if (detected.isFreeTrial) {
      // For free trials: use email date as trial start, and billing start date as first renewal
      startDate = detected.emailDate ?? now;
      
      print('🔍 Debug trial dates:');
      print('   detected.emailDate: ${detected.emailDate}');
      print('   detected.startDate: ${detected.startDate}');
      print('   detected.billingStartDate: ${detected.billingStartDate}');
      print('   detected.trialDays: ${detected.trialDays}');
      print('   Will use startDate: $startDate');
      
      if (detected.billingStartDate != null) {
        // Check if billing start date is the same as trial start (incorrect parsing)
        if (detected.billingStartDate!.difference(startDate).inDays.abs() <= 1) {
          print('⚠️ Warning: Billing start date is same as trial start, calculating from trial days');
          if (detected.trialDays != null && detected.trialDays! > 0) {
            renewalDate = startDate.add(Duration(days: detected.trialDays!));
            print('🆓 Fixed free trial: ${detected.serviceName} starts ${startDate.day}/${startDate.month}/${startDate.year}, ${detected.trialDays} days trial, billing starts ${renewalDate.day}/${renewalDate.month}/${renewalDate.year}');
          } else {
            // Fallback: assume 7-day trial
            renewalDate = startDate.add(const Duration(days: 7));
            print('🆓 Fixed free trial (fallback): ${detected.serviceName} starts ${startDate.day}/${startDate.month}/${startDate.year}, assuming 7-day trial, billing starts ${renewalDate.day}/${renewalDate.month}/${renewalDate.year}');
          }
        } else {
          // First renewal is when billing starts (end of trial)
          renewalDate = detected.billingStartDate!;
          print('🆓 Free trial: ${detected.serviceName} starts ${startDate.day}/${startDate.month}/${startDate.year}, billing starts ${renewalDate.day}/${renewalDate.month}/${renewalDate.year}');
        }
      } else if (detected.trialDays != null && detected.trialDays! > 0) {
        // Calculate billing start from trial start + trial days
        renewalDate = startDate.add(Duration(days: detected.trialDays!));
        print('🆓 Free trial: ${detected.serviceName} starts ${startDate.day}/${startDate.month}/${startDate.year}, ${detected.trialDays} days trial, billing starts ${renewalDate.day}/${renewalDate.month}/${renewalDate.year}');
      } else {
        // Fallback: assume 7-day trial
        renewalDate = startDate.add(const Duration(days: 7));
        print('🆓 Free trial: ${detected.serviceName} starts ${startDate.day}/${startDate.month}/${startDate.year}, assuming 7-day trial, billing starts ${renewalDate.day}/${renewalDate.month}/${renewalDate.year}');
      }
    } else {
      // Regular subscription: use standard logic
      startDate = detected.startDate ?? detected.emailDate ?? now;
      renewalDate = _calculateRenewalDate(startDate, detected.billingCycle);
      print('💰 Regular subscription: ${detected.serviceName} starts ${startDate.day}/${startDate.month}, next renewal ${renewalDate.day}/${renewalDate.month}');
    }
    
    // Convert billing cycle
    String billingCycle;
    int? customBillingDays;
    
    switch (detected.billingCycle) {
      case BillingCycle.weekly:
        billingCycle = AppConstants.BILLING_CYCLE_CUSTOM;
        customBillingDays = 7;
        break;
      case BillingCycle.monthly:
        billingCycle = AppConstants.BILLING_CYCLE_MONTHLY;
        break;
      case BillingCycle.yearly:
        billingCycle = AppConstants.BILLING_CYCLE_YEARLY;
        break;
    }

    // Determine category based on service name
    String category = _categorizeService(detected.serviceName);

    // Use the already-fetched logo from detection
    String? logoUrl = detected.logoUrl;

          return Subscription(
        name: detected.serviceName,
        amount: detected.amount,
        currencyCode: detected.currency,
        billingCycle: billingCycle,
        customBillingDays: customBillingDays,
        startDate: startDate,
        renewalDate: renewalDate,
        status: AppConstants.STATUS_ACTIVE,
        category: category,
        logoUrl: logoUrl,
                description: detected.isFreeTrial 
            ? 'Auto-detected from email: ${detected.emailSubject} (Free trial: ${detected.trialDays ?? 'Unknown'} days starting ${startDate.day}/${startDate.month}/${startDate.year}, billing starts ${renewalDate.day}/${renewalDate.month}/${renewalDate.year})'
            : 'Auto-detected from email: ${detected.emailSubject}',
        notificationsEnabled: true,
        notificationDays: detected.isFreeTrial ? 1 : 1, // 1 day before for email-detected subscriptions
      );
  }
  
  DateTime _calculateRenewalDate(DateTime startDate, BillingCycle billingCycle) {
    switch (billingCycle) {
      case BillingCycle.weekly:
        return startDate.add(const Duration(days: 7));
      case BillingCycle.monthly:
        return DateTime(startDate.year, startDate.month + 1, startDate.day);
      case BillingCycle.yearly:
        return DateTime(startDate.year + 1, startDate.month, startDate.day);
    }
  }

  String _categorizeService(String serviceName) {
    final lowerName = serviceName.toLowerCase();
    
    // Entertainment services (check specific video services first)
    if (lowerName.contains('prime video') ||
        lowerName.contains('amazon prime video') ||
        lowerName.contains('netflix') || 
        lowerName.contains('spotify') ||
        lowerName.contains('disney') ||
        lowerName.contains('hulu') ||
        lowerName.contains('youtube') ||
        lowerName.contains('hbo') ||
        lowerName.contains('paramount') ||
        lowerName.contains('twitch') ||
        lowerName.contains('apple tv') ||
        lowerName.contains('peacock') ||
        lowerName.contains('crunchyroll')) {
      return AppConstants.CATEGORY_ENTERTAINMENT;
    }
    
    // Productivity services
    if (lowerName.contains('notion') ||
        lowerName.contains('slack') ||
        lowerName.contains('zoom') ||
        lowerName.contains('canva') ||
        lowerName.contains('figma') ||
        lowerName.contains('adobe') ||
        lowerName.contains('microsoft') ||
        lowerName.contains('google')) {
      return AppConstants.CATEGORY_PRODUCTIVITY;
    }
    
    // Software/Developer services
    if (lowerName.contains('github') ||
        lowerName.contains('gitlab') ||
        lowerName.contains('atlassian')) {
      return AppConstants.CATEGORY_SOFTWARE;
    }
    
    // Security services
    if (lowerName.contains('vpn') ||
        lowerName.contains('1password') ||
        lowerName.contains('lastpass') ||
        lowerName.contains('dashlane')) {
      return AppConstants.CATEGORY_SOFTWARE;
    }
    
    // Gaming services
    if (lowerName.contains('playstation') ||
        lowerName.contains('xbox') ||
        lowerName.contains('nintendo')) {
      return AppConstants.CATEGORY_GAMING;
    }
    
    // Shopping services (after entertainment checks)
    if (lowerName.contains('amazon prime') && !lowerName.contains('video')) {
      return AppConstants.CATEGORY_SHOPPING;
    }
    if (lowerName.contains('amazon') && !lowerName.contains('prime video')) {
      return AppConstants.CATEGORY_SHOPPING;
    }
    
    // Default to Other
    return AppConstants.CATEGORY_OTHER;
  }

  /// Convert detected service names to better logo search terms
  String _getLogoSearchTerm(String serviceName) {
    final lowerName = serviceName.toLowerCase();
    
    // Map detected names to better logo search terms
    if (lowerName.contains('amazon prime video') || lowerName == 'amazon prime video') {
      return 'Prime Video';
    }
    
    if (lowerName.contains('youtube premium') || lowerName == 'youtube premium') {
      return 'YouTube Premium';
    }
    
    if (lowerName.contains('youtube music') || lowerName == 'youtube music') {
      return 'YouTube Music';
    }
    
    if (lowerName.contains('microsoft 365') || lowerName == 'microsoft 365') {
      return 'Microsoft 365';
    }
    
    if (lowerName.contains('office 365') || lowerName == 'office 365') {
      return 'Microsoft 365';
    }
    
    if (lowerName.contains('google one') || lowerName == 'google one') {
      return 'Google One';
    }
    
    if (lowerName.contains('google drive') || lowerName == 'google drive') {
      return 'Google Drive';
    }
    
    if (lowerName.contains('icloud') || lowerName == 'icloud storage') {
      return 'iCloud';
    }
    
    if (lowerName.contains('adobe creative cloud') || lowerName == 'adobe creative cloud') {
      return 'Adobe Creative Cloud';
    }
    
    if (lowerName.contains('github pro') || lowerName == 'github pro') {
      return 'GitHub';
    }
    
    if (lowerName.contains('discord nitro') || lowerName == 'discord nitro') {
      return 'Discord Nitro';
    }
    
    // For services ending with specific suffixes, clean them up
    if (lowerName.endsWith(' subscription')) {
      return serviceName.substring(0, serviceName.length - 12);
    }
    
    if (lowerName.endsWith(' premium')) {
      return serviceName;  // Keep "Premium" for services like "Spotify Premium"
    }
    
    // Default: return the original service name
    return serviceName;
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
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
            // Clean Header matching other pages
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
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Email Detection',
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
                      Icons.auto_awesome,
                      size: 24,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildIntroSection(),
                    const SizedBox(height: 24),
                    if (_currentUser != null) ...[
                      _buildScanSection(),
                      const SizedBox(height: 24),
                      _buildResultsSection(),
                    ] else
                      _buildSignInPromptSection(),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorSection(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Smart Email Detection',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Automatically detect subscriptions from your email receipts and billing statements. '
              'This feature scans your Gmail for subscription-related emails and extracts '
              'subscription details to save you time.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              '🔒 Your privacy is important: We only read subscription-related emails and never store your email content.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInPromptSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 64,
              color: colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Sign In Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'To scan your emails for subscriptions, please sign in with your Google account first.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // Go back
                  // Open bottom navigation to settings tab (index 3)
                  // The user will need to navigate to settings manually
                },
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Go to Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You can sign in from the Settings page',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Email Scanning',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scan your recent emails (last 90 days) for subscription receipts and billing statements.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            // Progress bar (shown when scanning)
            if (_isScanning) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _scanStatus,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${_scanProgress.toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _scanProgress / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ],
            
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? null : _scanEmails,
                icon: _isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.email_outlined),
                label: Text(_isScanning ? 'Scanning...' : 'Scan My Emails'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_detectedSubscriptions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detected Subscriptions (${_detectedSubscriptions.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        if (_selectedSubscriptions.length == _detectedSubscriptions.length) {
                          _selectedSubscriptions.clear();
                        } else {
                          _selectedSubscriptions = Set.from(
                            List.generate(_detectedSubscriptions.length, (index) => index)
                          );
                        }
                      });
                    },
                    icon: Icon(
                      _selectedSubscriptions.length == _detectedSubscriptions.length 
                          ? Icons.deselect 
                          : Icons.select_all,
                      size: 18,
                    ),
                    label: Text(
                      _selectedSubscriptions.length == _detectedSubscriptions.length 
                          ? 'Deselect All' 
                          : 'Select All',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      foregroundColor: Theme.of(context).primaryColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _detectedSubscriptions.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final subscription = _detectedSubscriptions[index];
                return _buildSubscriptionTile(subscription);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedSubscriptions.isEmpty || _isAddingSubscriptions
                    ? null 
                    : _addSelectedSubscriptions,
                icon: _isAddingSubscriptions
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(_isAddingSubscriptions 
                    ? 'Adding subscriptions...' 
                    : 'Add Selected Subscriptions (${_selectedSubscriptions.length})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionTile(DetectedSubscription subscription) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Logo
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: subscription.logoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        subscription.logoUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.subscriptions,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.subscriptions,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
            ),
            
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service name and trial badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subscription.serviceName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (subscription.isFreeTrial) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'TRIAL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Price
                  Text(
                    '${subscription.currency} ${subscription.amount.toStringAsFixed(2)} / ${subscription.billingCycle.name}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                  ),
                  
                  if (subscription.isFreeTrial) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Free for ${subscription.trialDays ?? '?'} days',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  
                  // Date
                  if (subscription.emailDate != null)
                    Text(
                      'Detected ${subscription.emailDate!.toLocal().toString().split(' ')[0]}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Checkbox
            Transform.scale(
              scale: 1.2,
              child: Checkbox(
                value: _selectedSubscriptions.contains(_detectedSubscriptions.indexOf(subscription)),
                onChanged: (value) {
                  final index = _detectedSubscriptions.indexOf(subscription);
                  setState(() {
                    if (value == true) {
                      _selectedSubscriptions.add(index);
                    } else {
                      _selectedSubscriptions.remove(index);
                    }
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSection() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 