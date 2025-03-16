import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<CustomBottomNavItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double elevation;
  final double iconSize;
  final double selectedFontSize;
  final double unselectedFontSize;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation = 8,
    this.iconSize = 24,
    this.selectedFontSize = 14,
    this.unselectedFontSize = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: items.map((item) => item.toBottomNavigationBarItem()).toList(),
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      selectedItemColor: selectedItemColor ?? theme.colorScheme.primary,
      unselectedItemColor: unselectedItemColor ?? theme.colorScheme.onSurface.withOpacity(0.6),
      type: BottomNavigationBarType.fixed,
      elevation: elevation,
      iconSize: iconSize,
      selectedFontSize: selectedFontSize,
      unselectedFontSize: unselectedFontSize,
      showUnselectedLabels: true,
    );
  }
}

class CustomBottomNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final Color? backgroundColor;

  const CustomBottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.backgroundColor,
  });

  BottomNavigationBarItem toBottomNavigationBarItem() {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      activeIcon: activeIcon != null ? Icon(activeIcon) : null,
      label: label,
      backgroundColor: backgroundColor,
    );
  }
}

class CustomFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<CustomBottomNavItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final VoidCallback? onFabPressed;
  final IconData fabIcon;
  final Color? fabColor;
  final String? fabLabel;

  const CustomFloatingNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.onFabPressed,
    this.fabIcon = Icons.add,
    this.fabColor,
    this.fabLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ...List.generate(items.length ~/ 2, (index) {
                return _buildNavItem(
                  context,
                  items[index],
                  index,
                  theme,
                );
              }),
              _buildFab(context, theme),
              ...List.generate(items.length - (items.length ~/ 2), (index) {
                final itemIndex = index + (items.length ~/ 2);
                return _buildNavItem(
                  context,
                  items[itemIndex],
                  itemIndex,
                  theme,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    CustomBottomNavItem item,
    int index,
    ThemeData theme,
  ) {
    final isSelected = currentIndex == index;
    final color = isSelected
        ? selectedItemColor ?? theme.colorScheme.primary
        : unselectedItemColor ?? theme.colorScheme.onSurface.withOpacity(0.6);

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected && item.activeIcon != null ? item.activeIcon : item.icon,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: isSelected ? 12 : 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context, ThemeData theme) {
    return GestureDetector(
      onTap: onFabPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: fabColor ?? theme.colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (fabColor ?? theme.colorScheme.primary).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              fabIcon,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          if (fabLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              fabLabel!,
              style: TextStyle(
                color: fabColor ?? theme.colorScheme.primary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
} 