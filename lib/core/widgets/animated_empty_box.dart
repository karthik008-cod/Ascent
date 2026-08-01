import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedEmptyBox extends StatefulWidget {
  final String text;
  final double size;
  final Color? color;

  const AnimatedEmptyBox({
    super.key,
    required this.text,
    this.size = 120.0,
    this.color,
  });

  @override
  State<AnimatedEmptyBox> createState() => _AnimatedEmptyBoxState();
}

class _AnimatedEmptyBoxState extends State<AnimatedEmptyBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Continuous open and close
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final boxColor = widget.color ?? theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;
              
              // Open and close logic (pause open, pause closed)
              // 0.0 - 0.2: Open
              // 0.2 - 0.5: Stay open
              // 0.5 - 0.7: Close
              // 0.7 - 1.0: Stay closed
              
              double lidAngle = 0.0;
              if (t < 0.2) {
                // Opening (0 to -45 deg)
                lidAngle = -math.pi / 4 * (t / 0.2);
              } else if (t < 0.5) {
                // Open
                lidAngle = -math.pi / 4;
                // Add a small hover/wobble effect while open
                lidAngle += math.sin((t - 0.2) * 20) * 0.05;
              } else if (t < 0.7) {
                // Closing
                lidAngle = -math.pi / 4 * (1 - ((t - 0.5) / 0.2));
              } else {
                // Closed
                lidAngle = 0.0;
              }

              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Back of the box
                  Positioned(
                    bottom: 20,
                    child: Container(
                      width: widget.size * 0.6,
                      height: widget.size * 0.4,
                      decoration: BoxDecoration(
                        color: boxColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  
                  // Inside shadow / void
                  Positioned(
                    bottom: 25,
                    child: Container(
                      width: widget.size * 0.5,
                      height: widget.size * 0.25,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  
                  // Front of the box
                  Positioned(
                    bottom: 20,
                    child: Container(
                      width: widget.size * 0.65,
                      height: widget.size * 0.35,
                      decoration: BoxDecoration(
                        color: boxColor.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: boxColor.withOpacity(0.9),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  
                  // Animated Lid
                  Positioned(
                    bottom: 20 + widget.size * 0.35 - 5,
                    left: widget.size * 0.175, // (1 - 0.65)/2
                    child: Transform(
                      alignment: Alignment.bottomLeft,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateZ(lidAngle),
                      child: Container(
                        width: widget.size * 0.65,
                        height: widget.size * 0.15,
                        decoration: BoxDecoration(
                          color: boxColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.text,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white70,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
