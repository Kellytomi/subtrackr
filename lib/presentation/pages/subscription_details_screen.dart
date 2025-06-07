import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/core/utils/currency_utils.dart';
import 'package:subtrackr/core/utils/date_utils.dart';
import 'package:subtrackr/data/services/logo_service.dart';
import 'package:subtrackr/domain/entities/subscription.dart';
import 'package:subtrackr/presentation/providers/subscription_provider.dart';
import 'package:subtrackr/core/widgets/app_tip.dart';
import 'package:subtrackr/core/utils/tips_helper.dart';

class SubscriptionDetailsScreen extends StatefulWidget {
  const SubscriptionDetailsScreen({super.key});

  @override
  State<SubscriptionDetailsScreen> createState() => _SubscriptionDetailsScreenState();
}

class _SubscriptionDetailsScreenState extends State<SubscriptionDetailsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Create a unique hero tag for this screen
  final String _heroTag = 'details_logo_${UniqueKey()}';
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Load data after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubscription();
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _loadSubscription() {
    // We'll set a brief delay to show loading indicator for better UX
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    });
  }

  void _deleteSubscription(BuildContext context, String subscriptionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Subscription'),
          content: const Text('Are you sure you want to delete this subscription? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final provider = Provider.of<SubscriptionProvider>(context, listen: false);
      provider.deleteSubscription(subscriptionId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppConstants.SUBSCRIPTION_DELETED_SUCCESS),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(
            bottom: kFloatingActionButtonMargin + 48,
            left: 20,
            right: 20,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _updateSubscriptionStatus(String subscriptionId, String newStatus) {
    final provider = Provider.of<SubscriptionProvider>(context, listen: false);
    
    // Find the subscription
    final subscription = provider.subscriptions.firstWhere(
      (s) => s.id == subscriptionId,
      orElse: () => throw Exception('Subscription not found'),
    );
    
    // Create updated subscription with new status
    final updatedSubscription = subscription.copyWith(status: newStatus);
    
    // Update in provider
    provider.updateSubscription(updatedSubscription);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Subscription ${_getStatusActionText(newStatus)}'),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Refresh state
    setState(() {});
    }
  
  String _getStatusActionText(String status) {
    switch (status) {
      case AppConstants.STATUS_ACTIVE:
        return 'activated';
      case AppConstants.STATUS_PAUSED:
        return 'paused';
      case AppConstants.STATUS_CANCELLED:
        return 'cancelled';
      default:
        return 'updated';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    // Get subscription ID from route arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final subscriptionId = args?['id'] as String?;
    
    if (subscriptionId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('Subscription ID not found'),
        ),
      );
    }
    
    // Get subscription from provider
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    
    // Show loading state if provider is loading
    if (subscriptionProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    // Find the subscription
    Subscription? subscription;
    try {
      subscription = subscriptionProvider.subscriptions.firstWhere(
        (s) => s.id == subscriptionId,
      );
    } catch (e) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('Subscription not found'),
        ),
      );
    }
    
    // Since we've found the subscription, we can be sure it's not null
    final sub = subscription;
    
    // Format subscription details
    final currencyFormatter = NumberFormat.currency(
      symbol: CurrencyUtils.getCurrencyByCode(sub.currencyCode)?.symbol ?? '\$',
      decimalDigits: 2,
    );
    
    // Determine status color
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (sub.status) {
      case AppConstants.STATUS_ACTIVE:
        statusColor = colorScheme.primary;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Active';
        break;
      case AppConstants.STATUS_PAUSED:
        statusColor = colorScheme.tertiary;
        statusIcon = Icons.pause_circle_rounded;
        statusText = 'Paused';
        break;
      case AppConstants.STATUS_CANCELLED:
        statusColor = Colors.grey;
        statusIcon = Icons.cancel_rounded;
        statusText = 'Cancelled';
        break;
      default:
        statusColor = colorScheme.primary;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Active';
    }
    
    // Calculate days until renewal
    final daysUntilRenewal = sub.renewalDate != null
      ? _calculateDaysUntil(sub.renewalDate)
      : null;
      
    // Get currency data
    final currency = CurrencyUtils.getCurrencyByCode(sub.currencyCode);
    
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Ensure animations are completed
        if (_animationController.status == AnimationStatus.forward) {
          _animationController.forward();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with back and edit buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back, 
                            color: isDark ? Colors.white : Colors.black
                          ),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Back',
                          style: IconButton.styleFrom(
                            backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context, 
                                  '/edit-subscription',
                                  arguments: {'id': sub.id},
                                );
                              },
                              tooltip: 'Edit',
                              style: IconButton.styleFrom(
                                backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: theme.colorScheme.error,
                              ),
                              onPressed: () => _deleteSubscription(context, sub.id),
                              tooltip: 'Delete',
                              style: IconButton.styleFrom(
                                backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            // Logo and name
                            Center(
                              child: Column(
                                children: [
                                  if (sub.logoUrl != null)
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: colorScheme.primary.withOpacity(0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Hero(
                                          tag: _heroTag,
                                          flightShuttleBuilder: (_, __, ___, ____, _____) => 
                                            const SizedBox.shrink(),
                                          child: Image.network(
                                            sub.logoUrl!,
                                            key: ValueKey('details_${sub.id}_logo'),
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              final logoService = Provider.of<LogoService>(context, listen: false);
                                              return Container(
                                                color: colorScheme.primary,
                                                child: Icon(
                                                  logoService.getFallbackIcon(sub.name),
                                                  color: Colors.white,
                                                  size: 40,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Center(
                                        child: Text(
                                          sub.name.substring(0, 1).toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  Text(
                                    sub.name,
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (sub.website != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        sub.website!,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Quick action buttons instead of status badge
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Activate button
                                  if (sub.status != AppConstants.STATUS_ACTIVE)
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          _updateSubscriptionStatus(
                                            sub.id, 
                                            AppConstants.STATUS_ACTIVE
                                          );
                                        },
                                        icon: const Icon(Icons.play_circle_outline, color: Colors.white),
                                        label: const Text('Start'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        ),
                                      ),
                                    ),
                                  
                                  // Pause button
                                  if (sub.status != AppConstants.STATUS_PAUSED)
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          _updateSubscriptionStatus(
                                            sub.id, 
                                            AppConstants.STATUS_PAUSED
                                          );
                                        },
                                        icon: const Icon(Icons.pause_circle_outline, color: Colors.black87),
                                        label: const Text('Pause'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.amber,
                                          foregroundColor: Colors.black87,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        ),
                                      ),
                                    ),
                                  
                                  // Cancel button
                                  if (sub.status != AppConstants.STATUS_CANCELLED)
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          _updateSubscriptionStatus(
                                            sub.id, 
                                            AppConstants.STATUS_CANCELLED
                                          );
                                        },
                                        icon: const Icon(Icons.cancel_outlined, color: Colors.white),
                                        label: const Text('Cancel'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Price and billing info
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.colorScheme.outline.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Payment Details',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Amount',
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                      Row(
                                        children: [
                                          if (currency != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              margin: const EdgeInsets.only(right: 8),
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                currency.flag,
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            ),
                                          Text(
                                            currencyFormatter.format(sub.amount),
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  
                                  const Divider(height: 32),
                                  
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Billing Cycle',
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                      Text(
                                        _getBillingCycleText(sub.billingCycle),
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Start Date',
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                      Text(
                                        AppDateUtils.formatDate(sub.startDate),
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Next Renewal',
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                      Flexible(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                AppDateUtils.formatDate(sub.renewalDate!),
                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (sub.isOverdue && sub.status == AppConstants.STATUS_ACTIVE)
                                              Container(
                                                margin: const EdgeInsets.only(left: 8),
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'Overdue',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            if (daysUntilRenewal != null && daysUntilRenewal < 3 && daysUntilRenewal >= 0 && sub.status == AppConstants.STATUS_ACTIVE)
                                              Container(
                                                margin: const EdgeInsets.only(left: 8),
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: daysUntilRenewal == 0 
                                                      ? Colors.red.withOpacity(0.1)
                                                      : Colors.orange.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  daysUntilRenewal == 0
                                                      ? 'Today'
                                                      : daysUntilRenewal == 1
                                                          ? 'Tomorrow'
                                                          : 'In $daysUntilRenewal days',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: daysUntilRenewal == 0
                                                        ? Colors.red
                                                        : Colors.orange,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Additional details
                            if (sub.category != null || sub.description != null)
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.colorScheme.outline.withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Additional Details',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    
                                    if (sub.category != null) ...[
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.category_rounded,
                                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Category:',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            sub.category!,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    
                                    if (sub.description != null) ...[
                                      const SizedBox(height: 16),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.description_rounded,
                                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Notes:',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        sub.description!,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            
                            const SizedBox(height: 24),
                            
                            // Notification settings
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.colorScheme.outline.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.notifications_active_rounded,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Notification Settings',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Renewal Notifications',
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: sub.notificationsEnabled
                                              ? colorScheme.primary.withOpacity(0.1)
                                              : Colors.grey.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          sub.notificationsEnabled ? 'Enabled' : 'Disabled',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: sub.notificationsEnabled
                                                ? colorScheme.primary
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  if (sub.notificationsEnabled) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          flex: 2,
                                          child: Text(
                                            'Notification Schedule',
                                            style: theme.textTheme.bodyLarge,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          flex: 3,
                                          child: Text(
                                            '${sub.notificationDays} days before renewal',
                                            style: theme.textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.end,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Annual cost calculation
                            if (sub.status == AppConstants.STATUS_ACTIVE)
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colorScheme.primary.withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Total Annual Cost',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      currencyFormatter.format(_calculateAnnualCost(sub)),
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    Text(
                                      'per year',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.primary.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            const SizedBox(height: 24),
                            
                            // Add "Mark as Paid" button for active subscriptions when today or overdue
                            if (sub.status == AppConstants.STATUS_ACTIVE && 
                                daysUntilRenewal != null && 
                                daysUntilRenewal <= 0) ...[
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: () => _markAsPaid(sub),
                                  icon: const Icon(Icons.check_circle_outline_rounded),
                                  label: const Text('Mark as Paid'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
  
  String _getBillingCycleText(String billingCycle) {
    switch (billingCycle) {
      case AppConstants.BILLING_CYCLE_MONTHLY:
        return 'Monthly';
      case AppConstants.BILLING_CYCLE_QUARTERLY:
        return 'Quarterly';
      case AppConstants.BILLING_CYCLE_YEARLY:
        return 'Yearly';
      default:
        return billingCycle;
    }
  }
  
  double _calculateAnnualCost(Subscription subscription) {
    switch (subscription.billingCycle) {
      case AppConstants.BILLING_CYCLE_MONTHLY:
        return subscription.amount * 12;
      case AppConstants.BILLING_CYCLE_QUARTERLY:
        return subscription.amount * 4;
      case AppConstants.BILLING_CYCLE_YEARLY:
        return subscription.amount;
      default:
        return subscription.amount;
    }
  }

  int _calculateDaysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final renewalDate = DateTime(date.year, date.month, date.day);
    return renewalDate.difference(today).inDays;
  }

  void _markAsPaid(Subscription subscription) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    
    // Call the markSubscriptionAsPaid method
    subscriptionProvider.markSubscriptionAsPaid(subscription.id).then((_) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${subscription.name} marked as paid'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              // Refresh the current screen to show updated renewal date
              Navigator.popAndPushNamed(
                context, 
                '/subscription_details',
                arguments: {'id': subscription.id},
              );
            },
          ),
        ),
      );
      
      // Navigate back to refresh the screen
      Navigator.pop(context);
    }).catchError((error) {
      // Show error message if something went wrong
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Could not mark subscription as paid'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }
} 