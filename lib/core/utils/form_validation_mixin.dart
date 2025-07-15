import 'package:flutter/material.dart';

/// Mixin that provides consistent form validation behavior across the app
/// Handles error highlighting, auto-scrolling, and validation state management
mixin FormValidationMixin<T extends StatefulWidget> on State<T> {
  /// Form key for validation
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  /// Track field error states for consistent highlighting
  final Map<String, bool> _fieldErrors = {};
  
  /// Track field keys for auto-scrolling
  final Map<String, GlobalKey> _fieldKeys = {};
  
  /// Track focus nodes for auto-scrolling
  final Map<String, FocusNode> _focusNodes = {};
  
  /// Get or create a field key for auto-scrolling
  GlobalKey getFieldKey(String fieldName) {
    _fieldKeys[fieldName] ??= GlobalKey();
    return _fieldKeys[fieldName]!;
  }
  
  /// Get or create a focus node for a field
  FocusNode getFocusNode(String fieldName) {
    _focusNodes[fieldName] ??= FocusNode();
    return _focusNodes[fieldName]!;
  }
  
  /// Check if a field has an error
  bool hasFieldError(String fieldName) {
    return _fieldErrors[fieldName] ?? false;
  }
  
  /// Set error state for a field
  void setFieldError(String fieldName, bool hasError) {
    setState(() {
      _fieldErrors[fieldName] = hasError;
    });
  }
  
  /// Clear error for a specific field
  void clearFieldError(String fieldName) {
    setFieldError(fieldName, false);
  }
  
  /// Clear all field errors
  void clearAllErrors() {
    setState(() {
      _fieldErrors.clear();
    });
  }
  
  /// Validate a required text field
  String? validateRequired(String? value, String fieldName, {String? customMessage}) {
    final hasError = value == null || value.trim().isEmpty;
    setFieldError(fieldName, hasError);
    
    if (hasError) {
      return customMessage ?? 'This field is required';
    }
    return null;
  }
  
  /// Validate a single field without triggering form-wide validation
  bool validateSingleField(String fieldName, String? value, {String? customMessage}) {
    final hasError = value == null || value.trim().isEmpty;
    setFieldError(fieldName, hasError);
    return !hasError;
  }
  
  /// Validate a number field
  String? validateNumber(String? value, String fieldName, {
    String? customMessage,
    double? minValue,
    double? maxValue,
  }) {
    if (value == null || value.trim().isEmpty) {
      setFieldError(fieldName, true);
      return customMessage ?? 'Please enter a number';
    }
    
    final cleanValue = value.replaceAll(',', '');
    final number = double.tryParse(cleanValue);
    
    if (number == null) {
      setFieldError(fieldName, true);
      return 'Please enter a valid number';
    }
    
    if (minValue != null && number < minValue) {
      setFieldError(fieldName, true);
      return 'Value must be at least ${minValue.toString()}';
    }
    
    if (maxValue != null && number > maxValue) {
      setFieldError(fieldName, true);
      return 'Value must be at most ${maxValue.toString()}';
    }
    
    setFieldError(fieldName, false);
    return null;
  }
  
  /// Validate email format
  String? validateEmail(String? value, String fieldName, {String? customMessage}) {
    if (value == null || value.trim().isEmpty) {
      setFieldError(fieldName, true);
      return customMessage ?? 'Please enter an email';
    }
    
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      setFieldError(fieldName, true);
      return 'Please enter a valid email address';
    }
    
    setFieldError(fieldName, false);
    return null;
  }
  
  /// Validate URL format
  String? validateUrl(String? value, String fieldName, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      if (isRequired) {
        setFieldError(fieldName, true);
        return 'Please enter a URL';
      }
      setFieldError(fieldName, false);
      return null;
    }
    
    try {
      final uri = Uri.parse(value.trim());
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        setFieldError(fieldName, true);
        return 'Please enter a valid URL (starting with http:// or https://)';
      }
      setFieldError(fieldName, false);
      return null;
    } catch (e) {
      setFieldError(fieldName, true);
      return 'Please enter a valid URL';
    }
  }
  
  /// Scroll to the first field with an error and show snackbar
  Future<void> scrollToFirstError({String? customMessage}) async {
    final firstErrorField = _fieldErrors.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .firstOrNull;
    
    if (firstErrorField != null) {
      await scrollToField(firstErrorField, customMessage ?? 'Please fix the highlighted field');
    }
  }
  
  /// Scroll to a specific field and optionally show a message
  Future<void> scrollToField(String fieldName, [String? message]) async {
    final fieldKey = _fieldKeys[fieldName];
    final focusNode = _focusNodes[fieldName];
    
    if (message != null && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
    
    // Multiple fallback strategies for reliable scrolling
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (fieldKey?.currentContext != null) {
      try {
        // Strategy 1: Use Scrollable.ensureVisible
        await Scrollable.ensureVisible(
          fieldKey!.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.2, // Show field 20% from top
        );
      } catch (e) {
        debugPrint('Scroll strategy 1 failed: $e');
      }
      
      // Strategy 2: Try manual RenderBox calculation as fallback
      try {
        final renderBox = fieldKey!.currentContext!.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final position = renderBox.localToGlobal(Offset.zero);
          final scrollableContext = Scrollable.of(fieldKey.currentContext!);
          if (scrollableContext != null) {
            await scrollableContext.position.animateTo(
              scrollableContext.position.pixels + position.dy - 200,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        }
      } catch (e) {
        debugPrint('Scroll strategy 2 failed: $e');
      }
    }
    
    // Focus the field after scrolling
    await Future.delayed(const Duration(milliseconds: 600));
    if (focusNode != null && mounted) {
      try {
        focusNode.requestFocus();
      } catch (e) {
        debugPrint('Focus request failed: $e');
      }
    }
  }
  
  /// Perform full form validation and scroll to first error if any
  Future<bool> validateFormAndScroll() async {
    clearAllErrors();
    
    // First pass - trigger built-in validation
    final isValid = formKey.currentState?.validate() ?? false;
    
    if (!isValid) {
      await scrollToFirstError();
      return false;
    }
    
    return true;
  }
  
  /// Get error border decoration for fields
  InputBorder getErrorBorder(String fieldName, {double borderRadius = 16}) {
    final theme = Theme.of(context);
    if (hasFieldError(fieldName)) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(
          color: theme.colorScheme.error,
          width: 2,
        ),
      );
    }
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide.none,
    );
  }
  
  /// Get focused border decoration
  InputBorder getFocusedBorder({double borderRadius = 16}) {
    final theme = Theme.of(context);
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(
        color: theme.colorScheme.primary,
        width: 2,
      ),
    );
  }
  
  /// Dispose all focus nodes when widget is disposed
  void disposeFormValidation() {
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    _focusNodes.clear();
    _fieldKeys.clear();
    _fieldErrors.clear();
  }
} 