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
  late Animation<Offset> _slideAnimation;
  
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
  
  // Add a list to store logo suggestions
  List<LogoSuggestion> _logoSuggestions = [];
  bool _showLogoSuggestions = false;
  Timer? _debounceTimer;
  
  Subscription? _subscription;
  bool _isLoading = true;
  bool _hasChanges = false;

  final List<String> _categories = [
    'Entertainment',
    'Productivity',
    'Utilities',
    'Health & Fitness',
    'Food & Drink',
    'Shopping',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    
    // Setup animations
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
    
    // Add listeners to update logo
    _websiteController.addListener(_updateLogoFromWebsite);
    _nameController.addListener(_updateLogoFromName);
    
    // Wait for the widget to be fully built before loading data
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
    if (_logoUrl != null) return; // Already have a logo
    
    final logoService = Provider.of<LogoService>(context, listen: false);
    final logoUrl = logoService.getLogoUrl(_websiteController.text);
    if (logoUrl != null) {
      setState(() {
        _logoUrl = logoUrl;
      });
    }
  }
  
  void _updateLogoFromName() {
    // Cancel previous debounce timer
    _debounceTimer?.cancel();
    
    // Always hide suggestions if name is empty
    if (_nameController.text.isEmpty) {
      setState(() {
        _logoSuggestions = [];
        _showLogoSuggestions = false;
      });
      return;
    }
    
    // If a logo has already been selected, don't show suggestions
    if (_logoUrl != null) {
      setState(() {
        _showLogoSuggestions = false;
      });
      return;
    }
    
    // Light debounce to feel real-time while avoiding excessive requests
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      _fetchLogoSuggestions(_nameController.text);
    });
  }
  
  void _fetchLogoSuggestions(String query) {
    if (!mounted || query.isEmpty) return;
    
    final logoService = Provider.of<LogoService>(context, listen: false);
    
    // Get logo suggestions asynchronously with retry logic
    _getLogoSuggestionsWithRetry(logoService, query, 3).then((suggestions) {
      if (mounted && _nameController.text == query) { // Check if query is still current
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
          // Last attempt failed, return empty list
          debugPrint('All logo suggestion attempts failed for query: $query');
        } else {
          // Shorter wait before retrying for faster recovery
          await Future.delayed(Duration(milliseconds: 200 * (i + 1)));
        }
      }
    }
    return [];
  }
  
  void _loadSubscription() {
    // Get the subscription ID from the route arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final subscriptionId = args?['id'] as String?;
    
    if (subscriptionId == null) {
      setState(() {
        _isLoading = false;
      });
      _showErrorAndPop('Subscription ID not found');
      return;
    }
    
    // Get the subscription from the provider
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    
    // Find the subscription
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
    
    // Set subscription data to form fields
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
    
    // Set currency symbol
    _currencySymbol = CurrencyUtils.getCurrencyByCode(_currencyCode)?.symbol;
    
    // Set loading state to false
    setState(() {
      _isLoading = false;
    });
    
    // Start animations
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
  
  // Method to select a new currency
  void _selectCurrency() async {
    // Show currency selection dialog
    final selectedCurrency = await showModalBottomSheet<Currency?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      'Select Currency',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: CurrencyUtils.getAllCurrencies().length,
                  itemBuilder: (context, index) {
                    final currency = CurrencyUtils.getAllCurrencies()[index];
                    return ListTile(
                      leading: Text(
                        currency.flag,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(currency.name),
                      subtitle: Text(currency.code),
                      trailing: _currencyCode == currency.code
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () => Navigator.pop(context, currency),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    if (selectedCurrency != null) {
      setState(() {
        _currencyCode = selectedCurrency.code;
        _currencySymbol = selectedCurrency.symbol;
        _hasChanges = true;
      });
    }
  }
  
  // Method to select a logo from suggestions
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
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    // Get currency information
    final currency = CurrencyUtils.getCurrencyByCode(_currencyCode) ?? 
        CurrencyUtils.getAllCurrencies().first;

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                onWillPop: _onWillPop,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Custom header with back button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back, 
                              color: isDark ? Colors.white : Colors.black
                            ),
                            onPressed: () => _confirmExit(),
                            tooltip: 'Back',
                            style: IconButton.styleFrom(
                              backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Edit Subscription',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          if (_hasChanges) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Form content
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            children: [
                              // Logo preview
                              Center(
                                child: Column(
                                  children: [
                                    if (_logoUrl != null)
                                      Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: colorScheme.primary.withOpacity(0.2),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: Hero(
                                            tag: 'no_hero_animation_edit',
                                            flightShuttleBuilder: (_, __, ___, ____, _____) => 
                                              const SizedBox.shrink(),
                                            child: Image.network(
                                              _logoUrl!,
                                              key: const ValueKey('edit_subscription_logo_image'),
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) {
                                                final logoService = Provider.of<LogoService>(context, listen: false);
                                                return Container(
                                                  color: colorScheme.primary,
                                                  child: Icon(
                                                    logoService.getFallbackIcon(_nameController.text),
                                                    color: Colors.white,
                                                    size: 40,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (_logoUrl != null)
                                          OutlinedButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _logoUrl = null;
                                                _hasChanges = true;
                                                // Trigger suggestions to reappear when logo is removed
                                                _updateLogoFromName();
                                              });
                                            },
                                            icon: const Icon(Icons.delete_outline),
                                            label: const Text('Remove Logo'),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              side: BorderSide(color: colorScheme.primary),
                                            ),
                                          )
                                        else
                                          OutlinedButton.icon(
                                            onPressed: _searchForLogo,
                                            icon: const Icon(Icons.image_search),
                                            label: const Text('Find Logo'),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              side: BorderSide(color: colorScheme.primary),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Name field
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Name',
                                  hintText: 'e.g. Netflix, Spotify',
                                  prefixIcon: const Icon(Icons.text_fields_rounded),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: theme.colorScheme.surface,
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
                                    // Force refresh to show suggestions while typing
                                  });
                                },
                              ),
                              
                              // Show logo suggestions immediately after name field if available
                              if (_showLogoSuggestions && _logoSuggestions.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(
                                      'Suggested Logos',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (_logoSuggestions.length > 4)
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.swipe_left,
                                            size: 16,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Swipe to see more',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    itemCount: _logoSuggestions.length,
                                    itemBuilder: (context, index) {
                                      final suggestion = _logoSuggestions[index];
                                      final isFirst = index == 0;
                                      final isLast = index == _logoSuggestions.length - 1;
                                      
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          left: isFirst ? 0 : 6,
                                          right: isLast ? 0 : 6,
                                        ),
                                        child: Column(
                                          children: [
                                            GestureDetector(
                                              onTap: () => _selectLogo(suggestion.logoUrl),
                                              child: Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: colorScheme.outline.withOpacity(0.3),
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: colorScheme.shadow.withOpacity(0.1),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Hero(
                                                    tag: 'no_hero_animation_suggestion_edit_${suggestion.name}_$index',
                                                    flightShuttleBuilder: (_, __, ___, ____, _____) => 
                                                      const SizedBox.shrink(),
                                                    child: Image.network(
                                                      suggestion.logoUrl,
                                                      key: ValueKey('edit_logo_suggestion_${suggestion.name}_$index'),
                                                      fit: BoxFit.contain,
                                                      loadingBuilder: (context, child, loadingProgress) {
                                                        if (loadingProgress == null) return child;
                                                        return Container(
                                                          color: colorScheme.surface,
                                                          child: Center(
                                                            child: SizedBox(
                                                              width: 20,
                                                              height: 20,
                                                              child: CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                value: loadingProgress.expectedTotalBytes != null
                                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                                        loadingProgress.expectedTotalBytes!
                                                                    : null,
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(
                                                          color: colorScheme.surface,
                                                          child: Icon(
                                                            Icons.image_not_supported,
                                                            color: colorScheme.outline,
                                                            size: 24,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            SizedBox(
                                              width: 60,
                                              child: Text(
                                                suggestion.name,
                                                style: theme.textTheme.bodySmall,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                              
                              const SizedBox(height: 16),
                              
                              // Amount and Currency
                              Row(
                                children: [
                                  // Currency selector
                                  InkWell(
                                    onTap: _selectCurrency,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      height: 60,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: colorScheme.outline.withOpacity(0.5),
                                        ),
                                        color: theme.colorScheme.surface,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            currency.flag,
                                            style: const TextStyle(fontSize: 20),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            currency.code,
                                            style: theme.textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.arrow_drop_down, size: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 12),
                                  
                                  // Amount field
                                  Expanded(
                                    child: TextFormField(
                                      controller: _amountController,
                                      decoration: InputDecoration(
                                        labelText: 'Amount',
                                        hintText: '9.99',
                                        prefixText: '${currency.symbol} ',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        filled: true,
                                        fillColor: theme.colorScheme.surface,
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
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Billing cycle dropdown
                              _buildDropdownField(
                                value: _billingCycle,
                                label: 'Billing Cycle',
                                icon: Icons.calendar_today_rounded,
                                items: [
                                  DropdownMenuItem(
                                    value: AppConstants.BILLING_CYCLE_MONTHLY,
                                    child: const Text('Monthly'),
                                  ),
                                  DropdownMenuItem(
                                    value: AppConstants.BILLING_CYCLE_QUARTERLY,
                                    child: const Text('Quarterly'),
                                  ),
                                  DropdownMenuItem(
                                    value: AppConstants.BILLING_CYCLE_YEARLY,
                                    child: const Text('Yearly'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _billingCycle = value;
                                      
                                      // Recalculate renewal date based on new billing cycle
                                      _renewalDate = AppDateUtils.calculateNextRenewalDate(
                                        _startDate,
                                        _billingCycle,
                                        _subscription?.customBillingDays,
                                        true, // We want to skip past dates when editing
                                      );
                                      
                                      _hasChanges = true;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Start date picker
                              GestureDetector(
                                onTap: () async {
                                  final DateTime? selectedDate = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  
                                  if (selectedDate != null) {
                                    setState(() {
                                      _startDate = selectedDate;
                                      
                                      // Recalculate renewal date based on new start date
                                      _renewalDate = AppDateUtils.calculateNextRenewalDate(
                                        _startDate,
                                        _billingCycle,
                                        _subscription?.customBillingDays,
                                        true, // We want to skip past dates when editing
                                      );
                                      
                                      _hasChanges = true;
                                    });
                                  }
                                },
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Start Date',
                                      prefixIcon: const Icon(Icons.date_range_rounded),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: theme.colorScheme.surface,
                                    ),
                                    controller: TextEditingController(
                                      text: AppDateUtils.formatDate(_startDate),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Category dropdown
                              _buildDropdownField(
                                value: _category,
                                label: 'Category',
                                icon: Icons.category_rounded,
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('None'),
                                  ),
                                  ..._categories.map((category) {
                                    return DropdownMenuItem<String?>(
                                      value: category,
                                      child: Text(category),
                                    );
                                  }).toList(),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _category = value;
                                    _hasChanges = true;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Website field
                              TextFormField(
                                controller: _websiteController,
                                decoration: InputDecoration(
                                  labelText: 'Website',
                                  hintText: 'e.g. netflix.com',
                                  prefixIcon: const Icon(Icons.link_rounded),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: theme.colorScheme.surface,
                                ),
                                keyboardType: TextInputType.url,
                                onChanged: (value) {
                                  setState(() {
                                    _hasChanges = true;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Description field
                              TextFormField(
                                controller: _descriptionController,
                                decoration: InputDecoration(
                                  labelText: 'Description',
                                  hintText: 'Add notes about this subscription',
                                  prefixIcon: const Icon(Icons.description_rounded),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: theme.colorScheme.surface,
                                  alignLabelWithHint: true,
                                ),
                                maxLines: 3,
                                onChanged: (value) {
                                  setState(() {
                                    _hasChanges = true;
                                  });
                                },
                              ),
                              const SizedBox(height: 24),
                              
                              // Notifications section
                              Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                                color: theme.colorScheme.surface,
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.notifications_active_rounded,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Renewal Notifications',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          Switch(
                                            value: _notificationsEnabled,
                                            onChanged: (value) {
                                              setState(() {
                                                _notificationsEnabled = value;
                                                _hasChanges = true;
                                              });
                                            },
                                            activeColor: colorScheme.primary,
                                          ),
                                        ],
                                      ),
                                      if (_notificationsEnabled) ...[
                                        const SizedBox(height: 16),
                                        const Text('Notify me before renewal:'),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          children: [1, 2, 3, 5, 7].map((days) {
                                            final isSelected = _notificationDays == days;
                                            return FilterChip(
                                              label: Text('$days days'),
                                              selected: isSelected,
                                              backgroundColor: theme.colorScheme.surface,
                                              selectedColor: colorScheme.primary.withOpacity(0.2),
                                              checkmarkColor: colorScheme.primary,
                                              onSelected: (selected) {
                                                setState(() {
                                                  _notificationDays = days;
                                                  _hasChanges = true;
                                                });
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 36),
                              
                              // Save button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _updateSubscription,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                  ),
                                  child: const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
  
  Widget _buildDropdownField<T>({
    required T value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final theme = Theme.of(context);
    
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
      items: items,
      onChanged: onChanged,
      borderRadius: BorderRadius.circular(12),
      dropdownColor: theme.colorScheme.surface,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
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
  
  void _searchForLogo() {
    setState(() {
      _logoUrl = null; // Reset logo to trigger search
      _hasChanges = true;
    });
    
    // Try to find logo from name first
    if (_nameController.text.isNotEmpty) {
      final logoService = Provider.of<LogoService>(context, listen: false);
      
      // Try exact name
      String? logoUrl = logoService.getLogoUrl(_nameController.text);
      
      // If no logo found, try with common variations
      if (logoUrl == null) {
        // Try with "premium" suffix
        logoUrl = logoService.getLogoUrl(_nameController.text + " premium");
        
        // Try with "+" suffix
        if (logoUrl == null) {
          logoUrl = logoService.getLogoUrl(_nameController.text + "+");
        }
        
        // Try with common prefixes
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
    
    // If no logo found and website is provided, try that
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
    
    // If still no logo, try with category if selected
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
    
    // If all else fails, show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No logo found. Try a different name or website.')),
    );
  }
  
  void _updateSubscription() {
    if (_formKey.currentState!.validate() && _subscription != null) {
      final amount = double.parse(_amountController.text.replaceAll(',', ''));
      
      // Create updated subscription
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
      
      // Update subscription in provider
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      subscriptionProvider.updateSubscription(updatedSubscription);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.SUBSCRIPTION_UPDATED_SUCCESS)),
      );
      
      // Navigate back
      Navigator.pop(context);
    }
  }
}

