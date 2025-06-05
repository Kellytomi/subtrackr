import 'package:flutter/material.dart';
import 'package:subtrackr/core/utils/currency_utils.dart';

/// Currency selector button widget
class CurrencySelectorButton extends StatelessWidget {
  final String currencyCode;
  final VoidCallback onTap;

  const CurrencySelectorButton({
    super.key,
    required this.currencyCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currency = CurrencyUtils.getCurrencyByCode(currencyCode) ?? 
        CurrencyUtils.getAllCurrencies().first;
    
    return InkWell(
      onTap: onTap,
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
    );
  }
} 