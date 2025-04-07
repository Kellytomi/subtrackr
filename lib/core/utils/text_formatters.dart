import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// TextInputFormatter that adds thousands separators to numbers as they're typed
/// For example: 1000 becomes 1,000
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _numberFormat;

  ThousandsSeparatorInputFormatter({bool allowDecimals = true}) : 
    _numberFormat = NumberFormat.decimalPattern('en_US');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Return empty string if empty
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Preserve cursor position
    int selectionIndex = newValue.selection.end;

    // Only process if the text has changed
    if (oldValue.text == newValue.text) {
      return newValue;
    }

    // If the user is deleting, let them
    if (oldValue.text.length > newValue.text.length) {
      return newValue;
    }

    // Remove all non-digit characters
    String newValueText = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');

    // Prevent more than one decimal point
    if (newValueText.contains('.')) {
      int decimalIndex = newValueText.indexOf('.');
      if (newValueText.substring(decimalIndex + 1).contains('.')) {
        newValueText = newValueText.substring(0, decimalIndex + 1) + 
                      newValueText.substring(decimalIndex + 1).replaceAll('.', '');
      }
    }

    // Format the number
    if (newValueText.isNotEmpty) {
      // Split into integer and decimal parts
      List<String> parts = newValueText.split('.');
      String integerPart = parts[0];
      
      // Format integer part with commas
      if (integerPart.isNotEmpty) {
        integerPart = _formatWithCommas(integerPart);
      }
      
      // Reassemble the number with decimal part if exists
      if (parts.length > 1) {
        newValueText = '$integerPart.${parts[1]}';
      } else {
        newValueText = integerPart;
      }
    }

    // Adjust selection index based on added commas
    int countCommas = newValueText.length - newValue.text.replaceAll(',', '').length;
    selectionIndex += countCommas - (oldValue.text.length - oldValue.text.replaceAll(',', '').length);

    // Return the formatted value
    return TextEditingValue(
      text: newValueText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }

  // Helper method to format number with commas
  String _formatWithCommas(String text) {
    if (text.length <= 3) return text;
    
    // Parse to number and format with commas
    try {
      return _numberFormat.format(int.parse(text));
    } catch (e) {
      return text;
    }
  }
} 