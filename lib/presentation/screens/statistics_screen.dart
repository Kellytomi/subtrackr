import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subtrackr/core/utils/currency_utils.dart';
import 'package:subtrackr/data/services/settings_service.dart';
import 'package:subtrackr/domain/entities/subscription.dart';
import 'package:subtrackr/presentation/blocs/subscription_provider.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = 'This Month';
  final TextEditingController _searchController = TextEditingController();
  bool _showFilterOptions = false;
  bool _showCurrencySelector = false;
  Currency? _selectedCurrency;
  String _searchQuery = '';
  
  // Date ranges for filtering
  late DateTime _startDate;
  late DateTime _endDate;
  
  @override
  void initState() {
    super.initState();
    // Initialize date range to current month
    _updateDateRange(_selectedPeriod);
    
    // Initialize search controller listener
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    
    // Delay initialization to avoid build-time errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeCurrency(context);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateDateRange(String period) {
    final now = DateTime.now();
    
    switch (period) {
      case 'This Week':
        // Start from the beginning of the current week (Monday)
        final weekday = now.weekday;
        _startDate = now.subtract(Duration(days: weekday - 1));
        _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
        _endDate = _startDate.add(const Duration(days: 6));
        break;
      case 'This Month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'Last Month':
        _startDate = DateTime(now.year, now.month - 1, 1);
        _endDate = DateTime(now.year, now.month, 0);
        break;
      case 'Last 6 months':
        _startDate = DateTime(now.year, now.month - 5, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'Last 12 months':
        _startDate = DateTime(now.year - 1, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      default:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
    }
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
  
  // Filter subscriptions based on selected period, currency, and search query
  List<Subscription> _getFilteredSubscriptions(List<Subscription> allSubscriptions) {
    return allSubscriptions.where((subscription) {
      // Filter by currency
      if (_selectedCurrency != null && subscription.currencyCode != _selectedCurrency!.code) {
        return false;
      }
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = subscription.name.toLowerCase();
        final category = subscription.category?.toLowerCase() ?? '';
        
        if (!name.contains(query) && !category.contains(query)) {
          return false;
        }
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
        case 'Last 12 months':
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
        case 'Last 12 months':
          categorySpending[category] = categorySpending[category]! + subscription.yearlyCost;
          break;
        default:
          categorySpending[category] = categorySpending[category]! + subscription.monthlyCost;
      }
    }
    
    return categorySpending;
  }
  
  // Get color for category
  Color _getCategoryColor(String category, int index) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
    ];
    
    // Use a hash of the category name to get a consistent color
    final hash = category.hashCode.abs() % colors.length;
    return colors[hash];
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
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
      appBar: null,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom header with back button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Text(
                        'Expense Insights',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),

                // Currency selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showCurrencySelector = true;
                        });
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedCurrency?.flag ?? '',
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedCurrency?.name ?? 'Select Currency',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: colorScheme.onSurface,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Total outflow section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'TOTAL OUTFLOW',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedCurrency?.symbol ?? '\$',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                NumberFormat('#,##0.00', 'en_US').format(totalSpending),
                                style: theme.textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Time period selector
                Center(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _showFilterOptions = true;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedPeriod,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: colorScheme.onSurface,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Spending comparison card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.trending_down,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          filteredSubscriptions.isEmpty 
                              ? 'No subscription data available'
                              : 'Total of ${filteredSubscriptions.length} active subscriptions',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Categories section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Categories',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: categorySpending.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceContainerHighest,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.receipt_outlined,
                                          size: 32,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No transaction to show',
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          color: colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  children: [
                                    // Pie chart for category distribution
                                    if (categorySpending.isNotEmpty)
                                      SizedBox(
                                        height: 200,
                                        child: PieChart(
                                          PieChartData(
                                            sections: sortedCategories.map((category) {
                                              final value = categorySpending[category]!;
                                              final percentage = value / totalSpending * 100;
                                              final index = sortedCategories.indexOf(category);
                                              
                                              return PieChartSectionData(
                                                color: _getCategoryColor(category, index),
                                                value: value,
                                                title: '${percentage.toStringAsFixed(0)}%',
                                                radius: 80,
                                                titleStyle: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              );
                                            }).toList(),
                                            sectionsSpace: 2,
                                            centerSpaceRadius: 40,
                                            startDegreeOffset: 180,
                                          ),
                                        ),
                                      ),
                                    
                                    const SizedBox(height: 24),
                                    
                                    // Category list
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: sortedCategories.length,
                                        itemBuilder: (context, index) {
                                          final category = sortedCategories[index];
                                          final amount = categorySpending[category]!;
                                          final percentage = amount / totalSpending * 100;
                                          
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 12),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 16,
                                                  height: 16,
                                                  decoration: BoxDecoration(
                                                    color: _getCategoryColor(category, index),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    category,
                                                    style: theme.textTheme.bodyLarge?.copyWith(
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '${_selectedCurrency?.symbol}${NumberFormat('#,##0.00', 'en_US').format(amount)}',
                                                  style: theme.textTheme.bodyLarge?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '(${percentage.toStringAsFixed(1)}%)',
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Filter overlay
            if (_showFilterOptions)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showFilterOptions = false;
                    });
                  },
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Column(
                      children: [
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                                child: Text(
                                  'Filter by',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              
                              // Search bar
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search here',
                                    hintStyle: TextStyle(
                                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                                      fontSize: 16,
                                    ),
                                    filled: true,
                                    fillColor: theme.colorScheme.surfaceContainerHighest,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Time period options
                              _buildFilterOption('This Week', 'This Week', theme),
                              _buildFilterOption('This Month', 'This Month', theme),
                              _buildFilterOption('Last Month', 'Last Month', theme),
                              _buildFilterOption('Last 6 months', 'Last 6 months', theme),
                              _buildFilterOption('Last 12 months', 'Last 12 months', theme),
                              
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Currency selector overlay
            if (_showCurrencySelector)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showCurrencySelector = false;
                    });
                  },
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Column(
                      children: [
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                                child: Text(
                                  'Select Currency',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              
                              // Currency list
                              SizedBox(
                                height: 300,
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  itemCount: CurrencyUtils.getAllCurrencies().length,
                                  itemBuilder: (context, index) {
                                    // Get sorted currencies with selected one at the top
                                    final currencies = _getSortedCurrencies();
                                    final currency = currencies[index];
                                    return _buildCurrencyOption(currency, theme);
                                  },
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String text, String value, ThemeData theme) {
    final isSelected = _selectedPeriod == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPeriod = value;
          _updateDateRange(value);
          _showFilterOptions = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.1),
                  width: 2,
                ),
                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: theme.colorScheme.onPrimary,
                    )
                  : null,
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              width: 1,
            ),
          ),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    currency.code,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  // Helper method to sort currencies with default currency at the top
  List<Currency> _getSortedCurrencies() {
    final allCurrencies = CurrencyUtils.getAllCurrencies();
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    final defaultCurrencyCode = settingsService.getCurrencyCode() ?? 'USD';
    final selectedCurrencyCode = _selectedCurrency?.code ?? '';
    
    // Create a new list to avoid modifying the original
    final sortedCurrencies = List<Currency>.from(allCurrencies);
    
    // First, find the selected currency (if different from default) and move it to position 1
    if (selectedCurrencyCode != defaultCurrencyCode) {
      final selectedIndex = sortedCurrencies.indexWhere((c) => c.code == selectedCurrencyCode);
      if (selectedIndex > 0) {
        final selectedCurrency = sortedCurrencies.removeAt(selectedIndex);
        sortedCurrencies.insert(1, selectedCurrency);
      }
    }
    
    // Then, find the default currency and move it to the top (position 0)
    final defaultIndex = sortedCurrencies.indexWhere((c) => c.code == defaultCurrencyCode);
    if (defaultIndex > 0) {
      final defaultCurrency = sortedCurrencies.removeAt(defaultIndex);
      sortedCurrencies.insert(0, defaultCurrency);
    }
    
    return sortedCurrencies;
  }
} 