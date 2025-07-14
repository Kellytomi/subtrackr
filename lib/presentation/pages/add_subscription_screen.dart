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

class AddSubscriptionScreen extends StatefulWidget {
  const AddSubscriptionScreen({super.key});

  @override
  State<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _customDaysController = TextEditingController();
  final _startDateController = TextEditingController();
  final _lastPaymentDateController = TextEditingController();
  final _renewalDateController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String _currencyCode = AppConstants.DEFAULT_CURRENCY_CODE;
  String _currencySymbol = AppConstants.DEFAULT_CURRENCY_SYMBOL;
  String _billingCycle = AppConstants.BILLING_CYCLE_MONTHLY;
  DateTime _startDate = DateTime.now();
  String? _category;
  bool _notificationsEnabled = true;
  int _notificationDays = AppConstants.DEFAULT_NOTIFICATION_DAYS_BEFORE_RENEWAL;
  String? _logoUrl;
  String _status = AppConstants.STATUS_ACTIVE;
  
  List<LogoSuggestion> _logoSuggestions = [];
  bool _showLogoSuggestions = false;
  bool _isLoading = true;
  Timer? _debounceTimer;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Entertainment', 'icon': Icons.movie_outlined, 'color': const Color(0xFF6366F1)},
    {'name': 'Productivity', 'icon': Icons.work_outline, 'color': const Color(0xFF06B6D4)},
    {'name': 'Utilities', 'icon': Icons.build_outlined, 'color': const Color(0xFF10B981)},
    {'name': 'Health & Fitness', 'icon': Icons.fitness_center_outlined, 'color': const Color(0xFFF59E0B)},
    {'name': 'Food & Drink', 'icon': Icons.restaurant_outlined, 'color': const Color(0xFFEF4444)},
    {'name': 'Shopping', 'icon': Icons.shopping_bag_outlined, 'color': const Color(0xFF8B5CF6)},
    {'name': 'Other', 'icon': Icons.category_outlined, 'color': const Color(0xFF6B7280)},
  ];

  DateTime? _lastPaymentDate;
  DateTime? _renewalDate;

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
    
    _startDateController.text = AppDateUtils.formatDate(_startDate);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsService = Provider.of<SettingsService>(context, listen: false);
      setState(() {
        _currencyCode = settingsService.getCurrencyCode() ?? AppConstants.DEFAULT_CURRENCY_CODE;
        _currencySymbol = CurrencyUtils.getCurrencyByCode(_currencyCode)?.symbol ?? AppConstants.DEFAULT_CURRENCY_SYMBOL;
        _isLoading = false;
      });
      
      _animationController.forward();
    });
    
    _websiteController.addListener(_updateLogoFromWebsite);
    _nameController.addListener(_updateLogoFromName);
    _startDateController.addListener(_checkIfHistorical);
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
    if (_websiteController.text.isNotEmpty) {
      final logoService = Provider.of<LogoService>(context, listen: false);
      final logoUrl = logoService.getLogoUrl(_websiteController.text);
      if (logoUrl != null) {
        setState(() {
          _logoUrl = logoUrl;
        });
      }
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

  void _searchForLogo() {
    setState(() {
      _logoUrl = null;
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
        });
        return;
      }
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No logo found. Try a different name or website.')),
    );
  }
  
  void _selectLogo(String logoUrl) {
    setState(() {
      _logoUrl = logoUrl;
      _showLogoSuggestions = false;
    });
  }

  Future<void> _selectCurrency() async {
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
                            onPressed: () => Navigator.pop(context),
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
                                Text(
                                  'Add Subscription',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Track a new recurring payment',
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
                            
                            // Save button
                            _buildSaveButton(),
                            
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
        onChanged: (_) {
          setState(() {});
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
          onTap: _selectStartDate,
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
                controller: _startDateController,
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
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Last payment date
        GestureDetector(
          onTap: () => _selectLastPaymentDate(context),
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
                controller: _lastPaymentDateController,
                decoration: InputDecoration(
                  labelText: 'Last Payment Date (Optional)',
                  hintText: 'When did you last pay?',
                  prefixIcon: Icon(
                    Icons.payment,
                    color: theme.colorScheme.secondary,
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
              ),
            ),
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

  Widget _buildSaveButton() {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saveSubscription,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline),
            SizedBox(width: 8),
            Text(
              'Add Subscription',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveSubscription() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final amount = double.parse(_amountController.text.replaceAll(RegExp(r'[^0-9\.]'), ''));
      final description = _descriptionController.text.trim();
      final website = _websiteController.text.trim();
      
      int? customBillingDays;
      if (_billingCycle == AppConstants.BILLING_CYCLE_CUSTOM) {
        customBillingDays = int.parse(_customDaysController.text);
      }
      
      DateTime calculatedRenewalDate;
      
      if (_lastPaymentDate != null) {
        calculatedRenewalDate = _renewalDate ?? _calculateRenewalFromLastPayment();
      } else {
        final shouldSkipPastDates = DateTime.now().difference(_startDate).inDays > 1;
        calculatedRenewalDate = AppDateUtils.calculateNextRenewalDate(
          _startDate,
          _billingCycle,
          customBillingDays,
          shouldSkipPastDates,
        );
      }
      
      debugPrint('DEBUG: Creating subscription: startDate: $_startDate, renewalDate: $calculatedRenewalDate, lastPaymentDate: $_lastPaymentDate');
      debugPrint('DEBUG: Days since start date: ${DateTime.now().difference(_startDate).inDays}');
      
      final subscription = Subscription(
        name: name,
        amount: amount,
        description: description.isNotEmpty ? description : null,
        website: website.isNotEmpty ? website : null,
        currencyCode: _currencyCode,
        billingCycle: _billingCycle,
        startDate: _startDate,
        renewalDate: calculatedRenewalDate,
        category: _category,
        customBillingDays: customBillingDays,
        logoUrl: _logoUrl,
        notificationsEnabled: _notificationsEnabled,
        notificationDays: _notificationDays,
        status: AppConstants.STATUS_ACTIVE,
      );
      
      if (_lastPaymentDate != null) {
        final List<DateTime> paymentHistory = [_lastPaymentDate!];
        final subscriptionWithHistory = subscription.copyWith(
          paymentHistory: paymentHistory,
        );
        Provider.of<SubscriptionProvider>(context, listen: false).addSubscription(subscriptionWithHistory);
      } else {
        Provider.of<SubscriptionProvider>(context, listen: false).addSubscription(subscription);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Subscription added successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      
      Navigator.pop(context);
    }
  }

  DateTime _calculateRenewalFromLastPayment() {
    if (_lastPaymentDate == null) return _startDate;
    
    DateTime calculatedDate;
    switch (_billingCycle) {
      case AppConstants.BILLING_CYCLE_MONTHLY:
        calculatedDate = DateTime(
          _lastPaymentDate!.year,
          _lastPaymentDate!.month + 1,
          _lastPaymentDate!.day,
        );
        break;
      case AppConstants.BILLING_CYCLE_QUARTERLY:
        calculatedDate = DateTime(
          _lastPaymentDate!.year,
          _lastPaymentDate!.month + 3,
          _lastPaymentDate!.day,
        );
        break;
      case AppConstants.BILLING_CYCLE_YEARLY:
        calculatedDate = DateTime(
          _lastPaymentDate!.year + 1,
          _lastPaymentDate!.month,
          _lastPaymentDate!.day,
        );
        break;
      case AppConstants.BILLING_CYCLE_CUSTOM:
        final days = int.tryParse(_customDaysController.text);
        if (days != null) {
          calculatedDate = _lastPaymentDate!.add(Duration(days: days));
        } else {
          calculatedDate = _lastPaymentDate!.add(const Duration(days: 30));
        }
        break;
      default:
        calculatedDate = _lastPaymentDate!.add(const Duration(days: 30));
    }
    
    while (calculatedDate.isBefore(DateTime.now())) {
      switch (_billingCycle) {
        case AppConstants.BILLING_CYCLE_MONTHLY:
          calculatedDate = DateTime(
            calculatedDate.year,
            calculatedDate.month + 1,
            calculatedDate.day,
          );
          break;
        case AppConstants.BILLING_CYCLE_QUARTERLY:
          calculatedDate = DateTime(
            calculatedDate.year,
            calculatedDate.month + 3,
            calculatedDate.day,
          );
          break;
        case AppConstants.BILLING_CYCLE_YEARLY:
          calculatedDate = DateTime(
            calculatedDate.year + 1,
            calculatedDate.month,
            calculatedDate.day,
          );
          break;
        case AppConstants.BILLING_CYCLE_CUSTOM:
          final days = int.tryParse(_customDaysController.text);
          if (days != null) {
            calculatedDate = calculatedDate.add(Duration(days: days));
          } else {
            calculatedDate = calculatedDate.add(const Duration(days: 30));
          }
          break;
        default:
          calculatedDate = calculatedDate.add(const Duration(days: 30));
      }
    }
    
    return calculatedDate;
  }

  bool _isStartDateHistorical() {
    final now = DateTime.now();
    final difference = now.difference(_startDate).inDays;
    
    debugPrint('DEBUG: Checking if historical: startDate: $_startDate, difference: $difference days');
    
    bool isHistorical = false;
    switch (_billingCycle) {
      case AppConstants.BILLING_CYCLE_MONTHLY:
        isHistorical = difference > 31;
        break;
      case AppConstants.BILLING_CYCLE_QUARTERLY:
        isHistorical = difference > 92;
        break;
      case AppConstants.BILLING_CYCLE_YEARLY:
        isHistorical = difference > 366;
        break;
      case AppConstants.BILLING_CYCLE_CUSTOM:
        final customDays = int.tryParse(_customDaysController.text) ?? 30;
        isHistorical = difference > customDays;
        break;
      default:
        isHistorical = difference > 31;
    }
    
    debugPrint('DEBUG: Is historical: $isHistorical');
    return isHistorical;
  }

  Future<void> _selectLastPaymentDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _lastPaymentDate ?? DateTime.now(),
      firstDate: _startDate,
      lastDate: DateTime.now(),
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
    
    if (picked != null && picked != _lastPaymentDate) {
      setState(() {
        _lastPaymentDate = picked;
        _lastPaymentDateController.text = DateFormat('MMM d, yyyy').format(picked);
        _calculateRenewalDate();
      });
    }
  }

  void _calculateRenewalDate() {
    if (_startDate == null) return;
    
    final baseDate = _lastPaymentDate ?? _startDate;
    
    DateTime calculatedDate;
    switch (_billingCycle) {
      case AppConstants.BILLING_CYCLE_MONTHLY:
        calculatedDate = DateTime(
          baseDate.year,
          baseDate.month + 1,
          baseDate.day,
        );
        break;
      case AppConstants.BILLING_CYCLE_QUARTERLY:
        calculatedDate = DateTime(
          baseDate.year,
          baseDate.month + 3,
          baseDate.day,
        );
        break;
      case AppConstants.BILLING_CYCLE_YEARLY:
        calculatedDate = DateTime(
          baseDate.year + 1,
          baseDate.month,
          baseDate.day,
        );
        break;
      case AppConstants.BILLING_CYCLE_CUSTOM:
        final days = int.tryParse(_customDaysController.text);
        if (days != null) {
          calculatedDate = baseDate.add(Duration(days: days));
        } else {
          calculatedDate = baseDate.add(const Duration(days: 30));
        }
        break;
      default:
        calculatedDate = baseDate.add(const Duration(days: 30));
    }
    
    while (calculatedDate.isBefore(DateTime.now())) {
      switch (_billingCycle) {
        case AppConstants.BILLING_CYCLE_MONTHLY:
          calculatedDate = DateTime(
            calculatedDate.year,
            calculatedDate.month + 1,
            calculatedDate.day,
          );
          break;
        case AppConstants.BILLING_CYCLE_QUARTERLY:
          calculatedDate = DateTime(
            calculatedDate.year,
            calculatedDate.month + 3,
            calculatedDate.day,
          );
          break;
        case AppConstants.BILLING_CYCLE_YEARLY:
          calculatedDate = DateTime(
            calculatedDate.year + 1,
            calculatedDate.month,
            calculatedDate.day,
          );
          break;
        case AppConstants.BILLING_CYCLE_CUSTOM:
          final days = int.tryParse(_customDaysController.text);
          if (days != null) {
            calculatedDate = calculatedDate.add(Duration(days: days));
          } else {
            calculatedDate = calculatedDate.add(const Duration(days: 30));
          }
          break;
        default:
          calculatedDate = calculatedDate.add(const Duration(days: 30));
      }
    }
    
    setState(() {
      _renewalDate = calculatedDate;
      _renewalDateController.text = DateFormat('MMM d, yyyy').format(calculatedDate);
    });
  }

  void _checkIfHistorical() {
    setState(() {});
  }

  Future<void> _selectStartDate() async {
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
        _startDateController.text = AppDateUtils.formatDate(selectedDate);
      });
      
      _checkIfHistorical();
    }
  }
} 