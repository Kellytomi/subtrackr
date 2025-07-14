import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/core/utils/color_extensions.dart';
import 'package:subtrackr/core/utils/currency_utils.dart';
import 'package:subtrackr/core/widgets/empty_state.dart';
import 'package:subtrackr/core/widgets/modern_spinner.dart';
import 'package:subtrackr/core/widgets/subscription_card.dart';
import 'package:subtrackr/data/services/settings_service.dart';
import 'package:subtrackr/domain/entities/subscription.dart';
import 'package:subtrackr/presentation/providers/subscription_provider.dart';
import 'package:subtrackr/presentation/providers/theme_provider.dart';
import 'package:subtrackr/presentation/widgets/home/app_header.dart';
import 'package:subtrackr/presentation/widgets/home/category_tabs.dart';
import 'package:subtrackr/presentation/widgets/home/summary_cards_section.dart';

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
  
  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  
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
    _searchController.dispose();
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
    final defaultCurrencyCode = settingsService.getCurrencyCode() ?? AppConstants.DEFAULT_CURRENCY_CODE;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // App Header (fixed)
            AppHeader(
              onSearchPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
            
            // Summary Cards - horizontal scrollable but fixed position
            SummaryCardsSection(defaultCurrencyCode: defaultCurrencyCode),
            
            // Search bar (when searching)
            if (_isSearching) 
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search subscriptions...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _isSearching = false;
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
            
            // Category Tabs (fixed) - hide when searching
            if (!_isSearching)
              CategoryTabs(
                selectedIndex: _selectedIndex,
                categories: _categories,
                onCategorySelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),
            
            // Subscription List (scrollable)
            Expanded(
              child: _buildSubscriptionList(
                _getFilteredSubscriptions(subscriptionProvider),
                defaultCurrencyCode,
              ),
            ),
          ],
        ),
      ),
      extendBody: true,
    );
  }

  List<Subscription> _getFilteredSubscriptions(SubscriptionProvider provider) {
    List<Subscription> subscriptions;
    
    // First filter by category if not searching
    if (_isSearching) {
      subscriptions = provider.subscriptions;
    } else {
      switch (_selectedIndex) {
        case 0: // All
          subscriptions = provider.subscriptions;
          break;
        case 1: // Active
          subscriptions = provider.activeSubscriptions;
          break;
        case 2: // Due Soon
          subscriptions = provider.subscriptionsDueSoon;
          break;
        case 3: // Paused
          subscriptions = provider.pausedSubscriptions;
          break;
        case 4: // Cancelled
          subscriptions = provider.cancelledSubscriptions;
          break;
        default:
          subscriptions = provider.subscriptions;
      }
    }
    
    // Then filter by search query if searching
    if (_isSearching && _searchQuery.isNotEmpty) {
      subscriptions = subscriptions.where((subscription) {
        return subscription.name.toLowerCase().contains(_searchQuery) ||
               (subscription.description?.toLowerCase().contains(_searchQuery) ?? false) ||
               (subscription.category?.toLowerCase().contains(_searchQuery) ?? false) ||
               (subscription.website?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }
    
    return subscriptions;
  }

  Widget _buildSubscriptionList(List<Subscription> subscriptions, String defaultCurrencyCode) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, child) {
        // Show loading state only when initially loading and no data yet
        if (subscriptionProvider.isLoading && subscriptions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ModernSpinner(
                  size: 48,
                  type: SpinnerType.pulse,
                  color: Theme.of(context).colorScheme.primary,
                  duration: const Duration(milliseconds: 1500),
                ),
                const SizedBox(height: 24),
                Text(
                  'Loading your subscriptions...',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This should only take a moment',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }
        
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
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            itemCount: subscriptions.length,
            itemBuilder: (context, index) {
              final subscription = subscriptions[index];
              return Padding(
                key: ValueKey('subscription_item_${subscription.id}'),
                padding: const EdgeInsets.only(bottom: 1.0),
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
      },
    );
  }

  void _navigateToSubscriptionDetails(Subscription subscription) {
    Navigator.pushNamed(
      context,
      AppConstants.SUBSCRIPTION_DETAILS_ROUTE,
      arguments: {'id': subscription.id},
    );
  }

  void _navigateToEditSubscription(Subscription subscription) {
    Navigator.pushNamed(
      context,
      AppConstants.EDIT_SUBSCRIPTION_ROUTE,
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