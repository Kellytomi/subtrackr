import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subtrackr/core/utils/currency_utils.dart';
import 'package:subtrackr/presentation/providers/subscription_provider.dart';
import 'package:subtrackr/presentation/widgets/home/summary_card.dart';

/// Summary cards section widget for displaying subscription statistics
class SummaryCardsSection extends StatefulWidget {
  final String defaultCurrencyCode;

  const SummaryCardsSection({
    super.key,
    required this.defaultCurrencyCode,
  });

  @override
  State<SummaryCardsSection> createState() => _SummaryCardsSectionState();
}

class _SummaryCardsSectionState extends State<SummaryCardsSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      // Trigger rebuild to update scroll indicators
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubscriptionProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    return _buildSummaryCards(provider, widget.defaultCurrencyCode, colorScheme);
  }

  Widget _buildSummaryCards(
    SubscriptionProvider provider, 
    String defaultCurrencyCode,
    ColorScheme colorScheme,
  ) {
    final activeCount = provider.activeSubscriptions.length;
    final dueSoonCount = provider.subscriptionsDueSoon.length;
    
    // Count local and foreign subscriptions
    int localSubscriptions = 0;
    int foreignSubscriptions = 0;
    
    for (final subscription in provider.activeSubscriptions) {
      if (subscription.currencyCode == defaultCurrencyCode) {
        localSubscriptions++;
      } else {
        foreignSubscriptions++;
      }
    }
    
    // Create summary cards - Due Soon first
    final summaryCards = <Widget>[
      SummaryCard(
        title: 'Due Soon',
        value: dueSoonCount.toString(),
        icon: Icons.notifications_active_rounded,
        color: colorScheme.tertiary,
      ),
      SummaryCard(
        title: 'Active Subscriptions',
        value: activeCount.toString(),
        icon: Icons.check_circle_rounded,
        color: colorScheme.primary,
      ),
    ];
    
    // Add local subscriptions card if there are any
    if (localSubscriptions > 0) {
      final currency = CurrencyUtils.getCurrencyByCode(defaultCurrencyCode) ?? 
          CurrencyUtils.getAllCurrencies().first;
      
      summaryCards.add(
        SummaryCard(
          title: 'Local Subscriptions',
          value: localSubscriptions.toString(),
          subtitle: currency.code,
          icon: Icons.home_rounded,
          color: colorScheme.secondary,
          flag: currency.flag,
        ),
      );
    }
    
    // Add foreign subscriptions card if there are any
    if (foreignSubscriptions > 0) {
      summaryCards.add(
        SummaryCard(
          title: 'Foreign Subscriptions',
          value: foreignSubscriptions.toString(),
          icon: Icons.language_rounded,
          color: Colors.indigo,
        ),
      );
    }
    
    // Calculate total width and visible width for scroll indicator
    final double cardWidth = 180.0 + 16.0; // card width + margin
    final double totalContentWidth = cardWidth * summaryCards.length;
    final double viewportWidth = MediaQuery.of(context).size.width - 40; // Accounting for padding
    
    // Calculate number of pages and scroll positions
    final int totalPages = (totalContentWidth / viewportWidth).ceil();
    final maxScrollExtent = totalContentWidth - viewportWidth;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 190,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            scrollDirection: Axis.horizontal,
            itemCount: summaryCards.length,
            itemBuilder: (context, index) => summaryCards[index],
          ),
        ),
        // Scroll indicators
        if (totalContentWidth > viewportWidth)
          Container(
            height: 8,
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalPages, (index) {
                // Calculate the active page based on scroll position
                final double scrollPercentage = _scrollController.hasClients && maxScrollExtent > 0
                    ? (_scrollController.offset / maxScrollExtent).clamp(0.0, 1.0)
                    : 0.0;
                final double activePosition = scrollPercentage * (totalPages - 1);
                final bool isActive = (index == activePosition.round());
                
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isActive ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? colorScheme.primary 
                        : colorScheme.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
} 