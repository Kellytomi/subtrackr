import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subtrackr/core/utils/tips_helper.dart';

/// A feature tutorial widget that guides users through multiple aspects of the app
class FeatureTutorial extends StatefulWidget {
  /// The widget that this tutorial wraps
  final Widget child;
  
  /// Key for storing tutorial completion status
  final String tutorialKey;
  
  /// Tips to display in order
  final List<TutorialTip> tips;
  
  /// Whether the tutorial should start automatically
  final bool autoStart;
  
  /// Callback when the tutorial is completed
  final VoidCallback? onComplete;

  const FeatureTutorial({
    super.key,
    required this.child,
    required this.tutorialKey,
    required this.tips,
    this.autoStart = true,
    this.onComplete,
  });

  @override
  State<FeatureTutorial> createState() => _FeatureTutorialState();
}

/// Represents a single tip in a feature tutorial
class TutorialTip {
  /// The title of the tip
  final String title;
  
  /// The content/message of the tip
  final String message;
  
  /// The icon to display with the tip
  final IconData icon;
  
  /// Position on screen where tip should appear (normalized coordinates 0.0-1.0)
  final Offset position;
  
  /// The alignment of the tip relative to its position
  final Alignment alignment;
  
  /// A key to identify the widget to highlight (optional)
  final GlobalKey? targetKey;

  TutorialTip({
    required this.title,
    required this.message,
    required this.icon,
    required this.position,
    this.alignment = Alignment.center,
    this.targetKey,
  });
}

class _FeatureTutorialState extends State<FeatureTutorial> with SingleTickerProviderStateMixin {
  int _currentTipIndex = -1;
  bool _isTutorialActive = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    if (widget.autoStart) {
      // Check if this tutorial has been completed
      _checkTutorialStatus();
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final tutorialCompleted = prefs.getBool('tutorial_${widget.tutorialKey}_completed') ?? false;
    
    // If the tutorial hasn't been completed, start it
    if (!tutorialCompleted && mounted) {
      // Delay showing the first tip to allow widgets to layout
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _startTutorial();
        }
      });
    }
  }
  
  void _startTutorial() {
    setState(() {
      _currentTipIndex = 0;
      _isTutorialActive = true;
    });
    _animationController.forward();
  }
  
  void _showNextTip() {
    // If we're at the last tip, end the tutorial
    if (_currentTipIndex >= widget.tips.length - 1) {
      _endTutorial();
      return;
    }
    
    // Animate out current tip
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _currentTipIndex++;
        });
        _animationController.forward();
      }
    });
  }
  
  Future<void> _endTutorial() async {
    await _animationController.reverse();
    
    if (mounted) {
      setState(() {
        _isTutorialActive = false;
        _currentTipIndex = -1;
      });
    }
    
    // Mark tutorial as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_${widget.tutorialKey}_completed', true);
    
    // Call completion callback if provided
    if (widget.onComplete != null) {
      widget.onComplete!();
    }
    
    // Also mark all tips as shown in the TipsHelper
    await TipsHelper.markAllTipsAsShown();
  }
  
  void _skipTutorial() {
    _endTutorial();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The main content
        widget.child,
        
        // The tutorial overlay
        if (_isTutorialActive && _currentTipIndex >= 0 && _currentTipIndex < widget.tips.length)
          Positioned.fill(
            child: _buildTutorialOverlay(context),
          ),
      ],
    );
  }
  
  Widget _buildTutorialOverlay(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final currentTip = widget.tips[_currentTipIndex];
    
    // Calculate the position based on the normalized coordinates
    final position = Offset(
      currentTip.position.dx * screenSize.width,
      currentTip.position.dy * screenSize.height,
    );
    
    // If we have a target key, use its position instead
    Rect? highlightRect;
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
      }
    }
    
    // Get the primary color or use a nice blue if it's too dark/light
    final colorScheme = Theme.of(context).colorScheme;
    final dialogColor = colorScheme.brightness == Brightness.dark 
        ? Color(0xFF2196F3) // Use a nicer blue for dark mode
        : colorScheme.primary;
    
    return Stack(
      children: [
        // Semi-transparent overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: () {}, // Prevent taps from going through
            child: Container(
              color: Colors.black.withOpacity(0.6),
              child: highlightRect != null
                  ? AnimatedHighlightPainter(highlightRect: highlightRect)
                  : null,
            ),
          ),
        ),
        
        // Tip content
        Positioned(
          left: position.dx - 140, // Center the 280px wide dialog
          top: position.dy,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Material(
              color: Colors.transparent,
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 280,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: BoxDecoration(
                  color: dialogColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            currentTip.icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentTip.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currentTip.message,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Skip button (only show if not on the last tip)
                        if (_currentTipIndex < widget.tips.length - 1)
                          TextButton(
                            onPressed: _skipTutorial,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white.withOpacity(0.7),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: const Size(60, 32),
                            ),
                            child: const Text('Skip'),
                          )
                        else
                          const SizedBox(width: 60),
                          
                        // Progress indicators
                        if (widget.tips.length > 1)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              widget.tips.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: index == _currentTipIndex ? 20 : 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: index == _currentTipIndex
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                                ),
                              ),
                            ),
                          ),
                          
                        // Next or Finish button
                        TextButton(
                          onPressed: _showNextTip,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: const Size(80, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            backgroundColor: Colors.white.withOpacity(0.2),
                          ),
                          child: Text(
                            _currentTipIndex < widget.tips.length - 1 ? 'Next' : 'Finish',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter to create a highlighting effect around a widget
class HighlightPainter extends CustomPainter {
  final Rect highlightRect;
  final double cornerRadius;
  final double glowIntensity;
  
  HighlightPainter({
    required this.highlightRect,
    this.cornerRadius = 16.0,
    this.glowIntensity = 0.8,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Create a path for the entire screen
    final fullScreenPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // Create a path for the highlighted area with rounded corners
    final highlightPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          highlightRect.inflate(6), // Add a small padding
          Radius.circular(cornerRadius),
        ),
      );
    
    // Cut out the highlighted area from the full screen
    final finalPath = Path.combine(
      PathOperation.difference,
      fullScreenPath,
      highlightPath,
    );
    
    // Draw the path with the cut-out
    canvas.drawPath(
      finalPath,
      Paint()..color = Colors.black.withOpacity(0.7),
    );
    
    // Draw a glowing border around the highlighted area - multiple strokes for better glow effect
    for (int i = 0; i < 3; i++) {
      final strokeWidth = (3 - i) * 1.0; // Decreasing stroke width
      final opacity = (0.9 - (i * 0.2)) * glowIntensity; // Decreasing opacity
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          highlightRect.inflate(6 + i * 2), // Increasing inflation
          Radius.circular(cornerRadius + i * 1),
        ),
        Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant HighlightPainter oldDelegate) {
    return oldDelegate.highlightRect != highlightRect || 
           oldDelegate.cornerRadius != cornerRadius ||
           oldDelegate.glowIntensity != glowIntensity;
  }
}

/// A stateful wrapper for the highlight effect to create a pulsating animation
class AnimatedHighlightPainter extends StatefulWidget {
  final Rect highlightRect;
  
  const AnimatedHighlightPainter({
    super.key,
    required this.highlightRect,
  });
  
  @override
  State<AnimatedHighlightPainter> createState() => _AnimatedHighlightPainterState();
}

class _AnimatedHighlightPainterState extends State<AnimatedHighlightPainter> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: HighlightPainter(
            highlightRect: widget.highlightRect,
            glowIntensity: _pulseAnimation.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
} 