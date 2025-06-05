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
      case AppConstants.statusActive:
        statusColor = customColors?.activeSubscription ?? Colors.green;
        break;
      case AppConstants.statusPaused:
        statusColor = customColors?.pausedSubscription ?? Colors.orange;
        break;
      case AppConstants.statusCancelled:
        statusColor = customColors?.cancelledSubscription ?? Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    // Get currency information
    final currency = CurrencyUtils.getCurrencyByCode(subscription.currencyCode) ?? 
        CurrencyUtils.getAllCurrencies().firstWhere(
          (c) => c.code == AppConstants.defaultCurrencyCode,
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
    
    if (subscription.status == AppConstants.statusActive) {
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
    } else if (subscription.status == AppConstants.statusPaused) {
      renewalText = 'Paused';
    } else {
      renewalText = 'Cancelled';
    }

    // Check if subscription is due today or overdue
    final bool isDueNowOrOverdue = subscription.status == AppConstants.statusActive && 
        (AppDateUtils.isToday(subscription.renewalDate) || subscription.isOverdue);
    
    return Material(
      color: Colors.transparent,
      child: Slidable(
        key: ValueKey(subscription.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.6,
          children: [
            if (subscription.status == AppConstants.statusActive && onPause != null)
              SlidableAction(
                onPressed: (_) => onPause!(),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                icon: Icons.pause_rounded,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                padding: const EdgeInsets.all(0),
                autoClose: true,
                label: 'Pause',
              ),
            if (subscription.status == AppConstants.statusPaused && onResume != null)
              SlidableAction(
                onPressed: (_) => onResume!(),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                icon: Icons.play_arrow_rounded,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                padding: const EdgeInsets.all(0),
                autoClose: true,
                label: 'Resume',
              ),
            if (subscription.status != AppConstants.statusCancelled && onCancel != null)
              SlidableAction(
                onPressed: (_) => onCancel!(),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                icon: Icons.cancel_rounded,
                padding: const EdgeInsets.all(0),
                autoClose: true,
                label: 'Cancel',
              ),
            if (onEdit != null)
              SlidableAction(
                onPressed: (_) => onEdit!(),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                icon: Icons.edit_rounded,
                padding: const EdgeInsets.all(0),
                autoClose: true,
                label: 'Edit',
              ),
            // Mark as Paid action (only for active subscriptions that are due or overdue)
            if (subscription.status == AppConstants.statusActive && 
                isDueNowOrOverdue && 
                onMarkAsPaid != null)
              SlidableAction(
                onPressed: (_) => onMarkAsPaid!(),
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                icon: Icons.check_circle_outline,
                padding: const EdgeInsets.all(0),
                autoClose: true,
                label: 'Mark Paid',
                borderRadius: BorderRadius.zero,
              ),
            if (onDelete != null)
              SlidableAction(
                onPressed: (_) => onDelete!(),
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.onErrorContainer,
                icon: Icons.delete_rounded,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                padding: const EdgeInsets.all(0),
                autoClose: true,
                label: 'Delete',
              ),
          ],
        ),
        child: Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              color: theme.colorScheme.surface,
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Logo or icon with gradient background
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: subscription.logoUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Hero(
                                    tag: 'card_logo_${subscription.id}_${key.hashCode}',
                                    flightShuttleBuilder: (_, __, ___, ____, _____) => 
                                      const SizedBox.shrink(),
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
                              Text(
                                subscription.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    formattedAmount,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (subscription.currencyCode != defaultCurrencySymbol) ...[
                                    const SizedBox(width: 4),
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
                            ],
                          ),
                        ),
                        // Status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: statusColor.withOpacity(0.7),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                subscription.status == AppConstants.statusActive
                                    ? 'Active'
                                    : subscription.status == AppConstants.statusPaused
                                        ? 'Paused'
                                        : 'Cancelled',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Renewal info
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          renewalText,
                          style: TextStyle(
                            fontSize: 12,
                            color: renewalTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // Add category tag if available
                        if (subscription.category != null) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              subscription.category!,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
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
    );
  }
} 