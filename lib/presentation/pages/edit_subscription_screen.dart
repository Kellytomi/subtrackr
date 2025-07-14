import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/core/utils/currency_utils.dart';
import 'package:subtrackr/core/utils/date_utils.dart';
import 'package:subtrackr/core/utils/text_formatters.dart';
import 'package:subtrackr/data/services/logo_service.dart';
import 'package:subtrackr/data/services/settings_service.dart';
import 'package:subtrackr/domain/entities/subscription.dart';
import 'package:subtrackr/presentation/providers/subscription_provider.dart';

class EditSubscriptionScreen extends StatefulWidget {
  const EditSubscriptionScreen({super.key});

  @override
  State<EditSubscriptionScreen> createState() => _EditSubscriptionScreenState();
}

class _EditSubscriptionScreenState extends State<EditSubscriptionScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String _billingCycle = AppConstants.BILLING_CYCLE_MONTHLY;
  DateTime _startDate = DateTime.now();
  DateTime _renewalDate = DateTime.now().add(const Duration(days: 30));
  String? _category;
  bool _notificationsEnabled = true;
  int _notificationDays = AppConstants.DEFAULT_NOTIFICATION_DAYS_BEFORE_RENEWAL;
  String _currencyCode = AppConstants.DEFAULT_CURRENCY_CODE;
  String? _currencySymbol;
  String? _logoUrl;
  String _status = AppConstants.STATUS_ACTIVE;
  
  List<LogoSuggestion> _logoSuggestions = [];
  bool _showLogoSuggestions = false;
  Timer? _debounceTimer;
  
  Subscription? _subscription;
  bool _isLoading = true;
  bool _hasChanges = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Entertainment', 'icon': Icons.movie_outlined, 'color': const Color(0xFF6366F1)},
    {'name': 'Productivity', 'icon': Icons.work_outline, 'color': const Color(0xFF06B6D4)},
    {'name': 'Utilities', 'icon': Icons.build_outlined, 'color': const Color(0xFF10B981)},
    {'name': 'Health & Fitness', 'icon': Icons.fitness_center_outlined, 'color': const Color(0xFFF59E0B)},
    {'name': 'Food & Drink', 'icon': Icons.restaurant_outlined, 'color': const Color(0xFFEF4444)},
    {'name': 'Shopping', 'icon': Icons.shopping_bag_outlined, 'color': const Color(0xFF8B5CF6)},
    {'name': 'Other', 'icon': Icons.category_outlined, 'color': const Color(0xFF6B7280)},
  ];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    _websiteController.addListener(_updateLogoFromWebsite);
    _nameController.addListener(_updateLogoFromName);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubscription();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _websiteController.removeListener(_updateLogoFromWebsite);
    _nameController.removeListener(_updateLogoFromName);
    
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _animationController.dispose();
    
    super.dispose();
  }

  void _updateLogoFromWebsite() {
    if (_logoUrl != null) return;
    
    final logoService = Provider.of<LogoService>(context, listen: false);
    final logoUrl = logoService.getLogoUrl(_websiteController.text);
    if (logoUrl != null) {
      setState(() {
        _logoUrl = logoUrl;
      });
    }
  }
  
  void _updateLogoFromName() {
    _debounceTimer?.cancel();
    
    if (_nameController.text.isEmpty) {
      setState(() {
        _logoSuggestions = [];
        _showLogoSuggestions = false;
      });
      return;
    }
    
    if (_logoUrl != null) {
      setState(() {
        _showLogoSuggestions = false;
      });
      return;
    }
    
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      _fetchLogoSuggestions(_nameController.text);
    });
  }
  
  void _fetchLogoSuggestions(String query) {
    if (!mounted || query.isEmpty) return;
    
    final logoService = Provider.of<LogoService>(context, listen: false);
    
    _getLogoSuggestionsWithRetry(logoService, query, 3).then((suggestions) {
      if (mounted && _nameController.text == query) {
        setState(() {
          _logoSuggestions = suggestions;
          _showLogoSuggestions = suggestions.isNotEmpty;
        });
      }
    });
  }
  
  Future<List<LogoSuggestion>> _getLogoSuggestionsWithRetry(
    LogoService logoService, 
    String query, 
    int retries,
  ) async {
    for (int i = 0; i < retries; i++) {
      try {
        final suggestions = await logoService.getLogoSuggestions(query);
        if (suggestions.isNotEmpty) {
          return suggestions;
        }
      } catch (error) {
        debugPrint('Logo suggestions attempt ${i + 1} failed: $error');
        if (i == retries - 1) {
          debugPrint('All logo suggestion attempts failed for query: $query');
        } else {
          await Future.delayed(Duration(milliseconds: 200 * (i + 1)));
        }
      }
    }
    return [];
  }
  
  void _loadSubscription() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final subscriptionId = args?['id'] as String?;
    
    if (subscriptionId == null) {
      setState(() {
        _isLoading = false;
      });
      _showErrorAndPop('Subscription ID not found');
      return;
    }
    
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    
    Subscription? foundSubscription;
    try {
      foundSubscription = subscriptionProvider.subscriptions.firstWhere(
        (s) => s.id == subscriptionId,
      );
    } catch (e) {
      // Subscription not found
    }
    
    if (foundSubscription == null) {
      setState(() {
        _isLoading = false;
      });
      _showErrorAndPop('Subscription not found');
      return;
    }
    
    _subscription = foundSubscription;
    
    _nameController.text = _subscription!.name;
    _amountController.text = _subscription!.amount.toString();
    _currencyCode = _subscription!.currencyCode;
    _billingCycle = _subscription!.billingCycle;
    _startDate = _subscription!.startDate;
    _renewalDate = _subscription!.renewalDate;
    _category = _subscription!.category;
    _descriptionController.text = _subscription!.description ?? '';
    _websiteController.text = _subscription!.website ?? '';
    _logoUrl = _subscription!.logoUrl;
    _notificationsEnabled = _subscription!.notificationsEnabled;
    _notificationDays = _subscription!.notificationDays;
    _status = _subscription!.status;
    
    _currencySymbol = CurrencyUtils.getCurrencyByCode(_currencyCode)?.symbol;
    
    setState(() {
      _isLoading = false;
    });
    
    _animationController.forward();
  }
  
  void _showErrorAndPop(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }
  
  void _selectCurrency() async {
    final selectedCurrency = await showModalBottomSheet<Currency?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCurrencySelector(),
    );
    
    if (selectedCurrency != null) {
      setState(() {
        _currencyCode = selectedCurrency.code;
        _currencySymbol = selectedCurrency.symbol;
        _hasChanges = true;
      });
    }
  }

  Widget _buildCurrencySelector() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text(
                    'Select Currency',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Currency list
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: CurrencyUtils.getAllCurrencies().length,
                itemBuilder: (context, index) {
                  final currency = CurrencyUtils.getAllCurrencies()[index];
                  final isSelected = _currencyCode == currency.code;
                  
                  return InkWell(
                    onTap: () => Navigator.pop(context, currency),
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
                                  '${currency.code} • ${currency.symbol}',
                                  style: theme.textTheme.bodySmall?.copyWith(
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
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _selectLogo(String logoUrl) {
    setState(() {
      _logoUrl = logoUrl;
      _showLogoSuggestions = false;
      _hasChanges = true;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final currency = CurrencyUtils.getCurrencyByCode(_currencyCode) ?? 
        CurrencyUtils.getAllCurrencies().first;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                onWillPop: _onWillPop,
                child: Column(
                  children: [
                    // Modern header
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: theme.colorScheme.onSurface,
                            ),
                            onPressed: () => _confirmExit(),
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Edit Subscription',
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    if (_hasChanges) ...[
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Unsaved',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Update your subscription details',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Form content
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          children: [
                            // Status selector
                            _buildStatusSelector(),
                            const SizedBox(height: 32),
                            
                            // Logo section
                            _buildLogoSection(),
                            const SizedBox(height: 32),
                            
                            // Basic info section
                            _buildSectionTitle('Basic Information'),
                            const SizedBox(height: 16),
                            _buildNameField(),
                            
                            // Logo suggestions
                            if (_showLogoSuggestions && _logoSuggestions.isNotEmpty)
                              _buildLogoSuggestions(),
                            
                            const SizedBox(height: 16),
                            _buildAmountAndCurrencyRow(),
                            const SizedBox(height: 16),
                            _buildBillingCycleField(),
                            const SizedBox(height: 16),
                            _buildCategorySelector(),
                            
                            const SizedBox(height: 32),
                            
                            // Date section
                            _buildSectionTitle('Important Dates'),
                            const SizedBox(height: 16),
                            _buildDateFields(),
                            
                            const SizedBox(height: 32),
                            
                            // Additional info section
                            _buildSectionTitle('Additional Information'),
                            const SizedBox(height: 16),
                            _buildWebsiteField(),
                            const SizedBox(height: 16),
                            _buildDescriptionField(),
                            
                            const SizedBox(height: 32),
                            
                            // Notifications section
                            _buildNotificationSection(),
                            
                            const SizedBox(height: 40),
                            
                            // Action buttons
                            _buildActionButtons(),
                            
                            const SizedBox(height: 40),
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

  Widget _buildStatusSelector() {
    final theme = Theme.of(context);
    
    final statusOptions = [
      {'value': AppConstants.STATUS_ACTIVE, 'label': 'Active', 'icon': Icons.check_circle_outline, 'color': Colors.green},
      {'value': AppConstants.STATUS_PAUSED, 'label': 'Paused', 'icon': Icons.pause_circle_outline, 'color': Colors.orange},
      {'value': AppConstants.STATUS_CANCELLED, 'label': 'Cancelled', 'icon': Icons.cancel_outlined, 'color': Colors.red},
    ];
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: statusOptions.map((option) {
          final isSelected = _status == option['value'];
          final color = option['color'] as Color;
          
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _status = option['value'] as String;
                  _hasChanges = true;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? Border.all(color: color, width: 2) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      option['icon'] as IconData,
                      color: isSelected ? color : theme.colorScheme.onSurface.withOpacity(0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      option['label'] as String,
                      style: TextStyle(
                        color: isSelected ? color : theme.colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogoSection() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Center(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
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
            child: _logoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      _logoUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        final logoService = Provider.of<LogoService>(context, listen: false);
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Icon(
                            logoService.getFallbackIcon(_nameController.text),
                            color: Colors.white,
                            size: 48,
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
          ),
          if (_logoUrl != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _logoUrl = null;
                  _hasChanges = true;
                  _updateLogoFromName();
                });
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Remove Logo'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface.withOpacity(0.8),
      ),
    );
  }

  Widget _buildNameField() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
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
      child: TextFormField(
        controller: _nameController,
        decoration: InputDecoration(
          labelText: 'Subscription Name',
          hintText: 'e.g. Netflix, Spotify',
          prefixIcon: Icon(
            Icons.subscriptions_outlined,
            color: theme.colorScheme.primary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        textCapitalization: TextCapitalization.words,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a name';
          }
          return null;
        },
        onChanged: (value) {
          setState(() {
            _hasChanges = true;
          });
        },
      ),
    );
  }

  Widget _buildLogoSuggestions() {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Suggested Logos',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _logoSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _logoSuggestions[index];
                
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < _logoSuggestions.length - 1 ? 12 : 0,
                  ),
                  child: InkWell(
                    onTap: () => _selectLogo(suggestion.logoUrl),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 80,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                suggestion.logoUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.image_not_supported,
                                    color: theme.colorScheme.outline,
                                    size: 18,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: Text(
                              suggestion.name,
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountAndCurrencyRow() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final currency = CurrencyUtils.getCurrencyByCode(_currencyCode) ?? 
        CurrencyUtils.getAllCurrencies().first;
    
    return Row(
      children: [
        // Currency selector
        InkWell(
          onTap: _selectCurrency,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                Text(
                  currency.flag,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  '${currency.code} • ${currency.symbol}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.expand_more,
                  size: 20,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Amount field
        Expanded(
          child: Container(
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
            child: TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: '0.00',
                prefixText: '${currency.symbol} ',
                prefixStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.transparent,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                try {
                  final amount = double.parse(value.replaceAll(',', ''));
                  if (amount <= 0) {
                    return 'Amount must be greater than 0';
                  }
                } catch (e) {
                  return 'Please enter a valid number';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _hasChanges = true;
                });
              },
              inputFormatters: [
                ThousandsSeparatorInputFormatter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillingCycleField() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final billingOptions = [
      {'value': AppConstants.BILLING_CYCLE_MONTHLY, 'label': 'Monthly', 'icon': Icons.calendar_view_month},
      {'value': AppConstants.BILLING_CYCLE_QUARTERLY, 'label': 'Quarterly', 'icon': Icons.date_range},
      {'value': AppConstants.BILLING_CYCLE_YEARLY, 'label': 'Yearly', 'icon': Icons.calendar_today},
    ];
    
    return Container(
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
      child: DropdownButtonFormField<String>(
        value: _billingCycle,
        decoration: InputDecoration(
          labelText: 'Billing Cycle',
          prefixIcon: Icon(
            Icons.repeat,
            color: theme.colorScheme.primary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        items: billingOptions.map((option) {
          return DropdownMenuItem<String>(
            value: option['value'] as String,
            child: Row(
              children: [
                Icon(
                  option['icon'] as IconData,
                  size: 20,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 12),
                Text(option['label'] as String),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _billingCycle = value;
              _renewalDate = AppDateUtils.calculateNextRenewalDate(
                _startDate,
                _billingCycle,
                _subscription?.customBillingDays,
                true,
              );
              _hasChanges = true;
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        dropdownColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
      ),
    );
  }

  Widget _buildCategorySelector() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _categories.map((categoryData) {
            final isSelected = _category == categoryData['name'];
            
            return InkWell(
              onTap: () {
                setState(() {
                  _category = isSelected ? null : categoryData['name'] as String;
                  _hasChanges = true;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (categoryData['color'] as Color).withOpacity(0.2)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? categoryData['color'] as Color
                        : theme.colorScheme.outline.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      categoryData['icon'] as IconData,
                      size: 18,
                      color: isSelected
                          ? categoryData['color'] as Color
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      categoryData['name'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? categoryData['color'] as Color
                            : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateFields() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        // Start date
        GestureDetector(
          onTap: () async {
            final DateTime? selectedDate = await showDatePicker(
              context: context,
              initialDate: _startDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            
            if (selectedDate != null) {
              setState(() {
                _startDate = selectedDate;
                _renewalDate = AppDateUtils.calculateNextRenewalDate(
                  _startDate,
                  _billingCycle,
                  _subscription?.customBillingDays,
                  true,
                );
                _hasChanges = true;
              });
            }
          },
          child: Container(
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
            child: AbsorbPointer(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Start Date',
                  hintText: 'When did you start this subscription?',
                  prefixIcon: Icon(
                    Icons.event_available,
                    color: theme.colorScheme.primary,
                  ),
                  suffixIcon: Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                ),
                controller: TextEditingController(
                  text: AppDateUtils.formatDate(_startDate),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Renewal date info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Renewal',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      AppDateUtils.formatDate(_renewalDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebsiteField() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
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
      child: TextFormField(
        controller: _websiteController,
        decoration: InputDecoration(
          labelText: 'Website (Optional)',
          hintText: 'e.g. netflix.com',
          prefixIcon: const Icon(Icons.language),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        keyboardType: TextInputType.url,
        onChanged: (value) {
          setState(() {
            _hasChanges = true;
          });
        },
      ),
    );
  }

  Widget _buildDescriptionField() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
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
      child: TextFormField(
        controller: _descriptionController,
        decoration: InputDecoration(
          labelText: 'Notes (Optional)',
          hintText: 'Add any notes about this subscription',
          prefixIcon: const Icon(Icons.notes),
          alignLabelWithHint: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        maxLines: 3,
        onChanged: (value) {
          setState(() {
            _hasChanges = true;
          });
        },
      ),
    );
  }

  Widget _buildNotificationSection() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF1E1E1E), const Color(0xFF2D2D2D)]
              : [Colors.white, const Color(0xFFF8F9FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications_active_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Renewal Reminders',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Get notified before renewal',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                    _hasChanges = true;
                  });
                },
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),
          if (_notificationsEnabled) ...[
            const SizedBox(height: 20),
            Text(
              'Notify me before renewal:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [1, 2, 3, 5, 7].map((days) {
                final isSelected = _notificationDays == days;
                return FilterChip(
                  label: Text('$days ${days == 1 ? 'day' : 'days'}'),
                  selected: isSelected,
                  backgroundColor: theme.colorScheme.surface,
                  selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                  checkmarkColor: theme.colorScheme.primary,
                  onSelected: (selected) {
                    setState(() {
                      _notificationDays = days;
                      _hasChanges = true;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Save button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _hasChanges ? _updateSubscription : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: theme.colorScheme.primary.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_hasChanges ? Icons.save_outlined : Icons.check_circle_outline),
                const SizedBox(width: 8),
                Text(
                  _hasChanges ? 'Save Changes' : 'No Changes',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Delete button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: _confirmDelete,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline),
                SizedBox(width: 8),
                Text(
                  'Delete Subscription',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Future<bool> _onWillPop() async {
    if (_hasChanges) {
      final shouldPop = await _confirmExit();
      return shouldPop;
    }
    return true;
  }
  
  Future<bool> _confirmExit() async {
    if (!_hasChanges) {
      Navigator.of(context).pop();
      return true;
    }
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
    
    if (result == true) {
      if (mounted) Navigator.of(context).pop();
      return true;
    }
    
    return false;
  }

  Future<void> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subscription?'),
        content: Text('Are you sure you want to delete "${_subscription?.name}"? This action cannot be undone.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
    
    if (result == true && _subscription != null) {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      subscriptionProvider.deleteSubscription(_subscription!.id!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Subscription deleted'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      
      Navigator.pop(context);
    }
  }
  
  void _searchForLogo() {
    setState(() {
      _logoUrl = null;
      _hasChanges = true;
    });
    
    if (_nameController.text.isNotEmpty) {
      final logoService = Provider.of<LogoService>(context, listen: false);
      
      String? logoUrl = logoService.getLogoUrl(_nameController.text);
      
      if (logoUrl == null) {
        logoUrl = logoService.getLogoUrl(_nameController.text + " premium");
        
        if (logoUrl == null) {
          logoUrl = logoService.getLogoUrl(_nameController.text + "+");
        }
        
        if (logoUrl == null && !_nameController.text.toLowerCase().contains("apple")) {
          logoUrl = logoService.getLogoUrl("apple " + _nameController.text);
        }
      }
      
      if (logoUrl != null) {
        setState(() {
          _logoUrl = logoUrl;
          _hasChanges = true;
        });
        return;
      }
    }
    
    if (_logoUrl == null && _websiteController.text.isNotEmpty) {
      final logoService = Provider.of<LogoService>(context, listen: false);
      final logoUrl = logoService.getLogoUrl(_websiteController.text);
      if (logoUrl != null) {
        setState(() {
          _logoUrl = logoUrl;
          _hasChanges = true;
        });
        return;
      }
    }
    
    if (_logoUrl == null && _category != null) {
      final logoService = Provider.of<LogoService>(context, listen: false);
      final logoUrl = logoService.getLogoUrl(_nameController.text + " " + _category!);
      if (logoUrl != null) {
        setState(() {
          _logoUrl = logoUrl;
          _hasChanges = true;
        });
        return;
      }
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No logo found. Try a different name or website.')),
    );
  }
  
  void _updateSubscription() {
    if (_formKey.currentState!.validate() && _subscription != null) {
      final amount = double.parse(_amountController.text.replaceAll(',', ''));
      
      final updatedSubscription = _subscription!.copyWith(
        name: _nameController.text,
        amount: amount,
        currencyCode: _currencyCode,
        billingCycle: _billingCycle,
        startDate: _startDate,
        renewalDate: _renewalDate,
        category: _category,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        website: _websiteController.text.isEmpty ? null : _websiteController.text,
        logoUrl: _logoUrl,
        notificationsEnabled: _notificationsEnabled,
        notificationDays: _notificationDays,
        status: _status,
      );
      
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      subscriptionProvider.updateSubscription(updatedSubscription);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Subscription updated successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      
      Navigator.pop(context);
    }
  }
}

