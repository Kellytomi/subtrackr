import 'package:intl/intl.dart';

class Currency {
  final String code;
  final String symbol;
  final String name;
  final String flag;
  
  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flag,
  });
}

class CurrencyUtils {
  // Format a number as currency with the given symbol
  static String formatCurrency(double amount, String currencySymbol) {
    return '$currencySymbol${amount.toStringAsFixed(2)}';
  }
  
  // Format a number as currency with the given symbol and locale
  static String formatCurrencyWithLocale(double amount, String currencySymbol, String locale) {
    final formatter = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 2,
      locale: locale,
    );
    return formatter.format(amount);
  }
  
  // Calculate monthly cost from yearly cost
  static double calculateMonthlyCost(double yearlyCost) {
    return yearlyCost / 12;
  }
  
  // Calculate yearly cost from monthly cost
  static double calculateYearlyCost(double monthlyCost) {
    return monthlyCost * 12;
  }
  
  // Calculate quarterly cost from monthly cost
  static double calculateQuarterlyCost(double monthlyCost) {
    return monthlyCost * 3;
  }
  
  // Calculate cost for a specific billing cycle
  static double calculateCostForBillingCycle(double monthlyCost, String billingCycle) {
    switch (billingCycle) {
      case 'monthly':
        return monthlyCost;
      case 'quarterly':
        return calculateQuarterlyCost(monthlyCost);
      case 'yearly':
        return calculateYearlyCost(monthlyCost);
      default:
        return monthlyCost;
    }
  }
  
  // Format a number as currency with the given symbol and add the billing cycle
  static String formatCurrencyWithBillingCycle(double amount, String currencySymbol, String billingCycle) {
    final formattedAmount = formatCurrency(amount, currencySymbol);
    
    switch (billingCycle) {
      case 'monthly':
        return '$formattedAmount/month';
      case 'quarterly':
        return '$formattedAmount/quarter';
      case 'yearly':
        return '$formattedAmount/year';
      case 'custom':
        return formattedAmount;
      default:
        return formattedAmount;
    }
  }
  
  // Get a list of all available currencies
  static List<Currency> getAllCurrencies() {
    return [
      const Currency(code: 'USD', symbol: '\$', name: 'US Dollar', flag: '🇺🇸'),
      const Currency(code: 'EUR', symbol: '€', name: 'Euro', flag: '🇪🇺'),
      const Currency(code: 'GBP', symbol: '£', name: 'British Pound', flag: '🇬🇧'),
      const Currency(code: 'JPY', symbol: '¥', name: 'Japanese Yen', flag: '🇯🇵'),
      const Currency(code: 'CNY', symbol: '¥', name: 'Chinese Yuan', flag: '🇨🇳'),
      const Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee', flag: '🇮🇳'),
      const Currency(code: 'NGN', symbol: '₦', name: 'Nigerian Naira', flag: '🇳🇬'),
      const Currency(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar', flag: '🇦🇺'),
      const Currency(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar', flag: '🇨🇦'),
      const Currency(code: 'RUB', symbol: '₽', name: 'Russian Ruble', flag: '🇷🇺'),
      const Currency(code: 'KRW', symbol: '₩', name: 'South Korean Won', flag: '🇰🇷'),
      const Currency(code: 'TRY', symbol: '₺', name: 'Turkish Lira', flag: '🇹🇷'),
      const Currency(code: 'UAH', symbol: '₴', name: 'Ukrainian Hryvnia', flag: '🇺🇦'),
      const Currency(code: 'ZAR', symbol: 'R', name: 'South African Rand', flag: '🇿🇦'),
      const Currency(code: 'SEK', symbol: 'kr', name: 'Swedish Krona', flag: '🇸🇪'),
      const Currency(code: 'CHF', symbol: 'CHF', name: 'Swiss Franc', flag: '🇨🇭'),
      const Currency(code: 'BRL', symbol: 'R\$', name: 'Brazilian Real', flag: '🇧🇷'),
      const Currency(code: 'MXN', symbol: '\$', name: 'Mexican Peso', flag: '🇲🇽'),
      const Currency(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar', flag: '🇸🇬'),
      const Currency(code: 'NZD', symbol: 'NZ\$', name: 'New Zealand Dollar', flag: '🇳🇿'),
      const Currency(code: 'HKD', symbol: 'HK\$', name: 'Hong Kong Dollar', flag: '🇭🇰'),
      const Currency(code: 'NOK', symbol: 'kr', name: 'Norwegian Krone', flag: '🇳🇴'),
      const Currency(code: 'DKK', symbol: 'kr', name: 'Danish Krone', flag: '🇩🇰'),
      const Currency(code: 'PLN', symbol: 'zł', name: 'Polish Złoty', flag: '🇵🇱'),
      const Currency(code: 'THB', symbol: '฿', name: 'Thai Baht', flag: '🇹🇭'),
      const Currency(code: 'IDR', symbol: 'Rp', name: 'Indonesian Rupiah', flag: '🇮🇩'),
      const Currency(code: 'CZK', symbol: 'Kč', name: 'Czech Koruna', flag: '🇨🇿'),
      const Currency(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham', flag: '🇦🇪'),
      const Currency(code: 'SAR', symbol: '﷼', name: 'Saudi Riyal', flag: '🇸🇦'),
      const Currency(code: 'PHP', symbol: '₱', name: 'Philippine Peso', flag: '🇵🇭'),
      const Currency(code: 'ILS', symbol: '₪', name: 'Israeli New Shekel', flag: '🇮🇱'),
      const Currency(code: 'EGP', symbol: 'E£', name: 'Egyptian Pound', flag: '🇪🇬'),
      const Currency(code: 'CLP', symbol: '\$', name: 'Chilean Peso', flag: '🇨🇱'),
      const Currency(code: 'COP', symbol: '\$', name: 'Colombian Peso', flag: '🇨🇴'),
      const Currency(code: 'ARS', symbol: '\$', name: 'Argentine Peso', flag: '🇦🇷'),
      const Currency(code: 'BTC', symbol: '₿', name: 'Bitcoin', flag: '🪙'),
      const Currency(code: 'ETH', symbol: 'Ξ', name: 'Ethereum', flag: '🪙'),
    ];
  }
  
  // Get a currency by its code
  static Currency? getCurrencyByCode(String code) {
    final currencies = getAllCurrencies();
    try {
      return currencies.firstWhere((currency) => currency.code == code);
    } catch (e) {
      return null;
    }
  }
  
  // Get a currency by its symbol
  static Currency? getCurrencyBySymbol(String symbol) {
    final currencies = getAllCurrencies();
    try {
      return currencies.firstWhere((currency) => currency.symbol == symbol);
    } catch (e) {
      return null;
    }
  }
  
  // Get a map of currency symbols to names (for backward compatibility)
  static Map<String, String> getCurrencySymbols() {
    final currencies = getAllCurrencies();
    final Map<String, String> result = {};
    
    for (final currency in currencies) {
      result[currency.symbol] = '${currency.code} (${currency.name})';
    }
    
    return result;
  }
} 