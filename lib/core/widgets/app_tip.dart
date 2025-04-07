import 'package:flutter/material.dart';
import 'package:subtrackr/core/utils/tips_helper.dart';

/// A widget that displays a tip for first-time users
class AppTip extends StatefulWidget {
  /// The key for this tip (used to mark it as shown)
  final String tipKey;
  
  /// The title of the tip
  final String title;
  
  /// The content/message of the tip
  final String message;
  
  /// The icon to display with the tip
  final IconData icon;
  
  /// The position where the tip should be anchored relative to the child widget
  final TipPosition position;
  
  /// A widget that will be highlighted by the tip
  final Widget child;
  
  /// Optional callback when the user dismisses the tip
  final VoidCallback? onDismiss;
  
  /// Whether to automatically position the tip based on available screen space
  final bool autoPosition;

  const AppTip({
    Key? key,
    required this.tipKey,
    required this.title,
    required this.message,
    required this.icon,
    required this.position,
    required this.child,
    this.onDismiss,
    this.autoPosition = true,
  }) : super(key: key);

  @override
  State<AppTip> createState() => _AppTipState();
}

/// Position options for the tip relative to the child widget
enum TipPosition {
  top,
  bottom,
  left,
  right,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class _AppTipState extends State<AppTip> with SingleTickerProviderStateMixin {
  bool _showTip = false;
  final GlobalKey _childKey = GlobalKey();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    // Check if this tip has been shown before
    _checkIfTipShouldBeShown();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _checkIfTipShouldBeShown() async {
    final hasBeenShown = await TipsHelper.isTipShown(widget.tipKey);
    
    if (!hasBeenShown) {
      // Add a slight delay to ensure the child widget is laid out
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showTip = true;
          });
          _animationController.forward();
        }
      });
    }
  }
  
  void _dismissTip() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showTip = false;
        });
      }
      TipsHelper.markTipAsShown(widget.tipKey);
      
      if (widget.onDismiss != null) {
        widget.onDismiss!();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The highlighted widget
        Container(
          key: _childKey,
          child: widget.child,
        ),
        
        // The tip overlay
        if (_showTip)
          LayoutBuilder(
            builder: (context, constraints) {
              // Get the position of the child widget
              final RenderBox? renderBox = _childKey.currentContext?.findRenderObject() as RenderBox?;
              
              if (renderBox == null) {
                return const SizedBox();
              }
              
              final childSize = renderBox.size;
              final childPosition = renderBox.localToGlobal(Offset.zero);
              
              // Calculate the position for the tip
              Offset tipPosition = _calculateTipPosition(
                childPosition, 
                childSize,
                constraints,
                MediaQuery.of(context).size,
              );
              
              return Positioned(
                left: tipPosition.dx,
                top: tipPosition.dy,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: min(280, constraints.maxWidth * 0.8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  widget.icon,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.title,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.message,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _dismissTip,
                                style: TextButton.styleFrom(
                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                                ),
                                child: const Text('Got it'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
  
  Offset _calculateTipPosition(
    Offset childPosition, 
    Size childSize,
    BoxConstraints constraints,
    Size screenSize,
  ) {
    // Calculate the default positions based on the specified position
    double dx = childPosition.dx;
    double dy = childPosition.dy;
    
    // Adjust the position based on the requested position
    switch (widget.position) {
      case TipPosition.top:
        dx = childPosition.dx + (childSize.width / 2) - 140;
        dy = childPosition.dy - 150;
        break;
      case TipPosition.bottom:
        dx = childPosition.dx + (childSize.width / 2) - 140;
        dy = childPosition.dy + childSize.height + 10;
        break;
      case TipPosition.left:
        dx = childPosition.dx - 300;
        dy = childPosition.dy + (childSize.height / 2) - 50;
        break;
      case TipPosition.right:
        dx = childPosition.dx + childSize.width + 10;
        dy = childPosition.dy + (childSize.height / 2) - 50;
        break;
      case TipPosition.topLeft:
        dx = childPosition.dx - 240;
        dy = childPosition.dy - 120;
        break;
      case TipPosition.topRight:
        dx = childPosition.dx + childSize.width - 50;
        dy = childPosition.dy - 120;
        break;
      case TipPosition.bottomLeft:
        dx = childPosition.dx - 240;
        dy = childPosition.dy + childSize.height + 10;
        break;
      case TipPosition.bottomRight:
        dx = childPosition.dx + childSize.width - 50;
        dy = childPosition.dy + childSize.height + 10;
        break;
    }
    
    // If auto-position is enabled, adjust to fit on screen
    if (widget.autoPosition) {
      // Ensure the tip stays within horizontal bounds
      if (dx < 10) {
        dx = 10;
      } else if (dx + 280 > screenSize.width - 10) {
        dx = screenSize.width - 290;
      }
      
      // Ensure the tip stays within vertical bounds
      if (dy < 10) {
        dy = 10;
      } else if (dy + 150 > screenSize.height - 10) {
        dy = screenSize.height - 160;
      }
    }
    
    return Offset(dx, dy);
  }
  
  // Helper to get the minimum value between two numbers
  double min(double a, double b) => a < b ? a : b;
} 