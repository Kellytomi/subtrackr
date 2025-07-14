import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subtrackr/core/utils/currency_utils.dart';
import 'package:subtrackr/data/services/settings_service.dart';
import 'package:subtrackr/domain/entities/subscription.dart';
import 'package:subtrackr/presentation/providers/subscription_provider.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> 
    with TickerProviderStateMixin {
  String _selectedPeriod = 'This Month';
  bool _showPeriodSelector = false;
  bool _showCurrencySelector = false;
  Currency? _selectedCurrency;
  
  // Animation controllers
  late AnimationController _chartAnimationController;
  late Animation<double> _chartAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.easeInOutCubic,
    );
    
    // Start animations
    _chartAnimationController.forward();
    
    // Initialize currency
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeCurrency(context);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _chartAnimationController.dispose();
    super.dispose();
  }

  void _initializeCurrency(BuildContext context) {
    try {
      final settingsService = Provider.of<SettingsService>(context, listen: false);
      final defaultCurrencyCode = settingsService.getCurrencyCode();
      if (defaultCurrencyCode != null) {
        _selectedCurrency = CurrencyUtils.getCurrencyByCode(defaultCurrencyCode);
      }
    } catch (e) {
      debugPrint('Error initializing currency: $e');
    }
    
    // Fallback to USD if no currency is set
    _selectedCurrency ??= CurrencyUtils.getCurrencyByCode('USD');
  }
  
  // Filter subscriptions based on selected currency
  List<Subscription> _getFilteredSubscriptions(List<Subscription> allSubscriptions) {
    return allSubscriptions.where((subscription) {
      // Filter by currency
      if (_selectedCurrency != null && subscription.currencyCode != _selectedCurrency!.code) {
        return false;
      }
      
      // Filter by status (only active subscriptions)
      if (subscription.status != 'active') {
        return false;
      }
      
      return true;
    }).toList();
  }
  
  // Calculate total spending for the selected period
  double _calculateTotalSpending(List<Subscription> subscriptions) {
    if (subscriptions.isEmpty) return 0;
    
    double total = 0;
    
    for (final subscription in subscriptions) {
      switch (_selectedPeriod) {
        case 'This Week':
        case 'This Month':
        case 'Last Month':
          total += subscription.monthlyCost;
          break;
        case 'Last 6 months':
          total += subscription.monthlyCost * 6;
          break;
        case 'This Year':
          total += subscription.yearlyCost;
          break;
        default:
          total += subscription.monthlyCost;
      }
    }
    
    return total;
  }
  
  // Calculate spending by category
  Map<String, double> _calculateSpendingByCategory(List<Subscription> subscriptions) {
    final Map<String, double> categorySpending = {};
    
    for (final subscription in subscriptions) {
      final category = subscription.category ?? 'Uncategorized';
      
      if (!categorySpending.containsKey(category)) {
        categorySpending[category] = 0;
      }
      
      switch (_selectedPeriod) {
        case 'This Week':
        case 'This Month':
        case 'Last Month':
          categorySpending[category] = categorySpending[category]! + subscription.monthlyCost;
          break;
        case 'Last 6 months':
          categorySpending[category] = categorySpending[category]! + subscription.monthlyCost * 6;
          break;
        case 'This Year':
          categorySpending[category] = categorySpending[category]! + subscription.yearlyCost;
          break;
        default:
          categorySpending[category] = categorySpending[category]! + subscription.monthlyCost;
      }
    }
    
    return categorySpending;
  }
  
  // Get modern solid colors for categories
  Color _getCategoryColor(String category) {
    const colorPalette = [
      Color(0xFF667EEA), // Purple
      Color(0xFF06BEB6), // Teal
      Color(0xFFF093FB), // Pink
      Color(0xFF4FACFE), // Blue
      Color(0xFFFA709A), // Coral
      Color(0xFF30CFD0), // Cyan
      Color(0xFFA8EDEA), // Mint
      Color(0xFFFF9A9E), // Peach
    ];
    
    final index = category.hashCode.abs() % colorPalette.length;
    return colorPalette[index];
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Ensure currency is initialized
    _selectedCurrency ??= CurrencyUtils.getCurrencyByCode('USD');
    
    // Get subscription data from provider
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final allSubscriptions = subscriptionProvider.subscriptions;
    final filteredSubscriptions = _getFilteredSubscriptions(allSubscriptions);
    
    // Calculate total spending
    final totalSpending = _calculateTotalSpending(filteredSubscriptions);
    
    // Calculate spending by category
    final categorySpending = _calculateSpendingByCategory(filteredSubscriptions);
    
    // Sort categories by spending amount (descending)
    final sortedCategories = categorySpending.keys.toList()
      ..sort((a, b) => categorySpending[b]!.compareTo(categorySpending[a]!));

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expense Insights',
                          style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Track your subscription spending',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                ),
                
                // Main content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Total spending card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDarkMode
                                  ? [const Color(0xFF1E1E1E), const Color(0xFF2D2D2D)]
                                  : [Colors.white, const Color(0xFFF8F9FA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkMode
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Currency and period selectors
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                // Currency selector
                                  InkWell(
                      onTap: () {
                        setState(() {
                          _showCurrencySelector = true;
                        });
                      },
                                    borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: theme.colorScheme.primary.withOpacity(0.3),
                                          width: 1,
                                        ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedCurrency?.flag ?? '',
                                            style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Text(
                                            _selectedCurrency?.code ?? 'USD',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                                            Icons.expand_more,
                              size: 16,
                              color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                  ),
                ),

                                  // Period selector
                                  InkWell(
                    onTap: () {
                      setState(() {
                                        _showPeriodSelector = true;
                      });
                    },
                                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                                        color: theme.colorScheme.secondary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: theme.colorScheme.secondary.withOpacity(0.3),
                                          width: 1,
                                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 14,
                                            color: theme.colorScheme.secondary,
                                          ),
                                          const SizedBox(width: 6),
                          Text(
                            _selectedPeriod,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                                            Icons.expand_more,
                            size: 16,
                                            color: theme.colorScheme.secondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                                ],
                ),

                              const SizedBox(height: 32),

                              // Total amount
                              Text(
                                'Total Spending',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              AnimatedBuilder(
                                animation: _chartAnimation,
                                builder: (context, child) {
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                      children: [
                                      Text(
                                        _selectedCurrency?.symbol ?? '\$',
                                        style: theme.textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.primary,
                          ),
                        ),
                                      Text(
                                        NumberFormat('#,##0.00').format(totalSpending * _chartAnimation.value),
                                        style: theme.textTheme.displaySmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -1,
                                          color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                                  );
                                },
                ),
                              const SizedBox(height: 8),
                            Text(
                                '${filteredSubscriptions.length} active subscriptions',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                                  ),
                                ],
                              ),
                            ),
                        
                        const SizedBox(height: 32),
                        
                        // Category breakdown
                        if (categorySpending.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                'Category Breakdown',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                '${sortedCategories.length} categories',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                          const SizedBox(height: 24),
                          
                          // Donut chart
                          Container(
                            height: 280,
                                                  decoration: BoxDecoration(
                              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                                                    boxShadow: [
                                                      BoxShadow(
                                  color: isDarkMode
                                      ? Colors.black.withOpacity(0.3)
                                      : Colors.black.withOpacity(0.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                                      ),
                                                    ],
                                                  ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: AnimatedBuilder(
                                animation: _chartAnimation,
                                builder: (context, child) {
                                  return Stack(
                                                      children: [
                                      PieChart(
                                        PieChartData(
                                          sections: sortedCategories.map((category) {
                                            final value = categorySpending[category]!;
                                            final percentage = value / totalSpending * 100;
                                            final color = _getCategoryColor(category);
                                            
                                            return PieChartSectionData(
                                              color: color,
                                              value: value * _chartAnimation.value,
                                              title: '',
                                              radius: 65,
                                            );
                                          }).toList(),
                                          sectionsSpace: 3,
                                          centerSpaceRadius: 60,
                                          startDegreeOffset: -90,
                                        ),
                                      ),
                                      // Center content
                                                          Center(
                                                              child: Column(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                            Icon(
                                              Icons.donut_large,
                                              color: theme.colorScheme.primary.withOpacity(0.3),
                                              size: 32,
                                            ),
                                            const SizedBox(height: 4),
                                                                  Text(
                                                                    'Total',
                                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                                                                  ),
                                            ),
                                            Text(
                                              '${_selectedCurrency?.symbol}${NumberFormat.compact().format(totalSpending)}',
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                                        fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.primary,
                                                                    ),
                                                                  ),
                                                                ],
                                                            ),
                                                          ),
                                                      ],
                                                  );
                                                },
                                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Category list
                          ...sortedCategories.map((category) {
                                                      final amount = categorySpending[category]!;
                                                      final percentage = amount / totalSpending * 100;
                            final color = _getCategoryColor(category);
                                                      
                                                                                                              return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                                                        decoration: BoxDecoration(
                                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDarkMode
                                        ? Colors.black.withOpacity(0.3)
                                        : Colors.black.withOpacity(0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            // Color indicator
                                                            Container(
                                    width: 48,
                                    height: 48,
                                                              decoration: BoxDecoration(
                                                                color: color,
                                      borderRadius: BorderRadius.circular(12),
                                                              ),
                                    child: Center(
                                      child: Icon(
                                        _getCategoryIcon(category),
                                        color: Colors.white,
                                        size: 24,
                                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                                            
                                  // Category info
                                                            Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                                                category,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                        const SizedBox(height: 4),
                                                            Text(
                                          '${percentage.toStringAsFixed(1)}% of total',
                                                              style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                  ),
                                  
                                  // Amount
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${_selectedCurrency?.symbol}${NumberFormat('#,##0.00').format(amount)}',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                                  ),
                                                ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _getPeriodLabel(),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: color,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                      ),
                          ),
                        ),
                      ],
                ),
              ],
            ),
                            );
                          }).toList(),
                        ] else ...[
                          // Empty state
                        Container(
                            height: 400,
                          decoration: BoxDecoration(
                              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                  color: isDarkMode
                                      ? Colors.black.withOpacity(0.3)
                                      : Colors.black.withOpacity(0.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                            child: Center(
                          child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.colorScheme.primary.withOpacity(0.2),
                                          theme.colorScheme.secondary.withOpacity(0.2),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.analytics_outlined,
                                      size: 40,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                              const SizedBox(height: 24),
                                  Text(
                                    'No Data Available',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add subscriptions to see insights',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                              
                              const SizedBox(height: 24),
                            ],
                    ),
                          ),
                        ),
                      ],
                    ),
            
            // Period selector overlay
            if (_showPeriodSelector)
              _buildOverlay(
                title: 'Select Period',
                onClose: () => setState(() => _showPeriodSelector = false),
                child: Column(
                  children: [
                    _buildPeriodOption('This Week', theme),
                    _buildPeriodOption('This Month', theme),
                    _buildPeriodOption('Last Month', theme),
                    _buildPeriodOption('Last 6 months', theme),
                    _buildPeriodOption('This Year', theme),
                  ],
                ),
              ),

            // Currency selector overlay
            if (_showCurrencySelector)
              _buildOverlay(
                title: 'Select Currency',
                onClose: () => setState(() => _showCurrencySelector = false),
                child: SizedBox(
                  height: 400,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: CurrencyUtils.getAllCurrencies().length,
                    itemBuilder: (context, index) {
                      final currency = CurrencyUtils.getAllCurrencies()[index];
                      return _buildCurrencyOption(currency, theme);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOverlay({
    required String title,
    required VoidCallback onClose,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
                  child: Container(
          color: Colors.black.withOpacity(0.5),
                    child: Column(
                      children: [
                        const Spacer(),
              GestureDetector(
                onTap: () {}, // Prevent closing when tapping content
                child: Container(
                          decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                      // Handle
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              
                      // Title
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: onClose,
                              icon: Icon(
                                Icons.close,
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                      ),
                      
                      // Content
                      child,
                    ],
                  ),
                ),
              ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodOption(String period, ThemeData theme) {
    final isSelected = _selectedPeriod == period;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
          _showPeriodSelector = false;
        });
        // Restart animation
        _chartAnimationController.reset();
        _chartAnimationController.forward();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              _getPeriodIcon(period),
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.5),
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                period,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(Currency currency, ThemeData theme) {
    final isSelected = _selectedCurrency?.code == currency.code;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCurrency = currency;
          _showCurrencySelector = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Text(
              currency.flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  Text(
                    '${currency.code} (${currency.symbol})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getPeriodIcon(String period) {
    switch (period) {
      case 'This Week':
        return Icons.view_week;
      case 'This Month':
        return Icons.calendar_view_month;
      case 'Last Month':
        return Icons.history;
      case 'Last 6 months':
        return Icons.date_range;
      case 'This Year':
        return Icons.calendar_today;
      default:
        return Icons.calendar_today;
    }
  }
  
  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'This Week':
        return 'per week';
      case 'This Month':
      case 'Last Month':
        return 'per month';
      case 'Last 6 months':
        return 'per 6 months';
      case 'This Year':
        return 'per year';
      default:
        return 'per month';
    }
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'entertainment':
        return Icons.movie_outlined;
      case 'music':
        return Icons.music_note_outlined;
      case 'streaming':
        return Icons.play_circle_outline;
      case 'fitness':
        return Icons.fitness_center_outlined;
      case 'productivity':
        return Icons.work_outline;
      case 'news':
        return Icons.newspaper_outlined;
      case 'education':
        return Icons.school_outlined;
      case 'cloud storage':
        return Icons.cloud_outlined;
      case 'gaming':
        return Icons.sports_esports_outlined;
      case 'food & drink':
        return Icons.restaurant_outlined;
      default:
        return Icons.category_outlined;
    }
  }
} 