import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/core/theme/app_theme.dart';
import 'package:subtrackr/core/utils/currency_utils.dart';
import 'package:subtrackr/core/utils/date_utils.dart';
import 'package:subtrackr/data/services/logo_service.dart';
import 'package:subtrackr/domain/entities/subscription.dart';

class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final String? defaultCurrencySymbol;

  const SubscriptionCard({
    Key? key,
    required this.subscription,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.defaultCurrencySymbol,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.customColors;
    final logoService = Provider.of<LogoService>(context, listen: false);
    
    // Determine the status color
    Color statusColor;
    switch (subscription.status) {
      case AppConstants.statusActive:
        statusColor = customColors.activeSubscription;
        break;
      case AppConstants.statusPaused:
        statusColor = customColors.pausedSubscription;
        break;
      case AppConstants.statusCancelled:
        statusColor = customColors.cancelledSubscription;
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
    if (subscription.status == AppConstants.statusActive) {
      if (subscription.isOverdue) {
        renewalText = 'Overdue';
      } else {
        renewalText = 'Renews in ${AppDateUtils.getDaysRemainingText(subscription.renewalDate)}';
      }
    } else if (subscription.status == AppConstants.statusPaused) {
      renewalText = 'Paused';
    } else {
      renewalText = 'Cancelled';
    }

    return Slidable(
      key: ValueKey(subscription.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.6,
        children: [
          if (subscription.status == AppConstants.statusActive && onPause != null)
            SlidableAction(
              onPressed: (_) => onPause!(),
              backgroundColor: theme.colorScheme.surfaceVariant,
              foregroundColor: theme.colorScheme.tertiary,
              icon: Icons.pause_rounded,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              padding: const EdgeInsets.all(0),
              autoClose: true,
              label: 'Pause',
            ),
          if (subscription.status == AppConstants.statusPaused && onResume != null)
            SlidableAction(
              onPressed: (_) => onResume!(),
              backgroundColor: theme.colorScheme.surfaceVariant,
              foregroundColor: customColors.activeSubscription,
              icon: Icons.play_arrow_rounded,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              padding: const EdgeInsets.all(0),
              autoClose: true,
              label: 'Resume',
            ),
          if (subscription.status != AppConstants.statusCancelled && onCancel != null)
            SlidableAction(
              onPressed: (_) => onCancel!(),
              backgroundColor: theme.colorScheme.surfaceVariant,
              foregroundColor: customColors.cancelledSubscription,
              icon: Icons.cancel_rounded,
              padding: const EdgeInsets.all(0),
              autoClose: true,
              label: 'Cancel',
            ),
          if (onEdit != null)
            SlidableAction(
              onPressed: (_) => onEdit!(),
              backgroundColor: theme.colorScheme.surfaceVariant,
              foregroundColor: theme.colorScheme.primary,
              icon: Icons.edit_rounded,
              padding: const EdgeInsets.all(0),
              autoClose: true,
              label: 'Edit',
            ),
          if (onDelete != null)
            SlidableAction(
              onPressed: (_) => onDelete!(),
              backgroundColor: theme.colorScheme.surfaceVariant,
              foregroundColor: theme.colorScheme.error,
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
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            color: theme.colorScheme.surface,
            border: Border.all(
              color: theme.brightness == Brightness.dark 
                  ? Colors.white.withOpacity(0.1) 
                  : Colors.black.withOpacity(0.05),
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
                          color: theme.brightness == Brightness.dark 
                              ? Colors.white.withOpacity(0.1) 
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: subscription.logoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  subscription.logoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      logoService.getFallbackIcon(subscription.name),
                                      color: theme.brightness == Brightness.dark 
                                          ? Colors.white 
                                          : Colors.black,
                                      size: 28,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                logoService.getFallbackIcon(subscription.name),
                                color: theme.brightness == Brightness.dark 
                                    ? Colors.white 
                                    : Colors.black,
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
                                color: theme.brightness == Brightness.dark 
                                    ? Colors.white 
                                    : Colors.black,
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
                                    color: theme.brightness == Brightness.dark 
                                        ? Colors.white.withOpacity(0.8) 
                                        : Colors.black.withOpacity(0.8),
                                  ),
                                ),
                                if (subscription.currencyCode != defaultCurrencySymbol) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.brightness == Brightness.dark 
                                          ? Colors.white.withOpacity(0.1) 
                                          : Colors.black.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      currency.code,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: theme.brightness == Brightness.dark 
                                            ? Colors.white.withOpacity(0.7) 
                                            : Colors.black.withOpacity(0.7),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
                              subscription.statusText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (subscription.category != null) ...[
                    const SizedBox(height: 12),
                    // Category tag
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.category_rounded,
                              size: 12,
                              color: theme.colorScheme.primary.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              subscription.category!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Renewal information
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark 
                          ? Colors.white.withOpacity(0.1) 
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      renewalText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.brightness == Brightness.dark 
                            ? Colors.white.withOpacity(0.7) 
                            : Colors.black.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 