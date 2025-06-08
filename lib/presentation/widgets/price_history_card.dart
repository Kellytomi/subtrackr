import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:subtrackr/core/utils/currency_utils.dart';
import 'package:subtrackr/domain/entities/price_change.dart';
import 'package:subtrackr/domain/entities/subscription.dart';

class PriceHistoryCard extends StatelessWidget {
  final Subscription subscription;
  final List<PriceChange> priceHistory;

  const PriceHistoryCard({
    super.key,
    required this.subscription,
    required this.priceHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currency = CurrencyUtils.getCurrencyByCode(subscription.currencyCode);
    final currencySymbol = currency?.symbol ?? '\$';

    // Show example data for new users if no real price changes exist
    List<PriceChange> displayHistory = priceHistory;
    bool showingExampleData = false;
    
    if (priceHistory.isEmpty) {
      showingExampleData = true;
      // Create example price changes to show what the feature looks like
      displayHistory = [
        PriceChange(
          id: 'example_1',
          subscriptionId: subscription.id,
          oldPrice: subscription.amount * 0.8, // 20% lower
          newPrice: subscription.amount,
          effectiveDate: DateTime.now().add(const Duration(days: 30)),
          reason: 'Annual price adjustment',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        PriceChange(
          id: 'example_2',
          subscriptionId: subscription.id,
          oldPrice: subscription.amount * 0.6, // Show a larger historical increase
          newPrice: subscription.amount * 0.8,
          effectiveDate: DateTime.now().subtract(const Duration(days: 90)),
          reason: 'Feature expansion',
          createdAt: DateTime.now().subtract(const Duration(days: 91)),
        ),
      ];
    }

    // Sort price changes by effective date (newest first)
    final sortedHistory = [...displayHistory];
    sortedHistory.sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));

    // Separate upcoming and past changes
    final now = DateTime.now();
    final upcomingChanges = sortedHistory.where((change) => change.effectiveDate.isAfter(now)).toList();
    final pastChanges = sortedHistory.where((change) => !change.effectiveDate.isAfter(now)).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Price History',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                // Demo indicator
                if (showingExampleData)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Demo',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),

                      // Upcoming changes section
            if (upcomingChanges.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Upcoming Price Changes',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            
            // Upcoming changes list
            ...upcomingChanges.map((change) => _buildPriceChangeItem(
              context,
              change,
              currencySymbol,
              isUpcoming: true,
            )),
            
            if (pastChanges.isNotEmpty) const Divider(height: 24),
          ],

          // Past changes section
          if (pastChanges.isNotEmpty) ...[
            if (upcomingChanges.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Past Changes',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else 
              const SizedBox(height: 16),
            
            const SizedBox(height: 8),
            
            // Past changes list
            ...pastChanges.map((change) => _buildPriceChangeItem(
              context,
              change,
              currencySymbol,
              isUpcoming: false,
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceChangeItem(
    BuildContext context,
    PriceChange change,
    String currencySymbol, {
    required bool isUpcoming,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final isIncrease = change.newPrice > change.oldPrice;
    final priceChangeColor = isIncrease ? Colors.red : Colors.green;
    final priceChangeIcon = isIncrease ? Icons.trending_up : Icons.trending_down;
    
    final priceDifference = (change.newPrice - change.oldPrice).abs();
    final percentageChange = ((change.newPrice - change.oldPrice) / change.oldPrice * 100).abs();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUpcoming 
            ? Colors.orange.withOpacity(0.05)
            : colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: isUpcoming 
            ? Border.all(color: Colors.orange.withOpacity(0.2))
            : null,
      ),
      child: Row(
        children: [
          // Price change indicator
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: priceChangeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              priceChangeIcon,
              color: priceChangeColor,
              size: 16,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Price change details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$currencySymbol${change.oldPrice.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$currencySymbol${change.newPrice.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 2),
                
                Row(
                  children: [
                    Text(
                      '${isIncrease ? '+' : '-'}$currencySymbol${priceDifference.toStringAsFixed(2)} (${percentageChange.toStringAsFixed(1)}%)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: priceChangeColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM dd, yyyy').format(change.effectiveDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                
                if (change.reason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    change.reason!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Date badge for upcoming changes
          if (isUpcoming) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getTimeDifference(change.effectiveDate),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getTimeDifference(DateTime effectiveDate) {
    final now = DateTime.now();
    final difference = effectiveDate.difference(now);
    
    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).round();
      return 'in ${months}mo';
    } else if (difference.inDays > 0) {
      return 'in ${difference.inDays}d';
    } else {
      return 'today';
    }
  }
} 