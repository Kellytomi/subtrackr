import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/core/utils/currency_utils.dart';
import 'package:subtrackr/core/utils/date_utils.dart';
import 'package:subtrackr/data/services/logo_service.dart';
import 'package:subtrackr/domain/entities/subscription.dart';
import 'package:subtrackr/presentation/blocs/subscription_provider.dart';

class SubscriptionDetailsScreen extends StatelessWidget {
  const SubscriptionDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    
    // Get the subscription ID from the route arguments
    final subscriptionId = ModalRoute.of(context)?.settings.arguments as String?;
    
    if (subscriptionId == null) {
      return _buildErrorScreen(context, 'Subscription ID not found');
    }
    
    // Get the subscription from the provider
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    
    // Find the subscription
    Subscription? foundSubscription;
    try {
      foundSubscription = subscriptionProvider.subscriptions.firstWhere(
        (s) => s.id == subscriptionId,
      );
    } catch (e) {
      // Subscription not found
    }
    
    if (foundSubscription == null) {
      return _buildErrorScreen(context, 'Subscription not found');
    }
    
    // Use a non-nullable subscription from here on
    final subscription = foundSubscription;
    
    // Get the logo service
    final logoService = Provider.of<LogoService>(context, listen: false);
    
    // Get currency information
    final currency = CurrencyUtils.getCurrencyByCode(subscription.currencyCode) ?? 
        CurrencyUtils.getAllCurrencies().first;
    
    // Format the amount with the currency symbol
    final formattedAmount = CurrencyUtils.formatCurrencyWithBillingCycle(
      subscription.amount,
      currency.symbol,
      subscription.billingCycle,
    );
    
    // Determine the status color
    Color statusColor;
    switch (subscription.status) {
      case AppConstants.statusActive:
        statusColor = colorScheme.primary;
        break;
      case AppConstants.statusPaused:
        statusColor = colorScheme.tertiary;
        break;
      case AppConstants.statusCancelled:
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.grey;
    }
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back, 
                      color: isDark ? Colors.white : Colors.black
                    ),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacementNamed(context, '/');
                      }
                    },
                    tooltip: 'Back',
                    style: IconButton.styleFrom(
                      backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Subscription Details',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Subscription content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Subscription header with logo and basic info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: subscription.logoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  subscription.logoUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      logoService.getFallbackIcon(subscription.name),
                                      color: isDark ? Colors.white : Colors.black,
                                      size: 40,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                logoService.getFallbackIcon(subscription.name),
                                color: isDark ? Colors.white : Colors.black,
                                size: 40,
                              ),
                      ),
                      const SizedBox(width: 20),
                      // Basic info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subscription.name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getStatusText(subscription.status),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  currency.flag,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  currency.code,
                                  style: TextStyle(
                                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Price section
                  _buildInfoSection(
                    context,
                    title: 'Price',
                    icon: Icons.attach_money,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedAmount,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getBillingCycleText(subscription.billingCycle),
                          style: TextStyle(
                            fontSize: 16,
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Renewal section
                  _buildInfoSection(
                    context,
                    title: 'Renewal',
                    icon: Icons.event,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (subscription.status == AppConstants.statusActive) ...[
                          Text(
                            subscription.isOverdue
                                ? 'Overdue'
                                : 'Next renewal in ${AppDateUtils.getDaysRemainingText(subscription.renewalDate)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: subscription.isOverdue
                                  ? Colors.red
                                  : (isDark ? Colors.white : Colors.black),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'on ${_formatDate(subscription.renewalDate)}',
                            style: TextStyle(
                              fontSize: 16,
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
                            ),
                          ),
                        ] else if (subscription.status == AppConstants.statusPaused) ...[
                          Text(
                            'Subscription is paused',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Resume to continue billing',
                            style: TextStyle(
                              fontSize: 16,
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Subscription is cancelled',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No further billing will occur',
                            style: TextStyle(
                              fontSize: 16,
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description section
                  if (subscription.description != null && subscription.description!.isNotEmpty)
                    _buildInfoSection(
                      context,
                      title: 'Description',
                      icon: Icons.description,
                      child: Text(
                        subscription.description!,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  
                  if (subscription.description != null && subscription.description!.isNotEmpty)
                    const SizedBox(height: 24),
                  
                  // Website section
                  if (subscription.website != null && subscription.website!.isNotEmpty)
                    _buildInfoSection(
                      context,
                      title: 'Website',
                      icon: Icons.language,
                      child: Text(
                        subscription.website!,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 40),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (subscription.status == AppConstants.statusActive)
                        _buildActionButton(
                          context,
                          icon: Icons.pause,
                          label: 'Pause',
                          color: colorScheme.tertiary,
                          onPressed: () => _showPauseConfirmationDialog(context, subscription),
                        )
                      else if (subscription.status == AppConstants.statusPaused)
                        _buildActionButton(
                          context,
                          icon: Icons.play_arrow,
                          label: 'Resume',
                          color: colorScheme.primary,
                          onPressed: () => _showResumeConfirmationDialog(context, subscription),
                        ),
                      
                      if (subscription.status != AppConstants.statusCancelled)
                        _buildActionButton(
                          context,
                          icon: Icons.cancel,
                          label: 'Cancel',
                          color: Colors.orange,
                          onPressed: () => _showCancelConfirmationDialog(context, subscription),
                        ),
                      
                      _buildActionButton(
                        context,
                        icon: Icons.delete,
                        label: 'Delete',
                        color: Colors.red,
                        onPressed: () => _showDeleteConfirmationDialog(context, subscription),
                      ),
                    ],
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
  
  Widget _buildErrorScreen(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back, 
                      color: isDark ? Colors.white : Colors.black
                    ),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacementNamed(context, '/');
                      }
                    },
                    tooltip: 'Back',
                    style: IconButton.styleFrom(
                      backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Subscription Details',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
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
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: child,
        ),
      ],
    );
  }
  
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: color,
          style: IconButton.styleFrom(
            backgroundColor: color.withOpacity(0.1),
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case AppConstants.statusActive:
        return 'Active';
      case AppConstants.statusPaused:
        return 'Paused';
      case AppConstants.statusCancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
  
  String _getBillingCycleText(String billingCycle) {
    switch (billingCycle) {
      case AppConstants.billingCycleMonthly:
        return 'Billed monthly';
      case AppConstants.billingCycleQuarterly:
        return 'Billed quarterly';
      case AppConstants.billingCycleYearly:
        return 'Billed yearly';
      case AppConstants.billingCycleCustom:
        return 'Custom billing cycle';
      default:
        return 'Unknown billing cycle';
    }
  }
  
  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
  
  void _showPauseConfirmationDialog(BuildContext context, Subscription subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pause Subscription'),
        content: Text(
          'Are you sure you want to pause ${subscription.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<SubscriptionProvider>(context, listen: false)
                  .pauseSubscription(subscription.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Subscription paused'),
                ),
              );
            },
            child: const Text('Pause'),
          ),
        ],
      ),
    );
  }
  
  void _showResumeConfirmationDialog(BuildContext context, Subscription subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resume Subscription'),
        content: Text(
          'Are you sure you want to resume ${subscription.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<SubscriptionProvider>(context, listen: false)
                  .resumeSubscription(subscription.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Subscription resumed'),
                ),
              );
            },
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }
  
  void _showCancelConfirmationDialog(BuildContext context, Subscription subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: Text(
          'Are you sure you want to cancel ${subscription.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<SubscriptionProvider>(context, listen: false)
                  .cancelSubscription(subscription.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Subscription cancelled'),
                ),
              );
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmationDialog(BuildContext context, Subscription subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subscription'),
        content: Text(
          'Are you sure you want to delete ${subscription.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<SubscriptionProvider>(context, listen: false)
                  .deleteSubscription(subscription.id);
              Navigator.pop(context); // Pop back to previous screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${subscription.name} deleted'),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 