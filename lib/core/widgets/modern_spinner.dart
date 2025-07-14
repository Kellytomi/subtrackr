import 'package:flutter/material.dart';

/// Modern animated spinner with customizable size and colors
class ModernSpinner extends StatefulWidget {
  final double size;
  final Color? color;
  final Duration duration;
  final SpinnerType type;
  
  const ModernSpinner({
    Key? key,
    this.size = 24.0,
    this.color,
    this.duration = const Duration(milliseconds: 1200),
    this.type = SpinnerType.dots,
  }) : super(key: key);
  
  @override
  State<ModernSpinner> createState() => _ModernSpinnerState();
}

enum SpinnerType { dots, pulse, ring }

class _ModernSpinnerState extends State<ModernSpinner>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    
    switch (widget.type) {
      case SpinnerType.dots:
        return _buildDotsSpinner(color);
      case SpinnerType.pulse:
        return _buildPulseSpinner(color);
      case SpinnerType.ring:
        return _buildRingSpinner(color);
    }
  }

  Widget _buildDotsSpinner(Color color) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              final delay = index * 0.2;
              final animationValue = (_controller.value - delay).clamp(0.0, 1.0);
              
              // Safer animation calculation to prevent painting assertions
              double scale;
              if (animationValue <= 0.0) {
                scale = 0.0;
              } else if (animationValue >= 1.0) {
                scale = 1.0;
              } else {
                scale = Curves.elasticOut.transform(
                  (animationValue * 2).clamp(0.0, 1.0),
                );
              }
              
              // Ensure scale is always valid and clamped
              final finalScale = (0.3 + (scale * 0.7)).clamp(0.1, 1.0);
              
              return Transform.scale(
                scale: finalScale,
                child: Container(
                  width: widget.size * 0.2,
                  height: widget.size * 0.2,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.4 + (scale * 0.6)),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildPulseSpinner(Color color) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final pulseValue = (Curves.easeInOut.transform(_controller.value));
          
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Transform.scale(
                scale: 0.8 + (pulseValue * 0.4),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withOpacity(0.3 - (pulseValue * 0.2)),
                      width: 2,
                    ),
                  ),
                ),
              ),
              // Inner dot
              Transform.scale(
                scale: 0.6 + (pulseValue * 0.2),
                child: Container(
                  width: widget.size * 0.3,
                  height: widget.size * 0.3,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.7 + (pulseValue * 0.3)),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRingSpinner(Color color) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * 2 * 3.14159,
            child: CustomPaint(
              painter: _RingSpinnerPainter(
                color: color,
                progress: _controller.value,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingSpinnerPainter extends CustomPainter {
  final Color color;
  final double progress;

  _RingSpinnerPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - paint.strokeWidth / 2;

    // Background ring
    paint.color = color.withOpacity(0.1);
    canvas.drawCircle(center, radius, paint);

    // Progress arc
    paint.color = color;
    final sweepAngle = 2 * 3.14159 * 0.25; // 25% of the circle
    final startAngle = -3.14159 / 2; // Start from top
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 