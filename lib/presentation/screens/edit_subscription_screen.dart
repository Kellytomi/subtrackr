import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/core/utils/currency_utils.dart';
import 'package:subtrackr/core/utils/date_utils.dart';
import 'package:subtrackr/data/services/logo_service.dart';
import 'package:subtrackr/data/services/settings_service.dart';
import 'package:subtrackr/domain/entities/subscription.dart';
import 'package:subtrackr/presentation/blocs/subscription_provider.dart';
import 'package:subtrackr/presentation/screens/add_subscription_screen.dart';

class EditSubscriptionScreen extends StatefulWidget {
  const EditSubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<EditSubscriptionScreen> createState() => _EditSubscriptionScreenState();
}

class _EditSubscriptionScreenState extends State<EditSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  
  late String _billingCycle;
  late DateTime _startDate;
  String? _category;
  late bool _notificationsEnabled;
  late int _notificationDays;
  late String _currencyCode;
  String? _logoUrl;
  String? _currencySymbol;
  
  late Subscription _subscription;
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

  @override
  void initState() {
    super.initState();
    
    // Add listeners to update logo
    _websiteController.addListener(_updateLogoFromWebsite);
    _nameController.addListener(_updateLogoFromName);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get subscription ID from route arguments
    final subscriptionId = ModalRoute.of(context)!.settings.arguments as String;
    
    // Get subscription from provider
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    _subscription = subscriptionProvider.subscriptions.firstWhere(
      (subscription) => subscription.id == subscriptionId,
    );
    
    // Initialize form fields
    _nameController.text = _subscription.name;
    _amountController.text = _subscription.amount.toString();
    _descriptionController.text = _subscription.description ?? '';
    _websiteController.text = _subscription.website ?? '';
    
    _billingCycle = _subscription.billingCycle;
    _startDate = _subscription.startDate;
    _category = _subscription.category;
    _notificationsEnabled = _subscription.notificationsEnabled;
    _notificationDays = _subscription.notificationDays;
    _currencyCode = _subscription.currencyCode;
    _logoUrl = _subscription.logoUrl;
    _currencySymbol = CurrencyUtils.getCurrencyByCode(_currencyCode)?.symbol;
    
    setState(() {
      _isLoading = false;
    });
  }
  
  @override
  void dispose() {
    _websiteController.removeListener(_updateLogoFromWebsite);
    _nameController.removeListener(_updateLogoFromName);
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
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
    if (_logoUrl == null && _nameController.text.isNotEmpty) {
      final logoService = Provider.of<LogoService>(context, listen: false);
      final logoUrl = logoService.getLogoUrl(_nameController.text);
      if (logoUrl != null) {
        setState(() {
          _logoUrl = logoUrl;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    if (_isLoading) {
      return Scaffold(
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Get currency information
    final currency = CurrencyUtils.getCurrencyByCode(_currencyCode) ?? 
        CurrencyUtils.getAllCurrencies().first;
    
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Form(
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
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacementNamed(context, '/');
                          }
                        },
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
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Form content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Logo preview
                      if (_logoUrl != null)
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    _logoUrl!,
                                    fit: BoxFit.cover,
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
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _logoUrl = null;
                                  });
                                },
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Remove Logo'),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Name field
                      _buildFormField(
                        controller: _nameController,
                        label: 'Name',
                        hint: 'e.g. Netflix, Spotify',
                        icon: Icons.text_fields_rounded,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Amount and Currency
                      Row(
                        children: [
                          // Currency selector
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outline.withOpacity(0.5),
                              ),
                              color: theme.colorScheme.surface,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _selectCurrency(),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  child: Row(
                                    children: [
                                      Text(
                                        CurrencyUtils.getCurrencyByCode(_currencyCode)?.flag ?? '',
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _currencyCode,
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
                                prefixIcon: Container(
                                  width: 60,
                                  height: 50,
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _selectCurrency(),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _currencySymbol ?? CurrencyUtils.getCurrencyByCode(_currencyCode)?.symbol ?? '',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.arrow_drop_down,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
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
                                  final amount = double.parse(value);
                                  if (amount <= 0) {
                                    return 'Amount must be greater than 0';
                                  }
                                } catch (e) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
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
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Website field
                      _buildFormField(
                        controller: _websiteController,
                        label: 'Website',
                        hint: 'e.g. https://netflix.com',
                        icon: Icons.link_rounded,
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 16),
                      
                      // Description field
                      _buildFormField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Add notes about this subscription',
                        icon: Icons.description_rounded,
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
                                    Icons.notifications_outlined, 
                                    color: colorScheme.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Notification Settings',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              
                              // Notifications switch
                              Row(
                                children: [
                                  Icon(
                                    Icons.notifications_active_outlined,
                                    color: colorScheme.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Enable Notifications',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'Get reminders before renewal',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch.adaptive(
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
                                const SizedBox(height: 24),
                                
                                // Notification days slider
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Days Before Renewal',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              _notificationDays.toString(),
                                              style: TextStyle(
                                                color: colorScheme.onPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: colorScheme.primary,
                                        inactiveTrackColor: colorScheme.primary.withOpacity(0.2),
                                        thumbColor: colorScheme.primary,
                                        overlayColor: colorScheme.primary.withOpacity(0.2),
                                      ),
                                      child: Slider(
                                        value: _notificationDays.toDouble(),
                                        min: 1,
                                        max: 14,
                                        divisions: 13,
                                        onChanged: (value) {
                                          setState(() {
                                            _notificationDays = value.toInt();
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
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
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        alignLabelWithHint: maxLines > 1,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }
  
  Widget _buildDropdownField<T>({
    required T value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      items: items,
      onChanged: onChanged,
    );
  }
  
  void _selectCurrency() async {
    final currencies = CurrencyUtils.getAllCurrencies();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Currency',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
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
                itemCount: currencies.length,
                itemBuilder: (context, index) {
                  final currency = currencies[index];
                  return ListTile(
                    leading: Text(
                      currency.symbol,
                      style: const TextStyle(fontSize: 18),
                    ),
                    title: Text(currency.name),
                    subtitle: Text(currency.code),
                    onTap: () {
                      setState(() {
                        _currencyCode = currency.code;
                        _currencySymbol = currency.symbol;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _saveSubscription() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      
      final renewalDate = AppDateUtils.calculateNextRenewalDate(
        _startDate,
        _billingCycle,
      );
      
      final updatedSubscription = _subscription.copyWith(
        name: _nameController.text,
        amount: amount,
        billingCycle: _billingCycle,
        startDate: _startDate,
        renewalDate: renewalDate,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        website: _websiteController.text.isEmpty ? null : _websiteController.text,
        category: _category,
        notificationsEnabled: _notificationsEnabled,
        notificationDays: _notificationDays,
        currencyCode: _currencyCode,
        logoUrl: _logoUrl,
      );
      
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      subscriptionProvider.updateSubscription(updatedSubscription);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.subscriptionUpdatedSuccess)),
      );
      
      Navigator.pop(context);
    }
  }
} 