import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/core/utils/currency_utils.dart';
import 'package:subtrackr/core/utils/date_utils.dart';
import 'package:subtrackr/core/utils/text_formatters.dart';
import 'package:subtrackr/data/services/logo_service.dart';
import 'package:subtrackr/data/services/settings_service.dart';
import 'package:subtrackr/domain/entities/subscription.dart';
import 'package:subtrackr/presentation/blocs/subscription_provider.dart';

class LogoSuggestion {
  final String name;
  final String logoUrl;
  
  LogoSuggestion({required this.name, required this.logoUrl});
}

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
  late Animation<Offset> _slideAnimation;
  
  String _currencyCode = AppConstants.defaultCurrencyCode;
  String _currencySymbol = AppConstants.defaultCurrencySymbol;
  String _billingCycle = AppConstants.billingCycleMonthly;
  DateTime _startDate = DateTime.now();
  String? _category;
  bool _notificationsEnabled = true;
  int _notificationDays = AppConstants.defaultNotificationDaysBeforeRenewal;
  String? _logoUrl;
  String _status = AppConstants.statusActive;
  
  // Add a list to store logo suggestions
  List<LogoSuggestion> _logoSuggestions = [];
  bool _showLogoSuggestions = false;
  bool _isLoading = true;

  final List<String> _categories = [
    'Entertainment',
    'Productivity',
    'Utilities',
    'Health & Fitness',
    'Food & Drink',
    'Shopping',
    'Other',
  ];

  DateTime? _lastPaymentDate;
  DateTime? _renewalDate;

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
    
    // Initialize date fields
    _startDateController.text = AppDateUtils.formatDate(_startDate);
    
    // Initialize with default currency from settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsService = Provider.of<SettingsService>(context, listen: false);
      setState(() {
        _currencyCode = settingsService.getCurrencyCode() ?? AppConstants.defaultCurrencyCode;
        _currencySymbol = CurrencyUtils.getCurrencyByCode(_currencyCode)?.symbol ?? AppConstants.defaultCurrencySymbol;
        _isLoading = false;
      });
      
      // Start animations after loading
      _animationController.forward();
    });
    
    // Add listener to website field to update logo
    _websiteController.addListener(_updateLogoFromWebsite);
    
    // Add listener to name field to update logo and suggestions
    _nameController.addListener(_updateLogoFromName);
    
    // Add listener to start date to check if historical
    _startDateController.addListener(_checkIfHistorical);
  }

  @override
  void dispose() {
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
    // If a logo has already been selected, don't show suggestions
    if (_logoUrl != null) {
      setState(() {
        _showLogoSuggestions = false;
      });
      return;
    }
    
    if (_nameController.text.isNotEmpty) {
      final logoService = Provider.of<LogoService>(context, listen: false);
      
      // Get logo suggestions
      final suggestions = logoService.getLogoSuggestions(_nameController.text);
      List<LogoSuggestion> newSuggestions = [];
      
      // Convert each suggestion to our LogoSuggestion class
      for (var suggestion in suggestions) {
        newSuggestions.add(LogoSuggestion(
          name: suggestion.name,
          logoUrl: suggestion.logoUrl,
        ));
      }
      
      _logoSuggestions = newSuggestions;
      
      // If we have suggestions, show them
      if (_logoSuggestions.isNotEmpty) {
        setState(() {
          _showLogoSuggestions = true;
        });
      }
      
      // REMOVED: No longer automatically set logo when typing
      // Only show suggestions, user must click to select one
    } else {
      setState(() {
        _logoSuggestions = [];
        _showLogoSuggestions = false;
      });
    }
  }

  void _searchForLogo() {
    setState(() {
      _logoUrl = null; // Reset logo to trigger search
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
        });
        return;
      }
    }
    
    // If all else fails, show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No logo found. Try a different name or website.')),
    );
  }

  // Method to select a logo from suggestions
  void _selectLogo(String logoUrl) {
    setState(() {
      _logoUrl = logoUrl;
      _showLogoSuggestions = false;
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
      });
    }
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
                            onPressed: () => Navigator.pop(context),
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
                      'Add Subscription',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
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
                                      tag: 'no_hero_animation',
                                      flightShuttleBuilder: (_, __, ___, ____, _____) => 
                                        const SizedBox.shrink(),
                                      child: Image.network(
                                        _logoUrl!,
                                        key: const ValueKey('add_subscription_logo_image'),
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
                                onChanged: (_) {
                                  // Force refresh to show suggestions while typing
                                  setState(() {
                                    // This empty setState helps trigger the widget rebuild
                                    // to show logo suggestions as the user types
                                  });
                                },
                              ),
                              
                              // Show logo suggestions immediately after name field if available
                              if (_showLogoSuggestions && _logoSuggestions.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Suggested Logos',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _logoSuggestions.length,
                                    itemBuilder: (context, index) {
                                      final suggestion = _logoSuggestions[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
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
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Hero(
                                                    tag: 'no_hero_animation_suggestion_${suggestion.name}',
                                                    child: Image.network(
                                                      suggestion.logoUrl,
                                                      key: ValueKey('logo_suggestion_${suggestion.name}'),
                                                      fit: BoxFit.contain,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(
                                                          color: colorScheme.primary,
                                                          child: const Icon(
                                                            Icons.image_not_supported,
                                                            color: Colors.white,
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
                                            Text(
                                              suggestion.name,
                                              style: theme.textTheme.bodySmall,
                                              overflow: TextOverflow.ellipsis,
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
                          value: AppConstants.billingCycleMonthly,
                          child: const Text('Monthly'),
                        ),
                        DropdownMenuItem(
                          value: AppConstants.billingCycleQuarterly,
                          child: const Text('Quarterly'),
                        ),
                        DropdownMenuItem(
                          value: AppConstants.billingCycleYearly,
                          child: const Text('Yearly'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _billingCycle = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Start date picker
                    GestureDetector(
                      onTap: _selectStartDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _startDateController,
                          decoration: InputDecoration(
                            labelText: 'Start Date',
                            prefixIcon: const Icon(Icons.date_range_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                          ),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Last Payment Date field (always visible for now)
                    GestureDetector(
                      onTap: () => _selectLastPaymentDate(context),
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _lastPaymentDateController,
                          decoration: InputDecoration(
                            labelText: 'Last Payment Date',
                            hintText: 'When did you last pay for this subscription?',
                            prefixIcon: const Icon(Icons.payment),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            suffixIcon: const Icon(Icons.calendar_today),
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
                        onPressed: _saveSubscription,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                        child: const Text(
                          'Add Subscription',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
      ),
    );
  }
  
  Widget _buildStatusOption(String value, String label, IconData icon, Color color) {
    final isSelected = _status == value;
    final theme = Theme.of(context);
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _status = value;
          });
        },
          borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : theme.colorScheme.outline.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? color : theme.colorScheme.onSurface.withOpacity(0.7),
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : theme.colorScheme.onSurface.withOpacity(0.7),
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
  
  void _saveSubscription() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final amount = double.parse(_amountController.text.replaceAll(RegExp(r'[^0-9\.]'), ''));
      final description = _descriptionController.text.trim();
      final website = _websiteController.text.trim();
      
      int? customBillingDays;
      if (_billingCycle == AppConstants.billingCycleCustom) {
        customBillingDays = int.parse(_customDaysController.text);
      }
      
      DateTime calculatedRenewalDate;
      
      // If we have a last payment date, use it to calculate the renewal date
      if (_lastPaymentDate != null) {
        calculatedRenewalDate = _renewalDate ?? _calculateRenewalFromLastPayment();
      } else {
        // For new subscriptions, we don't skip past dates, so we can see overdue payments
        calculatedRenewalDate = AppDateUtils.calculateNextRenewalDate(
        _startDate,
        _billingCycle,
          customBillingDays,
          false, // skipPastDates - don't skip past dates for new subscriptions
      );
      }
      
      // Debug info
      print('DEBUG: Creating subscription: startDate: $_startDate, renewalDate: $calculatedRenewalDate, lastPaymentDate: $_lastPaymentDate');
      
      // Create new subscription (always set to active)
      final subscription = Subscription(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
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
        status: AppConstants.statusActive, // Always active when first created
      );
      
      // If we had a last payment date, add it to the payment history
      if (_lastPaymentDate != null) {
        final List<DateTime> paymentHistory = [_lastPaymentDate!];
        final subscriptionWithHistory = subscription.copyWith(
          paymentHistory: paymentHistory,
        );
        Provider.of<SubscriptionProvider>(context, listen: false).addSubscription(subscriptionWithHistory);
      } else {
        Provider.of<SubscriptionProvider>(context, listen: false).addSubscription(subscription);
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.subscriptionAddedSuccess)),
      );
      
      // Navigate back
      Navigator.pop(context);
    }
  }

  // Calculate next renewal date from last payment
  DateTime _calculateRenewalFromLastPayment() {
    if (_lastPaymentDate == null) return _startDate;
    
    DateTime calculatedDate;
    switch (_billingCycle) {
      case AppConstants.billingCycleMonthly:
        calculatedDate = DateTime(
          _lastPaymentDate!.year,
          _lastPaymentDate!.month + 1,
          _lastPaymentDate!.day,
        );
        break;
      case AppConstants.billingCycleQuarterly:
        calculatedDate = DateTime(
          _lastPaymentDate!.year,
          _lastPaymentDate!.month + 3,
          _lastPaymentDate!.day,
        );
        break;
      case AppConstants.billingCycleYearly:
        calculatedDate = DateTime(
          _lastPaymentDate!.year + 1,
          _lastPaymentDate!.month,
          _lastPaymentDate!.day,
        );
        break;
      case AppConstants.billingCycleCustom:
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
    
    // If the calculated date is still in the past, keep adding billing cycles
    // until we get a future date
    while (calculatedDate.isBefore(DateTime.now())) {
      switch (_billingCycle) {
        case AppConstants.billingCycleMonthly:
          calculatedDate = DateTime(
            calculatedDate.year,
            calculatedDate.month + 1,
            calculatedDate.day,
          );
          break;
        case AppConstants.billingCycleQuarterly:
          calculatedDate = DateTime(
            calculatedDate.year,
            calculatedDate.month + 3,
            calculatedDate.day,
          );
          break;
        case AppConstants.billingCycleYearly:
          calculatedDate = DateTime(
            calculatedDate.year + 1,
            calculatedDate.month,
            calculatedDate.day,
          );
          break;
        case AppConstants.billingCycleCustom:
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

  // Check if start date is more than one billing cycle in the past
  bool _isStartDateHistorical() {
    final now = DateTime.now();
    final difference = now.difference(_startDate).inDays;
    
    print('DEBUG: Checking if historical: startDate: $_startDate, difference: $difference days');
    
    // Consider it historical if it's more than one billing cycle in the past
    bool isHistorical = false;
    switch (_billingCycle) {
      case AppConstants.billingCycleMonthly:
        isHistorical = difference > 31; // More than a month ago
        break;
      case AppConstants.billingCycleQuarterly:
        isHistorical = difference > 92; // More than 3 months ago
        break;
      case AppConstants.billingCycleYearly:
        isHistorical = difference > 366; // More than a year ago
        break;
      case AppConstants.billingCycleCustom:
        final customDays = int.tryParse(_customDaysController.text) ?? 30;
        isHistorical = difference > customDays; // More than one custom cycle ago
        break;
      default:
        isHistorical = difference > 31; // Default to monthly
    }
    
    print('DEBUG: Is historical: $isHistorical');
    return isHistorical;
  }

  // Last payment date picker
  Future<void> _selectLastPaymentDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _lastPaymentDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _lastPaymentDate) {
      setState(() {
        _lastPaymentDate = picked;
        _lastPaymentDateController.text = DateFormat('MMM d, yyyy').format(picked);
        
        // Recalculate the next renewal date based on the last payment date
        _calculateRenewalDate();
      });
    }
  }

  // Modify the _calculateRenewalDate method to use last payment date if available:
  void _calculateRenewalDate() {
    if (_startDate == null) return;
    
    // Use last payment date as the base for calculation if it's provided
    final baseDate = _lastPaymentDate ?? _startDate!;
    
    DateTime calculatedDate;
    switch (_billingCycle) {
      case AppConstants.billingCycleMonthly:
        calculatedDate = DateTime(
          baseDate.year,
          baseDate.month + 1,
          baseDate.day,
        );
        break;
      case AppConstants.billingCycleQuarterly:
        calculatedDate = DateTime(
          baseDate.year,
          baseDate.month + 3,
          baseDate.day,
        );
        break;
      case AppConstants.billingCycleYearly:
        calculatedDate = DateTime(
          baseDate.year + 1,
          baseDate.month,
          baseDate.day,
        );
        break;
      case AppConstants.billingCycleCustom:
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
    
    // If the calculated date is still in the past, keep adding billing cycles
    // until we get a future date
    while (calculatedDate.isBefore(DateTime.now())) {
      switch (_billingCycle) {
        case AppConstants.billingCycleMonthly:
          calculatedDate = DateTime(
            calculatedDate.year,
            calculatedDate.month + 1,
            calculatedDate.day,
          );
          break;
        case AppConstants.billingCycleQuarterly:
          calculatedDate = DateTime(
            calculatedDate.year,
            calculatedDate.month + 3,
            calculatedDate.day,
          );
          break;
        case AppConstants.billingCycleYearly:
          calculatedDate = DateTime(
            calculatedDate.year + 1,
            calculatedDate.month,
            calculatedDate.day,
          );
          break;
        case AppConstants.billingCycleCustom:
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
    setState(() {
      // Force UI update when start date changes
    });
  }

  // Start date picker
  Future<void> _selectStartDate() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (selectedDate != null) {
      setState(() {
        _startDate = selectedDate;
        _startDateController.text = AppDateUtils.formatDate(selectedDate);
      });
      
      // Check if we need to show the last payment date field
      _checkIfHistorical();
    }
  }
} 