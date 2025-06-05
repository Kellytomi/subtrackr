import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/core/utils/color_extensions.dart';
import 'package:subtrackr/core/utils/currency_utils.dart';
import 'package:subtrackr/core/widgets/empty_state.dart';
import 'package:subtrackr/core/widgets/subscription_card.dart';
import 'package:subtrackr/data/services/settings_service.dart';
import 'package:subtrackr/domain/entities/subscription.dart';
import 'package:subtrackr/presentation/blocs/subscription_provider.dart';
import 'package:subtrackr/presentation/blocs/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final List<String> _categories = ['All', 'Active', 'Due Soon', 'Paused', 'Cancelled'];
  late ScrollController _scrollController;
  bool _isScrolled = false;
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
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
    
    // Start animation after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    if (_scrollController.offset > 0 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 0 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final defaultCurrencyCode = settingsService.getCurrencyCode() ?? AppConstants.defaultCurrencyCode;
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App Header (fixed)
            _buildAppHeader(colorScheme),
            
            // Summary Cards - horizontal scrollable but fixed position
            _buildSummaryCards(subscriptionProvider, defaultCurrencyCode),
            
            // Category Tabs (fixed)
            _buildCategoryTabs(colorScheme),
            
            // Subscription List (scrollable)
            Expanded(
              child: _buildSubscriptionList(
                _getFilteredSubscriptions(subscriptionProvider),
                defaultCurrencyCode,
                theme,
              ),
            ),
          ],
        ),
      ),
      // Configure snackbar behavior
      extendBody: true,
    );
  }

  Widget _buildAppHeader(ColorScheme colorScheme) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track your subscriptions',
            style: TextStyle(
              fontSize: 16,
              color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(SubscriptionProvider provider, String defaultCurrencyCode) {
    final activeCount = provider.activeSubscriptions.length;
    final dueSoonCount = provider.subscriptionsDueSoon.length;
    final colorScheme = Theme.of(context).colorScheme;
    
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
      _buildSummaryCard(
        title: 'Due Soon',
        value: dueSoonCount.toString(),
        icon: Icons.notifications_active_rounded,
        color: colorScheme.tertiary,
      ),
      
      _buildSummaryCard(
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
        _buildSummaryCard(
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
        _buildSummaryCard(
          title: 'Foreign Subscriptions',
          value: foreignSubscriptions.toString(),
          icon: Icons.language_rounded,
          color: Colors.indigo,
        ),
      );
    }
    
    // Create a scroll controller for the horizontal list
    final ScrollController horizontalScrollController = ScrollController();
    
    return StatefulBuilder(
      builder: (context, setState) {
        // Calculate total width and visible width for scroll indicator
        final double cardWidth = 180.0 + 16.0; // card width + margin
        final double totalContentWidth = cardWidth * summaryCards.length;
        final double viewportWidth = MediaQuery.of(context).size.width - 40; // Accounting for padding
        final theme = Theme.of(context);
        
        // Calculate number of pages and scroll positions
        final int totalPages = (totalContentWidth / viewportWidth).ceil();
        final maxScrollExtent = totalContentWidth - viewportWidth;
        
        // Listen to scroll events
        horizontalScrollController.addListener(() {
          setState(() {}); // Rebuild to update indicator position
        });
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 190, // Increased height to accommodate all content
              child: ListView.builder(
                controller: horizontalScrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                scrollDirection: Axis.horizontal,
                itemCount: summaryCards.length,
                itemBuilder: (context, index) => summaryCards[index],
              ),
            ),
            // Scroll indicators
            if (totalContentWidth > viewportWidth) // Only show if content is scrollable
              Container(
                height: 8,
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalPages, (index) {
                    // Calculate the active page based on scroll position
                    final double scrollPercentage = horizontalScrollController.hasClients && maxScrollExtent > 0
                        ? (horizontalScrollController.offset / maxScrollExtent).clamp(0.0, 1.0)
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
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    String? flag,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(right: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: theme.colorScheme.surface,
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon and flag row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22, // Slightly smaller icon
                  ),
                ),
                if (flag != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    flag,
                    style: const TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 10), // Reduced spacing
            
            // Value (number)
            Text(
              value,
              style: TextStyle(
                fontSize: 26, // Slightly smaller font size
                fontWeight: FontWeight.bold,
                color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 2), // Reduced spacing
            
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.brightness == Brightness.dark 
                    ? Colors.white.withOpacity(0.7) 
                    : Colors.black.withOpacity(0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Subtitle (optional)
            if (subtitle != null) ...[
              const SizedBox(height: 2), // Reduced spacing
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.brightness == Brightness.dark 
                      ? Colors.white.withOpacity(0.5) 
                      : Colors.black.withOpacity(0.5),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(ColorScheme colorScheme) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      height: 50,
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: List.generate(_categories.length, (index) {
          final isSelected = _selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    _categories[index],
                    style: TextStyle(
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  List<Subscription> _getFilteredSubscriptions(SubscriptionProvider provider) {
    switch (_selectedIndex) {
      case 0: // All
        return provider.subscriptions;
      case 1: // Active
        return provider.activeSubscriptions;
      case 2: // Due Soon
        return provider.subscriptionsDueSoon;
      case 3: // Paused
        return provider.pausedSubscriptions;
      case 4: // Cancelled
        return provider.cancelledSubscriptions;
      default:
        return provider.subscriptions;
    }
  }

  Widget _buildSubscriptionList(List<Subscription> subscriptions, String defaultCurrencyCode, ThemeData theme) {
    if (subscriptions.isEmpty) {
      return const EmptyState(
        icon: Icons.subscriptions,
        title: 'No Subscriptions',
        message: 'Add your first subscription to get started',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<SubscriptionProvider>(context, listen: false).loadSubscriptions();
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        itemCount: subscriptions.length,
        itemBuilder: (context, index) {
          final subscription = subscriptions[index];
          return Padding(
            key: ValueKey('subscription_item_${subscription.id}'),
            padding: const EdgeInsets.only(bottom: 8.0),
            child: SubscriptionCard(
              key: ValueKey('subscription_card_${subscription.id}'),
              subscription: subscription,
              defaultCurrencySymbol: CurrencyUtils.getCurrencyByCode(defaultCurrencyCode)?.symbol ?? '\$',
              onTap: () => _navigateToSubscriptionDetails(subscription),
              onEdit: () => _navigateToEditSubscription(subscription),
              onDelete: () => _showDeleteConfirmation(subscription),
              onPause: () => _pauseSubscription(subscription),
              onResume: () => _resumeSubscription(subscription),
              onCancel: () => _cancelSubscription(subscription),
              onMarkAsPaid: () => _markSubscriptionAsPaid(subscription),
            ),
          );
        },
      ),
    );
  }

  void _navigateToSubscriptionDetails(Subscription subscription) {
    Navigator.pushNamed(
      context,
      AppConstants.subscriptionDetailsRoute,
      arguments: {'id': subscription.id},
    );
  }

  void _navigateToEditSubscription(Subscription subscription) {
    Navigator.pushNamed(
      context,
      AppConstants.editSubscriptionRoute,
      arguments: {'id': subscription.id},
    );
  }

  void _pauseSubscription(Subscription subscription) async {
    final provider = Provider.of<SubscriptionProvider>(context, listen: false);
    await provider.pauseSubscription(subscription.id);
  }

  void _resumeSubscription(Subscription subscription) async {
    final provider = Provider.of<SubscriptionProvider>(context, listen: false);
    await provider.resumeSubscription(subscription.id);
  }

  void _cancelSubscription(Subscription subscription) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text('Are you sure you want to cancel this subscription?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final provider = Provider.of<SubscriptionProvider>(context, listen: false);
      await provider.cancelSubscription(subscription.id);
    }
  }

  void _markSubscriptionAsPaid(Subscription subscription) async {
    final provider = Provider.of<SubscriptionProvider>(context, listen: false);
    await provider.markSubscriptionAsPaid(subscription.id);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${subscription.name} marked as paid'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showDeleteConfirmation(Subscription subscription) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subscription'),
        content: const Text('Are you sure you want to delete this subscription?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final provider = Provider.of<SubscriptionProvider>(context, listen: false);
      await provider.deleteSubscription(subscription.id);
    }
  }
} 