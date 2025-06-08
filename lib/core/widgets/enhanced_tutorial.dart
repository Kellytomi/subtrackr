import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subtrackr/core/utils/tips_helper.dart';

enum TutorialArrowDirection {
  up,
  down,
  left,
  right,
  none,
}

/// Enhanced tutorial widget with improved animations and debug features
class EnhancedTutorial extends StatefulWidget {
  final Widget child;
  final String tutorialKey;
  final List<EnhancedTip> tips;
  final bool autoStart;
  final VoidCallback? onComplete;

  const EnhancedTutorial({
    super.key,
    required this.child,
    required this.tutorialKey,
    required this.tips,
    this.autoStart = true,
    this.onComplete,
  });

  @override
  State<EnhancedTutorial> createState() => _EnhancedTutorialState();
}

class EnhancedTip {
  final String title;
  final String message;
  final IconData icon;
  final Offset position;
  final Alignment alignment;
  final GlobalKey? targetKey;
  final Color? backgroundColor;
  final String? debugLabel; // For debug mode
  final VoidCallback? onTipShown; // Callback when tip is shown

  EnhancedTip({
    required this.title,
    required this.message,
    required this.icon,
    required this.position,
    this.alignment = Alignment.center,
    this.targetKey,
    this.backgroundColor,
    this.debugLabel,
    this.onTipShown,
  });
}

class _EnhancedTutorialState extends State<EnhancedTutorial> 
    with TickerProviderStateMixin {
  int _currentTipIndex = -1;
  bool _isTutorialActive = false;
  
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize multiple animation controllers for smoother effects
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Start pulse animation on repeat
    _pulseController.repeat(reverse: true);
    
    if (widget.autoStart) {
      _checkTutorialStatus();
    }
    
    // Debug mode: Listen for debug commands
    if (TipsHelper.isDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDebugOptions();
      });
    }
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _showDebugOptions() {
    if (!TipsHelper.isDebugMode) return;
    
    // Add a debug gesture detector
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🐛 Debug: Tutorial Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow, color: Colors.green),
              title: Text('Start ${widget.tutorialKey} Tutorial'),
              onTap: () {
                Navigator.pop(context);
                _forceTutorial();
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.orange),
              title: const Text('Reset All Tips'),
              onTap: () async {
                Navigator.pop(context);
                await TipsHelper.resetAllTips();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🐛 Debug: All tips reset!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final tutorialCompleted = prefs.getBool('tutorial_${widget.tutorialKey}_completed') ?? false;
    
    if (!tutorialCompleted && mounted) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _startTutorial();
        }
      });
    }
  }
  
  bool _dialogOverlapsTarget(Offset dialogPosition, double dialogWidth, double dialogHeight, Rect targetRect) {
    final dialogRect = Rect.fromLTWH(
      dialogPosition.dx - dialogWidth / 2,
      dialogPosition.dy,
      dialogWidth,
      dialogHeight,
    );
    return dialogRect.overlaps(targetRect.inflate(60)); // Add generous margin to prevent any overlap
  }
  
  void _forceTutorial() {
    _startTutorial();
  }
  
  void _startTutorial() {
    setState(() {
      _currentTipIndex = 0;
      _isTutorialActive = true;
    });
    _fadeController.forward();
    _scaleController.forward();
    
    // Call the onTipShown callback if it exists
    if (widget.tips.isNotEmpty && widget.tips[0].onTipShown != null) {
      // Delay the callback slightly to ensure the tip is visible
      Future.delayed(const Duration(milliseconds: 300), () {
        widget.tips[0].onTipShown!();
      });
    }
  }
  
  void _showNextTip() {
    if (_currentTipIndex >= widget.tips.length - 1) {
      _endTutorial();
      return;
    }
    
    // Smooth transition between tips
    _fadeController.reverse().then((_) {
      _scaleController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _currentTipIndex++;
          });
          _fadeController.forward();
          _scaleController.forward();
          
          // Call the onTipShown callback for the new tip if it exists
          final currentTip = widget.tips[_currentTipIndex];
          if (currentTip.onTipShown != null) {
            // Delay the callback slightly to ensure the tip is visible
            Future.delayed(const Duration(milliseconds: 300), () {
              currentTip.onTipShown!();
            });
          }
        }
      });
    });
  }
  
  Future<void> _endTutorial() async {
    await _fadeController.reverse();
    await _scaleController.reverse();
    
    if (mounted) {
      setState(() {
        _isTutorialActive = false;
        _currentTipIndex = -1;
      });
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_${widget.tutorialKey}_completed', true);
    
    if (widget.onComplete != null) {
      widget.onComplete!();
    }
    
    await TipsHelper.markAllTipsAsShown();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // Debug overlay (only in debug mode)
        if (TipsHelper.isDebugMode)
          Positioned(
            top: 50,
            right: 20,
            child: FloatingActionButton.small(
              heroTag: "debug_tutorial_${widget.tutorialKey}",
              backgroundColor: Colors.red.withOpacity(0.8),
              child: const Icon(Icons.bug_report, color: Colors.white),
              onPressed: _showDebugOptions,
            ),
          ),
        
        // Tutorial overlay
        if (_isTutorialActive && _currentTipIndex >= 0 && _currentTipIndex < widget.tips.length)
          Positioned.fill(
            child: _buildEnhancedTutorialOverlay(context),
          ),
      ],
    );
  }
  
  Widget _buildEnhancedTutorialOverlay(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final currentTip = widget.tips[_currentTipIndex];
    
    // Calculate position with safe area padding
    final padding = MediaQuery.of(context).padding;
    
    const dialogWidth = 300.0;
    const dialogHeight = 260.0;
    
    // Target highlighting
    Rect? highlightRect;
    Offset? targetCenter;
    
    if (currentTip.targetKey != null) {
      final RenderBox? renderBox = currentTip.targetKey!.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final targetPosition = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;
        highlightRect = Rect.fromLTWH(
          targetPosition.dx,
          targetPosition.dy,
          size.width,
          size.height,
        );
        targetCenter = highlightRect.center;
      }
    }
    
    // Smart positioning based on target location
    Offset position;
    TutorialArrowDirection arrowDirection = TutorialArrowDirection.none;
    
    if (targetCenter != null) {
      // Position dialog relative to target, avoiding overlap
      final isTargetInTopHalf = targetCenter.dy < screenSize.height / 2;
      final isTargetInLeftHalf = targetCenter.dx < screenSize.width / 2;
      
      if (isTargetInTopHalf) {
        // Target is in top half, place dialog below with more spacing
        position = Offset(
          targetCenter.dx.clamp(dialogWidth / 2 + 20, screenSize.width - dialogWidth / 2 - 20),
          (targetCenter.dy + highlightRect!.height / 2 + 120).clamp(padding.top + 20, screenSize.height - dialogHeight - 20),
        );
        arrowDirection = TutorialArrowDirection.up;
      } else {
        // Target is in bottom half, place dialog above with more spacing
        position = Offset(
          targetCenter.dx.clamp(dialogWidth / 2 + 20, screenSize.width - dialogWidth / 2 - 20),
          (targetCenter.dy - highlightRect!.height / 2 - dialogHeight - 120).clamp(padding.top + 20, screenSize.height - dialogHeight - 20),
        );
        arrowDirection = TutorialArrowDirection.down;
      }
      
      // Adjust if dialog still overlaps target
      if (highlightRect != null && _dialogOverlapsTarget(position, dialogWidth, dialogHeight, highlightRect)) {
        if (isTargetInLeftHalf) {
          // Place dialog to the right with more spacing
          position = Offset(
            (targetCenter.dx + highlightRect.width / 2 + 180).clamp(dialogWidth / 2 + 20, screenSize.width - dialogWidth / 2 - 20),
            targetCenter.dy.clamp(padding.top + 20, screenSize.height - dialogHeight - 20),
          );
          arrowDirection = TutorialArrowDirection.left;
        } else {
          // Place dialog to the left with more spacing
          position = Offset(
            (targetCenter.dx - highlightRect.width / 2 - 180).clamp(dialogWidth / 2 + 20, screenSize.width - dialogWidth / 2 - 20),
            targetCenter.dy.clamp(padding.top + 20, screenSize.height - dialogHeight - 20),
          );
          arrowDirection = TutorialArrowDirection.right;
        }
      }
    } else {
      // No target, use original position logic
      position = Offset(
        currentTip.position.dx * screenSize.width,
        currentTip.position.dy * screenSize.height,
      );
      
      // Keep within bounds
      position = Offset(
        position.dx.clamp(dialogWidth / 2 + 20, screenSize.width - dialogWidth / 2 - 20),
        position.dy.clamp(padding.top + 20, screenSize.height - dialogHeight - 20),
      );
    }
    
    // Target highlighting for display
    Rect? displayHighlightRect;
    if (currentTip.targetKey != null) {
      final RenderBox? renderBox = currentTip.targetKey!.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final targetPosition = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;
        displayHighlightRect = Rect.fromLTWH(
          targetPosition.dx,
          targetPosition.dy,
          size.width,
          size.height,
        );
      }
    }
    
    // Enhanced color scheme
    final colorScheme = Theme.of(context).colorScheme;
    final tipColor = currentTip.backgroundColor ?? 
        (colorScheme.brightness == Brightness.dark 
            ? const Color(0xFF6366F1) // Indigo
            : colorScheme.primary);
    
    return Stack(
      children: [
        // Animated overlay
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Container(
                color: Colors.black.withOpacity(0.7 * _fadeAnimation.value),
                child: displayHighlightRect != null
                    ? _EnhancedHighlightPainter(
                        highlightRect: displayHighlightRect,
                        animation: _pulseAnimation,
                      )
                    : null,
              );
            },
          ),
        ),
        
        // Enhanced tip dialog
        Positioned(
          left: position.dx - 150, // Center the 300px wide dialog
          top: position.dy,
          child: AnimatedBuilder(
            animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: _buildTipCard(currentTip, tipColor, arrowDirection, targetCenter),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildTipCard(EnhancedTip tip, Color tipColor, TutorialArrowDirection arrowDirection, Offset? targetCenter) {
    return Material(
      color: Colors.transparent,
      elevation: 12,
      shadowColor: Colors.black.withOpacity(0.5),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 300,
        constraints: const BoxConstraints(
          maxHeight: 260,
          maxWidth: 300,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tipColor,
              tipColor.withBlue((tipColor.blue * 0.8).round()),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: tipColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    tip.icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Debug label
                      if (TipsHelper.isDebugMode && tip.debugLabel != null)
                        Text(
                          '🐛 ${tip.debugLabel}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Message
            Text(
              tip.message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 16),
            
            // Actions
            Column(
              children: [
                // Progress dots
                if (widget.tips.length > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.tips.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: index == _currentTipIndex ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: index == _currentTipIndex
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                // Buttons
                Row(
                  children: [
                    // Skip button
                    if (_currentTipIndex < widget.tips.length - 1)
                      Expanded(
                        child: TextButton(
                          onPressed: _endTutorial,
                          child: const Text('Skip All', 
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ),
                      )
                    else
                      const Spacer(),
                      
                    // Next/Finish button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _showNextTip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: tipColor,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          _currentTipIndex < widget.tips.length - 1 ? 'Next' : 'Finish',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }
}

/// Enhanced highlight painter with pulsing animation
class _EnhancedHighlightPainter extends StatefulWidget {
  final Rect highlightRect;
  final Animation<double> animation;
  
  const _EnhancedHighlightPainter({
    required this.highlightRect,
    required this.animation,
  });
  
  @override
  State<_EnhancedHighlightPainter> createState() => __EnhancedHighlightPainterState();
}

class __EnhancedHighlightPainterState extends State<_EnhancedHighlightPainter> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _HighlightCustomPainter(
            highlightRect: widget.highlightRect,
            pulseValue: widget.animation.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _HighlightCustomPainter extends CustomPainter {
  final Rect highlightRect;
  final double pulseValue;
  
  _HighlightCustomPainter({
    required this.highlightRect,
    required this.pulseValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Create cutout effect
    final fullPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final highlightPath = Path()..addRRect(
      RRect.fromRectAndRadius(
        highlightRect.inflate(8),
        const Radius.circular(16),
      ),
    );
    
    final cutoutPath = Path.combine(PathOperation.difference, fullPath, highlightPath);
    canvas.drawPath(cutoutPath, Paint()..color = Colors.black.withOpacity(0.8));
    
    // Pulsing border effect
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.white.withOpacity(0.8 * pulseValue);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        highlightRect.inflate(8 + (4 * pulseValue)),
        const Radius.circular(16),
      ),
      borderPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant _HighlightCustomPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue || oldDelegate.highlightRect != highlightRect;
  }
} 