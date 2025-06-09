import 'dart:async';
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

class _EmailDetectionPageState extends State<EmailDetectionPage> with WidgetsBindingObserver {
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
  
  // Timer for periodic auth refresh
  Timer? _authRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAuth();
    
    // Set up periodic auth refresh (every 10 seconds when page is active)
    _authRefreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        print('⏰ Periodic auth check...');
        _checkAuthStateQuietly();
      }
    });
  }

  @override
  void dispose() {
    _authRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh auth state when coming back from settings
    print('📍 didChangeDependencies called, refreshing auth...');
    _initializeAuth();
  }

  @override
  void didUpdateWidget(EmailDetectionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh auth state when widget updates
    print('🔄 didUpdateWidget called, refreshing auth...');
    _initializeAuth();
  }

  // This method will be called when the app resumes or when returning from other screens
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh auth state when app resumes
      print('📱 App resumed, refreshing auth state...');
      _initializeAuth();
    }
  }

  // Method to handle when user returns from settings or other screens
  void _handleReturnFromNavigation() {
    print('🔄 Returned to Email Detection page, refreshing auth state...');
    _initializeAuth();
  }

  // Quiet auth check that doesn't show loading states
  Future<void> _checkAuthStateQuietly() async {
    if (!mounted || _isLoading || _isScanning) return;
    
    try {
      final cloudSyncService = Provider.of<CloudSyncService>(context, listen: false);
      final isGoogleSignedIn = _authService.isSignedIn;
      final isFirebaseSignedIn = cloudSyncService.isUserSignedIn;
      
      // Only update if there's a discrepancy
      final shouldBeSignedIn = isFirebaseSignedIn && isGoogleSignedIn;
      final currentlyShowingSignedIn = _currentUser != null;
      
      if (shouldBeSignedIn != currentlyShowingSignedIn) {
        print('🔄 Auth state mismatch detected, refreshing...');
        _initializeAuth();
      }
    } catch (e) {
      print('⚠️ Quiet auth check failed: $e');
    }
  }

  Future<void> _initializeAuth() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
    });
    
    try {
      print('🔄 Starting comprehensive auth refresh...');
      
      // Step 1: Check CloudSyncService first (this is our source of truth)
      final cloudSyncService = Provider.of<CloudSyncService>(context, listen: false);
      final isFirebaseSignedIn = cloudSyncService.isUserSignedIn;
      final firebaseUser = cloudSyncService.currentFirebaseUser;
      
      print('🔍 CloudSync state: signed in: $isFirebaseSignedIn, user: ${firebaseUser?.email}');
      
      // Step 2: Force reinitialize AuthService to get latest state
      await _authService.initialize();
      
      // Step 3: Get current Google auth state
      GoogleSignInAccount? currentUser = _authService.currentUser;
      final isGoogleSignedIn = _authService.isSignedIn;
      
      print('🔍 Initial Google state: signed in: $isGoogleSignedIn, user: ${currentUser?.email}');
      
      // Step 4: If Firebase is signed in but Google is not, try multiple approaches
      if (isFirebaseSignedIn && firebaseUser != null && currentUser == null) {
        print('🔄 Firebase signed in but Google not detected. Trying recovery methods...');
        
        // Method 1: Try silent sign-in again
        try {
          final googleSignIn = GoogleSignIn(scopes: [
            'email',
            'profile',
            'https://www.googleapis.com/auth/gmail.readonly',
          ]);
          
          final silentUser = await googleSignIn.signInSilently();
          if (silentUser != null) {
            print('✅ Silent sign-in recovered user: ${silentUser.email}');
            currentUser = silentUser;
            
            // Update AuthService with recovered user
            await _authService.initialize();
          }
        } catch (e) {
          print('⚠️ Silent sign-in failed: $e');
        }
        
        // Method 2: If still no user, try refreshing AuthService authentication
        if (currentUser == null) {
          print('🔄 Attempting AuthService refresh...');
          try {
            final refreshed = await _authService.refreshAuthentication();
            if (refreshed) {
              currentUser = _authService.currentUser;
              print('✅ AuthService refresh successful: ${currentUser?.email}');
            } else {
              print('❌ AuthService refresh failed');
            }
          } catch (e) {
            print('⚠️ AuthService refresh error: $e');
          }
        }
        
        // Method 3: If still no user and we have Firebase email, show helpful message
        if (currentUser == null) {
          print('⚠️ Could not recover Google auth for ${firebaseUser.email}');
          setState(() {
            _errorMessage = 'Google authentication needs to be refreshed. Please sign out and sign in again from Settings.';
          });
        }
      }
      
      // Step 5: If we have a Firebase user but no matching Google user, check if they match
      if (isFirebaseSignedIn && currentUser != null && firebaseUser != null) {
        if (currentUser.email != firebaseUser.email) {
          print('⚠️ Email mismatch: Google(${currentUser.email}) vs Firebase(${firebaseUser.email})');
          setState(() {
            _errorMessage = 'Account mismatch detected. Please sign out and sign in again.';
          });
          return;
        }
      }
      
      // Step 6: Clear previous detected subscriptions if user changed
      if (_currentUser?.email != currentUser?.email) {
        print('🔄 User changed from ${_currentUser?.email} to ${currentUser?.email}');
        _detectedSubscriptions.clear();
        _selectedSubscriptions.clear();
      }
      
      if (!mounted) return;
      
      setState(() {
        _currentUser = currentUser;
      });
      
      // Debug: Print final authentication state
      print('🔍 Final EmailDetectionPage Auth State:');
      print('   CloudSync.isUserSignedIn: $isFirebaseSignedIn');
      print('   CloudSync.currentUser: ${firebaseUser?.email}');
      print('   AuthService.isSignedIn: ${_authService.isSignedIn}');
      print('   AuthService.currentUser: ${_authService.currentUser?.email}');
      print('   AuthService.gmailApi: ${_authService.gmailApi != null ? "initialized" : "null"}');
      print('   Final _currentUser: ${_currentUser?.email}');
      print('   UI will show: ${_currentUser != null ? "scan section" : "sign-in prompt"}');
      
    } catch (error) {
      print('❌ Error initializing authentication: $error');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to initialize authentication: $error';
      });
    } finally {
      if (!mounted) return;
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
        _errorMessage = null;
      });
      
      // Show detected subscriptions in a popup dialog
      if (subscriptions.isEmpty) {
        _showSnackBar('No subscriptions found in your recent emails', isError: false);
      } else {
        _showDetectedSubscriptionsDialog(subscriptions);
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
        if (context.mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              isDark 
                  ? colorScheme.surface.withOpacity(0.95)
                  : colorScheme.primary.withOpacity(0.02),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern Header with Glassmorphism
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark 
                        ? Colors.white.withOpacity(0.1)
                        : Colors.white.withOpacity(0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Back button with modern styling
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email Detection',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'AI-powered subscription discovery',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Status indicator
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withOpacity(0.2),
                            Colors.orange.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content with improved spacing
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildModernIntroSection(),
                      const SizedBox(height: 16),
                      if (_currentUser != null) ...[
                        _buildModernScanSection(),
                      ] else
                        _buildModernSignInSection(),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        _buildModernErrorSection(),
                      ],
                      const SizedBox(height: 16), // Bottom padding
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernIntroSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor.withOpacity(0.05),
            Colors.orange.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange,
                      Colors.orange.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Email Detection',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Powered by AI',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            'Automatically discover subscriptions from your email receipts and billing statements. Our AI scans your Gmail for subscription-related emails and extracts subscription details to save you time.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          
          const SizedBox(height: 14),
          
          // Privacy note with better styling
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_rounded,
                  color: Colors.green.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Privacy protected: We only read subscription emails and never store your email content.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernScanSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withOpacity(0.03)
            : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
                             Container(
                 padding: const EdgeInsets.all(10),
                 decoration: BoxDecoration(
                   color: theme.colorScheme.primary.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: Icon(
                   Icons.email_outlined,
                   color: theme.colorScheme.primary,
                   size: 20,
                 ),
               ),
              const SizedBox(width: 12),
              Text(
                'Email Scanning',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Scan your recent emails (last 90 days) for subscription receipts and billing statements.',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.3,
            ),
          ),
          
          const SizedBox(height: 16),
          
                     // Progress bar (shown when scanning)
           if (_isScanning) ...[
             Container(
               padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _scanStatus,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_scanProgress.toInt()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _scanProgress / 100,
                      backgroundColor: Colors.orange.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
                         const SizedBox(height: 16),
           ],
           
           // Scan button
           Container(
             width: double.infinity,
             height: 52,
            child: ElevatedButton(
              onPressed: _isScanning ? null : _scanEmails,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isScanning ? Colors.grey : Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: _isScanning ? 0 : 3,
                shadowColor: Colors.orange.withOpacity(0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isScanning)
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(right: 12),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    const Icon(Icons.search_rounded, size: 20),
                  const SizedBox(width: 8),
                                     Text(
                     _isScanning ? 'Scanning Emails...' : 'Scan My Emails',
                     style: const TextStyle(
                       fontSize: 15,
                       fontWeight: FontWeight.w600,
                     ),
                   ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSignInSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.primaryColor.withOpacity(0.05),
            theme.primaryColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon with gradient background
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.account_circle_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Sign In Required',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'To scan your emails for subscriptions, please sign in with your Google account first.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 28),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.settings_outlined, size: 20),
                    label: const Text(
                      'Go to Settings',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _initializeAuth,
                  icon: _isLoading 
                      ? Container(
                          width: 16,
                          height: 16,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text(
                    'Refresh',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'You can sign in from the Settings page or tap Refresh after signing in',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernErrorSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            Row(
              children: [
                Expanded(
                  child: SizedBox(
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
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _initializeAuth,
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.secondary,
                      foregroundColor: colorScheme.onSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'You can sign in from the Settings page or tap Refresh after signing in',
              textAlign: TextAlign.center,
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
    // Get responsive sizing based on screen size and pixel density
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final pixelRatio = mediaQuery.devicePixelRatio;
    final textScaleFactor = mediaQuery.textScaleFactor;
    
    // Calculate responsive dimensions
    // Smaller devices or higher pixel density = more compact layout
    final isCompactScreen = screenHeight < 700 || textScaleFactor > 1.1;
    final isLargeScreen = screenWidth > 400;
    
    // Adaptive spacing and sizing
    final cardPadding = isCompactScreen ? 12.0 : 16.0;
    final cardMargin = isCompactScreen ? 8.0 : 12.0;
    final logoSize = isCompactScreen ? 40.0 : 48.0;
    final horizontalSpacing = isCompactScreen ? 12.0 : 16.0;
    final verticalSpacing = isCompactScreen ? 4.0 : 8.0;
    final smallVerticalSpacing = isCompactScreen ? 2.0 : 4.0;
    
    // Adaptive font sizes
    final titleFontSize = isCompactScreen ? 14.0 : 16.0;
    final priceFontSize = isCompactScreen ? 12.0 : 14.0;
    final trialFontSize = isCompactScreen ? 10.0 : 12.0;
    final dateFontSize = isCompactScreen ? 9.0 : 11.0;
    final badgeFontSize = isCompactScreen ? 8.0 : 10.0;
    
    // Adaptive trial badge sizing
    final badgePadding = isCompactScreen 
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
    
    // Adaptive checkbox scaling
    final checkboxScale = isCompactScreen ? 1.0 : 1.2;

    return Container(
      margin: EdgeInsets.only(bottom: cardMargin),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(isCompactScreen ? 12 : 16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isCompactScreen ? 6 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          children: [
            // Logo
            Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isCompactScreen ? 10 : 12),
              ),
              child: subscription.logoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(isCompactScreen ? 10 : 12),
                      child: Image.network(
                        subscription.logoUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.subscriptions,
                          color: Theme.of(context).primaryColor,
                          size: logoSize * 0.5,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.subscriptions,
                      color: Theme.of(context).primaryColor,
                      size: logoSize * 0.5,
                    ),
            ),
            
            SizedBox(width: horizontalSpacing),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service name only (trial badge moved to top-right)
                  Text(
                    subscription.serviceName,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: verticalSpacing),
                  
                  // Price
                  Text(
                    '${subscription.currency} ${subscription.amount.toStringAsFixed(2)} / ${_getBillingCycleText(subscription.billingCycle)}',
                    style: TextStyle(
                      fontSize: priceFontSize,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                  ),
                  
                  if (subscription.isFreeTrial) ...[
                    SizedBox(height: smallVerticalSpacing),
                    Text(
                      'Free for ${subscription.trialDays ?? '?'} days',
                      style: TextStyle(
                        fontSize: trialFontSize,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  
                  SizedBox(height: verticalSpacing),
                  
                  // Date
                  if (subscription.emailDate != null)
                    Text(
                      'Detected ${subscription.emailDate!.toLocal().toString().split(' ')[0]}',
                      style: TextStyle(
                        fontSize: dateFontSize,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
            
            SizedBox(width: horizontalSpacing),
            
            // Right side with trial badge and checkbox
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Trial badge at top
                if (subscription.isFreeTrial) ...[
                  Container(
                    padding: badgePadding,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(isCompactScreen ? 6 : 8),
                    ),
                    child: Text(
                      'TRIAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: badgeFontSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: verticalSpacing),
                ],
                
                // Checkbox at bottom
                Transform.scale(
                  scale: checkboxScale,
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
          ],
        ),
      ),
    );
  }

  /// Get proper grammar for billing cycle text
  String _getBillingCycleText(BillingCycle billingCycle) {
    switch (billingCycle) {
      case BillingCycle.weekly:
        return 'week';
      case BillingCycle.monthly:
        return 'month';
      case BillingCycle.yearly:
        return 'year';
    }
  }

  /// Show detected subscriptions in a popup dialog
  void _showDetectedSubscriptionsDialog(List<DetectedSubscription> subscriptions) {
    final selectedSubscriptions = Set<int>();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                  maxWidth: 400,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).dialogBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Theme.of(context).brightness == Brightness.dark
                      ? Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.1),
                            Theme.of(context).primaryColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.email_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Detected Subscriptions',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).textTheme.titleLarge?.color,
                                  ),
                                ),
                                Text(
                                  '${subscriptions.length} subscription${subscriptions.length != 1 ? 's' : ''} found',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Select/Deselect All Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child:                         Container(
                         width: double.infinity,
                         decoration: BoxDecoration(
                           color: Theme.of(context).brightness == Brightness.dark
                               ? Colors.white.withOpacity(0.05)
                               : Colors.grey.withOpacity(0.05),
                           border: Border.all(
                             color: Theme.of(context).brightness == Brightness.dark
                                 ? Colors.white.withOpacity(0.3)
                                 : Colors.grey.withOpacity(0.3),
                           ),
                           borderRadius: BorderRadius.circular(12),
                         ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setDialogState(() {
                                if (selectedSubscriptions.length == subscriptions.length) {
                                  selectedSubscriptions.clear();
                                } else {
                                  selectedSubscriptions.clear();
                                  selectedSubscriptions.addAll(List.generate(subscriptions.length, (index) => index));
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              child: Row(
                                children: [
                                  Icon(
                                    selectedSubscriptions.length == subscriptions.length
                                        ? Icons.check_box_rounded
                                        : selectedSubscriptions.isEmpty
                                            ? Icons.check_box_outline_blank_rounded
                                            : Icons.indeterminate_check_box_rounded,
                                    color: Theme.of(context).primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    selectedSubscriptions.length == subscriptions.length
                                        ? 'Deselect All'
                                        : 'Select All',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (selectedSubscriptions.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${selectedSubscriptions.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Subscription List
                    Flexible(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        shrinkWrap: true,
                        itemCount: subscriptions.length,
                        itemBuilder: (context, index) {
                          final subscription = subscriptions[index];
                          final isSelected = selectedSubscriptions.contains(index);
                          
                                                     return Container(
                             margin: const EdgeInsets.only(bottom: 12),
                             decoration: BoxDecoration(
                               color: isSelected 
                                   ? Theme.of(context).brightness == Brightness.dark
                                       ? Theme.of(context).primaryColor.withOpacity(0.15)
                                       : Theme.of(context).primaryColor.withOpacity(0.08)
                                   : Theme.of(context).cardColor,
                               borderRadius: BorderRadius.circular(16),
                               border: Border.all(
                                 color: isSelected
                                     ? Theme.of(context).primaryColor.withOpacity(0.6)
                                     : Theme.of(context).brightness == Brightness.dark
                                         ? Colors.white.withOpacity(0.25)
                                         : Colors.grey.withOpacity(0.2),
                                 width: isSelected ? 2 : 1,
                               ),
                               boxShadow: [
                                 if (isSelected)
                                   BoxShadow(
                                     color: Theme.of(context).primaryColor.withOpacity(0.2),
                                     blurRadius: 12,
                                     offset: const Offset(0, 4),
                                   ),
                               ],
                             ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  setDialogState(() {
                                    if (isSelected) {
                                      selectedSubscriptions.remove(index);
                                    } else {
                                      selectedSubscriptions.add(index);
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Logo
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white.withOpacity(0.1)
                                              : Colors.grey.shade100,
                                        ),
                                        child: subscription.logoUrl != null
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.network(
                                                  subscription.logoUrl!,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error, stackTrace) => Icon(
                                                    Icons.subscriptions_rounded,
                                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                                                    size: 22,
                                                  ),
                                                ),
                                              )
                                            : Icon(
                                                Icons.subscriptions_rounded,
                                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                                                size: 22,
                                              ),
                                      ),
                                      
                                      const SizedBox(width: 12),
                                      
                                      // Content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Service name
                                            Text(
                                              subscription.serviceName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: Theme.of(context).textTheme.titleMedium?.color,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            
                                            const SizedBox(height: 4),
                                            
                                            // Price and billing cycle
                                            Row(
                                              children: [
                                                Text(
                                                  '${subscription.currency} ${subscription.amount.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                                Text(
                                                  ' / ${_getBillingCycleText(subscription.billingCycle)}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            
                                            const SizedBox(height: 6),
                                            
                                            // Trial and date info
                                            Row(
                                              children: [
                                                if (subscription.isFreeTrial) ...[
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.withOpacity(0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(
                                                        color: Colors.green.withOpacity(0.3),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'FREE ${subscription.trialDays ?? '?'} DAYS',
                                                      style: TextStyle(
                                                        color: Colors.green.shade700,
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                ],
                                                Flexible(
                                                  child: Text(
                                                    subscription.emailDate != null
                                                        ? 'Detected ${subscription.emailDate!.toLocal().toString().split(' ')[0]}'
                                                        : 'Recently detected',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 8),
                                      
                                                                               // Selection indicator
                                       Container(
                                         padding: const EdgeInsets.all(2),
                                         decoration: BoxDecoration(
                                           shape: BoxShape.circle,
                                           color: isSelected 
                                               ? Theme.of(context).primaryColor
                                               : Colors.transparent,
                                           border: Border.all(
                                             color: isSelected
                                                 ? Theme.of(context).primaryColor
                                                 : Theme.of(context).brightness == Brightness.dark
                                                     ? Colors.white.withOpacity(0.4)
                                                     : Colors.grey.withOpacity(0.6),
                                             width: 2,
                                           ),
                                         ),
                                         child: Icon(
                                           isSelected ? Icons.check : Icons.add,
                                           color: isSelected 
                                               ? Colors.white
                                               : Theme.of(context).brightness == Brightness.dark
                                                   ? Colors.white.withOpacity(0.6)
                                                   : Colors.grey.withOpacity(0.6),
                                           size: 16,
                                         ),
                                       ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Action Buttons
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.2),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: selectedSubscriptions.isEmpty
                                  ? null
                                  : () async {
                                      Navigator.of(context).pop();
                                      await _addSubscriptionsFromDialog(subscriptions, selectedSubscriptions);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: selectedSubscriptions.isEmpty ? 0 : 2,
                              ),
                              child: Text(
                                selectedSubscriptions.isEmpty 
                                    ? 'Select subscriptions'
                                    : 'Add Selected (${selectedSubscriptions.length})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Add selected subscriptions from dialog
  Future<void> _addSubscriptionsFromDialog(List<DetectedSubscription> subscriptions, Set<int> selectedIndices) async {
    if (selectedIndices.isEmpty) {
      _showSnackBar('Please select at least one subscription to add', isError: true);
      return;
    }

    setState(() => _isAddingSubscriptions = true);

    try {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      int addedCount = 0;

      for (final index in selectedIndices) {
        if (index < subscriptions.length) {
          final detected = subscriptions[index];
          
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
        final skippedCount = selectedIndices.length - addedCount;
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