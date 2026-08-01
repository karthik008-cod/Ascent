import 'package:flutter/material.dart';
import 'dart:math' as math;

class ClimbingDotsLoader extends StatefulWidget {
  final Color? color;
  final double size;

  const ClimbingDotsLoader({
    super.key,
    this.color,
    this.size = 12.0,
  });

  @override
  State<ClimbingDotsLoader> createState() => _ClimbingDotsLoaderState();
}

class _ClimbingDotsLoaderState extends State<ClimbingDotsLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
    final dotColor = widget.color ?? theme.colorScheme.primary;
    final dotSize = widget.size;
    final gap = dotSize * 0.8;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Wave animation offset by index
            final t = _controller.value;
            final offset = (index * 0.2); // phase shift
            double normalizedTime = (t - offset) % 1.0;
            if (normalizedTime < 0) normalizedTime += 1.0;

            double translationY = 0;
            // Up and down bounce
            if (normalizedTime < 0.5) {
              translationY = -dotSize * 1.5 * math.sin(normalizedTime * 2 * math.pi);
              if (translationY > 0) translationY = 0; // Only bounce up
            }

            return Transform.translate(
              offset: Offset(0, translationY),
              child: child,
            );
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: gap / 2),
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            ),
          ),
        );
      }),
    );
  }
}
