import 'package:flutter/material.dart';

/// A widget that tracks scroll velocity and passes it to its descendants.
/// Wrap your ListView in this.
class ScrollVelocityTracker extends StatefulWidget {
  final Widget child;

  const ScrollVelocityTracker({super.key, required this.child});

  static _ScrollVelocityTrackerState? of(BuildContext context) {
    return context.findAncestorStateOfType<_ScrollVelocityTrackerState>();
  }

  @override
  State<ScrollVelocityTracker> createState() => _ScrollVelocityTrackerState();
}

class _ScrollVelocityTrackerState extends State<ScrollVelocityTracker> {
  final ValueNotifier<double> velocityNotifier = ValueNotifier<double>(0.0);
  DateTime? _lastTime;
  double? _lastOffset;

  @override
  void dispose() {
    velocityNotifier.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final now = DateTime.now();
      if (_lastTime != null && _lastOffset != null) {
        final dt = now.difference(_lastTime!).inMilliseconds.toDouble();
        if (dt > 0) {
          final dy = notification.metrics.pixels - _lastOffset!;
          // Smooth the velocity a bit
          final currentVelocity = dy / dt; 
          // Cap velocity for sanity
          velocityNotifier.value = currentVelocity.clamp(-15.0, 15.0);
        }
      }
      _lastTime = now;
      _lastOffset = notification.metrics.pixels;
    } else if (notification is ScrollEndNotification) {
      _lastTime = null;
      _lastOffset = null;
      // Spring back to 0
      _animateToZero();
    }
    return false; // Let the notification bubble up
  }

  void _animateToZero() {
    // A simple tick to smoothly bring velocity back to 0
    // Realistically, we'd use an AnimationController, but this simple
    // decay loop works perfectly for the physics snap back.
    if (velocityNotifier.value == 0) return;
    
    // Instead of a loop, we just set it to 0 immediately when scrolling ends.
    // The ScrollBender itself uses an AnimatedContainer to handle the smooth snapping!
    velocityNotifier.value = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: widget.child,
    );
  }
}

/// A wrapper for individual list items that tilts them based on scroll velocity.
class ScrollBender extends StatelessWidget {
  final Widget child;

  const ScrollBender({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final tracker = ScrollVelocityTracker.of(context);
    if (tracker == null) return child;

    return ValueListenableBuilder<double>(
      valueListenable: tracker.velocityNotifier,
      builder: (context, velocity, _) {
        // We use an AnimatedContainer so when velocity drops to 0, it springs back smoothly
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutQuad,
          transformAlignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateX(velocity * 0.02), // tilt based on velocity (up/down)
          child: child,
        );
      },
    );
  }
}
