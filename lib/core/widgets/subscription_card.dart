import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/core/theme/app_theme.dart';
import 'package:subtrackr/core/utils/currency_utils.dart';
import 'package:subtrackr/core/utils/date_utils.dart';
import 'package:subtrackr/core/widgets/app_tip.dart';
import 'package:subtrackr/core/utils/tips_helper.dart';
import 'package:subtrackr/data/services/logo_service.dart';
import 'package:subtrackr/domain/entities/subscription.dart';

class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final VoidCallback? onEdit;
  final VoidCallback? onMarkAsPaid;
  final String? defaultCurrencySymbol;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    required this.onTap,
    this.onDelete,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onEdit,
    this.onMarkAsPaid,
    this.defaultCurrencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColorsExtension>();
    final logoService = Provider.of<LogoService>(context, listen: false);
    
    // Determine the status color with fallbacks
    Color statusColor;
    switch (subscription.status) {
      case AppConstants.STATUS_ACTIVE:
        statusColor = customColors?.activeSubscription ?? Colors.green;
        break;
      case AppConstants.STATUS_PAUSED:
        statusColor = customColors?.pausedSubscription ?? Colors.orange;
        break;
      case AppConstants.STATUS_CANCELLED:
        statusColor = customColors?.cancelledSubscription ?? Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    // Get currency information
    final currency = CurrencyUtils.getCurrencyByCode(subscription.currencyCode) ?? 
        CurrencyUtils.getAllCurrencies().firstWhere(
          (c) => c.code == AppConstants.DEFAULT_CURRENCY_CODE,
          orElse: () => CurrencyUtils.getAllCurrencies().first,
        );

    // Format the amount with the currency symbol
    final formattedAmount = CurrencyUtils.formatCurrencyWithBillingCycle(
      subscription.amount,
      currency.symbol,
      subscription.billingCycle,
    );
    
    // Get days until renewal text
    String renewalText;
    Color renewalTextColor = theme.colorScheme.onSurface.withOpacity(0.8);
    
    if (subscription.status == AppConstants.STATUS_ACTIVE) {
      if (subscription.isOverdue) {
        renewalText = 'Overdue';
        renewalTextColor = theme.colorScheme.error;
      } else {
        final daysText = AppDateUtils.getDaysRemainingText(subscription.renewalDate);
        // Don't include "in" for "Today" or "Tomorrow"
        renewalText = daysText == 'Today' || daysText == 'Tomorrow' 
            ? 'Renews $daysText' 
            : 'Renews in $daysText';
             
        // Make "Renews Today" red
        if (daysText == 'Today') {
          renewalTextColor = theme.colorScheme.error;
        }
      }
    } else if (subscription.status == AppConstants.STATUS_PAUSED) {
      renewalText = 'Paused';
    } else {
      renewalText = 'Cancelled';
    }

    // Check if subscription is due today or overdue
    final bool isDueNowOrOverdue = subscription.status == AppConstants.STATUS_ACTIVE && 
        (AppDateUtils.isToday(subscription.renewalDate) || subscription.isOverdue);
    
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Slidable(
          key: ValueKey(subscription.id),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.65,
            children: [
              // Add a container to control the actual height of the action buttons
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      if (subscription.status == AppConstants.STATUS_ACTIVE && onPause != null)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHigh,
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                            ),
                            child: InkWell(
                              onTap: () => onPause!(),
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.pause_rounded, size: 20),
                                  SizedBox(height: 4),
                                  Text('Pause', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (subscription.status == AppConstants.STATUS_PAUSED && onResume != null)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHigh,
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                            ),
                            child: InkWell(
                              onTap: () => onResume!(),
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_arrow_rounded, size: 20),
                                  SizedBox(height: 4),
                                  Text('Resume', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (subscription.status != AppConstants.STATUS_CANCELLED && onCancel != null)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHigh,
                            ),
                            child: InkWell(
                              onTap: () => onCancel!(),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cancel_rounded, size: 20, color: theme.colorScheme.onSurface),
                                  const SizedBox(height: 4),
                                  Text('Cancel', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHigh,
                          ),
                          child: InkWell(
                            onTap: () => onEdit!(),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_rounded, size: 20, color: theme.colorScheme.onSurface),
                                const SizedBox(height: 4),
                                Text('Edit', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (subscription.status == AppConstants.STATUS_ACTIVE && 
                          isDueNowOrOverdue && 
                          onMarkAsPaid != null)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHigh,
                            ),
                            child: InkWell(
                              onTap: () => onMarkAsPaid!(),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 20, color: theme.colorScheme.onSurface),
                                  const SizedBox(height: 4),
                                  Text('Mark Paid', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (onDelete != null)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                            ),
                            child: InkWell(
                              onTap: () => onDelete!(),
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_rounded, size: 20, color: theme.colorScheme.onErrorContainer),
                                  const SizedBox(height: 4),
                                  Text('Delete', style: TextStyle(fontSize: 12, color: theme.colorScheme.onErrorContainer)),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                    spreadRadius: 0,
                  ),
                ],
                color: theme.colorScheme.surface,
                border: Border.all(
                  color: theme.brightness == Brightness.dark 
                      ? theme.colorScheme.outline.withOpacity(0.25)
                      : theme.colorScheme.outline.withOpacity(0.08),
                  width: theme.brightness == Brightness.dark ? 0.8 : 1,
                ),
              ),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Logo or icon with clean background
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.brightness == Brightness.dark 
                                      ? theme.colorScheme.outline.withOpacity(0.15)
                                      : theme.colorScheme.outline.withOpacity(0.06),
                                  width: 0.5,
                                ),
                              ),
                              child: subscription.logoUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: subscription.logoUrl!.startsWith('assets/')
                                          ? Image.asset(
                                              subscription.logoUrl!,
                                              key: ValueKey('card_${subscription.id}_logo'),
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Icon(
                                                  logoService.getFallbackIcon(subscription.name),
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                  size: 28,
                                                );
                                              },
                                            )
                                          : Image.network(
                                              subscription.logoUrl!,
                                              key: ValueKey('card_${subscription.id}_logo'),
                                              fit: BoxFit.contain,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Center(
                                                  child: CircularProgressIndicator(
                                                    value: loadingProgress.expectedTotalBytes != null
                                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                        : null,
                                                    strokeWidth: 2,
                                                    color: theme.colorScheme.onSurfaceVariant,
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) {
                                                return Icon(
                                                  logoService.getFallbackIcon(subscription.name),
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                  size: 28,
                                                );
                                              },
                                            ),
                                    )
                                  : Icon(
                                      logoService.getFallbackIcon(subscription.name),
                                      color: theme.colorScheme.onSurfaceVariant,
                                      size: 28,
                                    ),
                                                              ),
                            const SizedBox(width: 16),
                            // Subscription details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Service name with trial badge
                                  Row(
                                    children: [
                                      // Constrained service name - stop before currency/status area
                                      SizedBox(
                                        width: 180, // Fixed width to ensure truncation before currency badge
                                        child: Text(
                                          subscription.name,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: theme.colorScheme.onSurface,
                                            letterSpacing: -0.1,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Spacer(), // Push trial badge to the right
                                      if (_isCurrentlyInTrial(subscription))
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'TRIAL',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Price, currency, and status with proper spacing
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Wrap(
                                          children: [
                                            Text(
                                              formattedAmount,
                                              style: theme.textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                            if (subscription.currencyCode != defaultCurrencySymbol) ...[
                                              const SizedBox(width: 6),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: BackdropFilter(
                                                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: theme.colorScheme.primary.withOpacity(0.08),
                                                      border: Border.all(
                                                        color: theme.colorScheme.primary.withOpacity(0.15),
                                                        width: 0.5,
                                                      ),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          currency.flag,
                                                          style: const TextStyle(
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          subscription.currencyCode,
                                                          style: TextStyle(
                                                            color: theme.colorScheme.primary.withOpacity(0.8),
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Compact status indicator
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: statusColor.withOpacity(0.2),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 3,
                                              height: 3,
                                              decoration: BoxDecoration(
                                                color: statusColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              subscription.status == AppConstants.STATUS_ACTIVE
                                                  ? 'Active'
                                                  : subscription.status == AppConstants.STATUS_PAUSED
                                                      ? 'Paused'
                                                      : 'Cancelled',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                                color: statusColor,
                                                letterSpacing: 0.1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      // Renewal info
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            flex: 3,
                            child: Text(
                              renewalText,
                              style: TextStyle(
                                fontSize: 11,
                                color: renewalTextColor,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Add category tag if available
                          if (subscription.category != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.outline.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                subscription.category!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Check if a subscription is currently in its free trial period
  bool _isCurrentlyInTrial(Subscription subscription) {
    // A subscription is in trial if:
    // 1. Its description mentions "Free trial"
    // 2. The current date is before the renewal date (first billing)
    // 3. The subscription is active
    
    print('🔍 Checking trial status for ${subscription.name}:');
    print('   Status: ${subscription.status}');
    print('   Description: ${subscription.description}');
    print('   Renewal Date: ${subscription.renewalDate}');
    print('   Current Date: ${DateTime.now()}');
    
    if (subscription.status != AppConstants.STATUS_ACTIVE) {
      print('   ❌ Not active');
      return false;
    }
    
    // Check if description mentions free trial
    final description = subscription.description?.toLowerCase() ?? '';
    final isTrialSubscription = description.contains('free trial');
    
    print('   Free trial in description: $isTrialSubscription');
    
    if (!isTrialSubscription) {
      print('   ❌ No free trial in description');
      return false;
    }
    
    // Check if we're still before the first billing date
    final now = DateTime.now();
    final renewalDate = subscription.renewalDate;
    
    final isInFuture = renewalDate.isAfter(now);
    print('   Renewal in future: $isInFuture');
    
    // If renewal is in the future, and this was detected as a trial, we're still in trial
    final result = isInFuture;
    print('   Final result: $result');
    return result;
  }
} 