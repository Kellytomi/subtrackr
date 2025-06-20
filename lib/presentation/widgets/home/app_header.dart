import 'package:flutter/material.dart';
import 'package:subtrackr/core/constants/app_constants.dart';

/// App header widget displayed at the top of the home screen
class AppHeader extends StatelessWidget {
  final VoidCallback? onSearchPressed;
  
  const AppHeader({super.key, this.onSearchPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.APP_NAME,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track your subscriptions',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.brightness == Brightness.dark 
                        ? Colors.white.withOpacity(0.7) 
                        : Colors.black.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (onSearchPressed != null)
            IconButton(
              icon: Icon(
                Icons.search,
                color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
              onPressed: onSearchPressed,
              tooltip: 'Search',
              style: IconButton.styleFrom(
                backgroundColor: (theme.brightness == Brightness.dark ? Colors.white : Colors.black).withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 