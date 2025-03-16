import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
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
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: colorScheme.surface,
              toolbarHeight: 70,
              leading: Container(),
              flexibleSpace: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final top = constraints.biggest.height;
                  final expandedHeight = 120.0;
                  final shrinkOffset = expandedHeight - top;
                  final progress = (shrinkOffset / (expandedHeight - kToolbarHeight)).clamp(0.0, 1.0);
                  
                  return FlexibleSpaceBar(
                    expandedTitleScale: 1.0,
                    titlePadding: EdgeInsets.only(
                      left: 20 + progress * 40,
                      bottom: 16,
                    ),
                    title: AnimatedOpacity(
                      duration: const Duration(milliseconds: 100),
                      opacity: progress > 0.5 ? 1.0 : 0.0,
                      child: Text(
                        AppConstants.appName,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    background: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colorScheme.surface,
                            colorScheme.surface.withOpacity(0.8),
                          ],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: _buildAppBar(colorScheme),
                    ),
                  );
                },
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Summary Cards
            _buildSummaryCards(subscriptionProvider, defaultCurrencyCode),
            
            // Category Tabs
            _buildCategoryTabs(colorScheme),
            
            // Subscription List
            Expanded(
              child: _buildSubscriptionList(
                _getFilteredSubscriptions(subscriptionProvider),
                defaultCurrencyCode,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 70, 20, 0),
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
          icon: Icons.public_rounded,
          color: const Color(0xFFFF9500),
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
        final isDark = theme.brightness == Brightness.dark;
        
        // Listen to scroll events
        horizontalScrollController.addListener(() {
          setState(() {}); // Rebuild to update indicator position
        });
        
        // Calculate indicator metrics
        final double scrollPercentage = horizontalScrollController.hasClients 
            ? horizontalScrollController.offset / (totalContentWidth - viewportWidth).clamp(0.0, 1.0)
            : 0.0;
        final double indicatorWidth = (viewportWidth / totalContentWidth) * viewportWidth;
        final double maxOffset = viewportWidth - indicatorWidth;
        final double indicatorPosition = scrollPercentage * maxOffset;
        
        return Column(
          children: [
            Container(
              height: 180,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                controller: horizontalScrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                children: summaryCards,
              ),
            ),
            // Dynamic scroll indicator
            if (totalContentWidth > viewportWidth) // Only show if content is scrollable
              Container(
                width: viewportWidth,
                height: 8, // Increased height to match onboarding indicator
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    summaryCards.length,
                    (index) {
                      // Calculate which card is currently most visible
                      final double cardWidth = 180.0 + 16.0; // card width + margin
                      final double scrollPosition = horizontalScrollController.hasClients 
                          ? horizontalScrollController.offset 
                          : 0.0;
                      final int activeCardIndex = (scrollPosition / cardWidth).round().clamp(0, summaryCards.length - 1);
                      
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: index == activeCardIndex ? 24 : 8,
                        decoration: BoxDecoration(
                          color: index == activeCardIndex 
                              ? (isDark ? Colors.white : colorScheme.primary)
                              : (isDark ? Colors.white.withOpacity(0.3) : colorScheme.primary.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  ),
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
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.brightness == Brightness.dark 
              ? Colors.white.withOpacity(0.1) 
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    size: 24,
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
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: theme.brightness == Brightness.dark 
                    ? Colors.white.withOpacity(0.7) 
                    : Colors.black.withOpacity(0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
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
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
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
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    _categories[index],
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
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

  Widget _buildSubscriptionList(List<Subscription> subscriptions, String defaultCurrencyCode) {
    if (subscriptions.isEmpty) {
      return EmptyState(
        title: 'No subscriptions found',
        message: _selectedIndex == 0
            ? 'Add your first subscription to start tracking your expenses.'
            : 'No subscriptions in this category.',
        icon: _selectedIndex == 1
            ? Icons.check_circle_rounded
            : _selectedIndex == 2
                ? Icons.notifications_active_rounded
                : _selectedIndex == 3
                    ? Icons.pause_circle_rounded
                    : Icons.cancel_rounded,
        onActionPressed: _selectedIndex == 0
            ? () {
                Navigator.pushNamed(context, AppConstants.addSubscriptionRoute);
              }
            : null,
        actionLabel: _selectedIndex == 0 ? 'Add Subscription' : null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
      itemCount: subscriptions.length,
      itemBuilder: (context, index) {
        final subscription = subscriptions[index];
        return SubscriptionCard(
          subscription: subscription,
          defaultCurrencySymbol: CurrencyUtils.getCurrencyByCode(defaultCurrencyCode)?.symbol ?? '\$',
          onTap: () {
            Navigator.pushNamed(
              context,
              AppConstants.subscriptionDetailsRoute,
              arguments: subscription.id,
            );
          },
          onEdit: () {
            Navigator.pushNamed(
              context,
              AppConstants.editSubscriptionRoute,
              arguments: subscription.id,
            );
          },
          onDelete: () {
            _showDeleteConfirmationDialog(subscription);
          },
          onPause: subscription.status == AppConstants.statusActive
              ? () {
                  _showPauseConfirmationDialog(subscription);
                }
              : null,
          onResume: subscription.status == AppConstants.statusPaused
              ? () {
                  _showResumeConfirmationDialog(subscription);
                }
              : null,
          onCancel: subscription.status != AppConstants.statusCancelled
              ? () {
                  _showCancelConfirmationDialog(subscription);
                }
              : null,
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(Subscription subscription) {
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppConstants.subscriptionDeletedSuccess),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPauseConfirmationDialog(Subscription subscription) {
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

  void _showResumeConfirmationDialog(Subscription subscription) {
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

  void _showCancelConfirmationDialog(Subscription subscription) {
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
} 