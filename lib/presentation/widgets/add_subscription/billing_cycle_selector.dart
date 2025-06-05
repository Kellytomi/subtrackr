import 'package:flutter/material.dart';
import 'package:subtrackr/core/constants/app_constants.dart';

/// Billing cycle selector widget
class BillingCycleSelector extends StatelessWidget {
  final String selectedCycle;
  final ValueChanged<String?> onChanged;

  const BillingCycleSelector({
    super.key,
    required this.selectedCycle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DropdownButtonFormField<String>(
      value: selectedCycle,
      decoration: InputDecoration(
        labelText: 'Billing Cycle',
        prefixIcon: const Icon(Icons.calendar_today_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
      items: const [
        DropdownMenuItem(
          value: AppConstants.BILLING_CYCLE_MONTHLY,
          child: Text('Monthly'),
        ),
        DropdownMenuItem(
          value: AppConstants.BILLING_CYCLE_QUARTERLY,
          child: Text('Quarterly'),
        ),
        DropdownMenuItem(
          value: AppConstants.BILLING_CYCLE_YEARLY,
          child: Text('Yearly'),
        ),
      ],
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a billing cycle';
        }
        return null;
      },
    );
  }
} 