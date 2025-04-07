import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/core/utils/currency_utils.dart';
import 'package:subtrackr/core/utils/date_utils.dart';
import 'package:subtrackr/data/services/logo_service.dart';
import 'package:subtrackr/domain/entities/subscription.dart';
import 'package:subtrackr/presentation/blocs/subscription_provider.dart';
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
        const SnackBar(content: Text(AppConstants.subscriptionDeletedSuccess)),
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
    
    if (subscription != null) {
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
  }
  
  String _getStatusActionText(String status) {
    switch (status) {
      case AppConstants.statusActive:
        return 'activated';
      case AppConstants.statusPaused:
        return 'paused';
      case AppConstants.statusCancelled:
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
        appBar: AppBar(title: const Text('Subscription Details')),
        body: const Center(child: Text('Subscription not found')),
      );
    }
    
    // Get subscription from provider
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final subscription = subscriptionProvider.subscriptions.firstWhere(
      (s) => s.id == subscriptionId,
      orElse: () => throw Exception('Subscription not found'),
    );
    
    if (subscription == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Subscription Details')),
        body: const Center(child: Text('Subscription not found')),
      );
    }
    
    // Format subscription details
    final currencyFormatter = NumberFormat.currency(
      symbol: CurrencyUtils.getCurrencyByCode(subscription.currencyCode)?.symbol ?? '\$',
      decimalDigits: 2,
    );
    
    // Determine status color
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (subscription.status) {
      case AppConstants.statusActive:
        statusColor = colorScheme.primary;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Active';
        break;
      case AppConstants.statusPaused:
        statusColor = colorScheme.tertiary;
        statusIcon = Icons.pause_circle_rounded;
        statusText = 'Paused';
        break;
      case AppConstants.statusCancelled:
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
    final daysUntilRenewal = subscription.renewalDate != null
      ? _calculateDaysUntil(subscription.renewalDate!)
      : null;
      
    // Get currency data
    final currency = CurrencyUtils.getCurrencyByCode(subscription.currencyCode);
    
    return Scaffold(
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
                                arguments: {'id': subscription.id},
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
                            onPressed: () => _deleteSubscription(context, subscription.id),
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
                                if (subscription.logoUrl != null)
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
                                        tag: 'no_hero_animation_details_${subscription.id}',
                                        flightShuttleBuilder: (_, __, ___, ____, _____) => 
                                          const SizedBox.shrink(),
                                        child: Image.network(
                                          subscription.logoUrl!,
                                          key: ValueKey('details_${subscription.id}_logo'),
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) {
                                            final logoService = Provider.of<LogoService>(context, listen: false);
                                            return Container(
                                              color: colorScheme.primary,
                                              child: Icon(
                                                logoService.getFallbackIcon(subscription.name),
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
                                        subscription.name.substring(0, 1).toUpperCase(),
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
                                  subscription.name,
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (subscription.website != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      subscription.website!,
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
                            child: AppTip(
                              tipKey: TipsHelper.quickActionsKey,
                              title: 'Quick Actions',
                              message: 'Easily change your subscription status with these buttons. Pause temporarily or cancel a subscription you no longer need.',
                              icon: Icons.touch_app,
                              position: TipPosition.bottom,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Activate button
                                  if (subscription.status != AppConstants.statusActive)
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          _updateSubscriptionStatus(
                                            subscription.id, 
                                            AppConstants.statusActive
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
                                  if (subscription.status != AppConstants.statusPaused)
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          _updateSubscriptionStatus(
                                            subscription.id, 
                                            AppConstants.statusPaused
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
                                  if (subscription.status != AppConstants.statusCancelled)
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          _updateSubscriptionStatus(
                                            subscription.id, 
                                            AppConstants.statusCancelled
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
                                          currencyFormatter.format(subscription.amount),
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
                                      _getBillingCycleText(subscription.billingCycle),
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
                                      AppDateUtils.formatDate(subscription.startDate),
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                if (subscription.renewalDate != null) ...[
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
                                                AppDateUtils.formatDate(subscription.renewalDate!),
                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (subscription.isOverdue && subscription.status == AppConstants.statusActive)
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
                                            if (daysUntilRenewal != null && daysUntilRenewal < 3 && daysUntilRenewal >= 0 && subscription.status == AppConstants.statusActive)
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
                          if (subscription.category != null || subscription.description != null)
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
                                  
                                  if (subscription.category != null) ...[
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
                                          subscription.category!,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  
                                  if (subscription.description != null) ...[
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
                                      subscription.description!,
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
                                        color: subscription.notificationsEnabled
                                            ? colorScheme.primary.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        subscription.notificationsEnabled ? 'Enabled' : 'Disabled',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: subscription.notificationsEnabled
                                              ? colorScheme.primary
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                if (subscription.notificationsEnabled) ...[
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
                                          '${subscription.notificationDays} days before renewal',
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
                          if (subscription.status == AppConstants.statusActive)
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
                                    currencyFormatter.format(_calculateAnnualCost(subscription)),
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
                          if (subscription.status == AppConstants.statusActive && 
                              daysUntilRenewal != null && daysUntilRenewal <= 0) ...[
                            // Debug print before the widget
                            SizedBox(
                              height: 1,
                              child: Builder(builder: (context) {
                                print('DEBUG DETAILS: Status: ${subscription.status}, daysUntilRenewal: $daysUntilRenewal, RenewalDate: ${subscription.renewalDate}, isOverdue: ${subscription.isOverdue}');
                                return Container();
                              }),
                            ),
                            const SizedBox(height: 24),
                            AppTip(
                              tipKey: TipsHelper.historyTipKey,
                              title: 'Mark Payments',
                              message: 'When a subscription is due or overdue, you can mark it as paid here. This will update the renewal date and add to payment history.',
                              icon: Icons.history,
                              position: TipPosition.top,
                              child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: () => _markAsPaid(subscription),
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
    );
  }
  
  String _getBillingCycleText(String billingCycle) {
    switch (billingCycle) {
      case AppConstants.billingCycleMonthly:
        return 'Monthly';
      case AppConstants.billingCycleQuarterly:
        return 'Quarterly';
      case AppConstants.billingCycleYearly:
        return 'Yearly';
      default:
        return billingCycle;
    }
  }
  
  double _calculateAnnualCost(Subscription subscription) {
    switch (subscription.billingCycle) {
      case AppConstants.billingCycleMonthly:
        return subscription.amount * 12;
      case AppConstants.billingCycleQuarterly:
        return subscription.amount * 4;
      case AppConstants.billingCycleYearly:
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