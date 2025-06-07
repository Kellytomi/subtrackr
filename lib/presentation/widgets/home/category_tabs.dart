import 'package:flutter/material.dart';

/// Modern category tabs widget for filtering subscriptions
class CategoryTabs extends StatelessWidget {
  final int selectedIndex;
  final List<String> categories;
  final ValueChanged<int> onCategorySelected;

  const CategoryTabs({
    super.key,
    required this.selectedIndex,
    required this.categories,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark 
                ? colorScheme.outline.withOpacity(0.15)
                : colorScheme.outline.withOpacity(0.25),
            width: isDark ? 0.5 : 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: List.generate(categories.length, (index) {
              final isSelected = selectedIndex == index;
              final category = categories[index];
              
              return Expanded(
                child: GestureDetector(
                  onTap: () => onCategorySelected(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? colorScheme.primary 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Container(
                      height: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          style: TextStyle(
                            color: isSelected 
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface.withOpacity(0.75),
                            fontWeight: isSelected 
                                ? FontWeight.w600 
                                : FontWeight.w500,
                            fontSize: _getFontSize(category),
                            letterSpacing: 0.2,
                          ),
                          child: Text(
                            category,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
  
  /// Dynamic font sizing based on text length for optimal fit
  double _getFontSize(String text) {
    if (text.length <= 3) return 13.0;      // "All"
    if (text.length <= 6) return 12.0;      // "Active"
    if (text.length <= 8) return 11.5;      // "Due Soon"
    if (text.length <= 9) return 11.0;      // "Cancelled"
    return 10.5;                             // Fallback for longer text
  }
} 