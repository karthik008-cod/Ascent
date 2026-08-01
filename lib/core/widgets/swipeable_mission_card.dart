import 'package:flutter/material.dart';
import '../../features/tasks/data/models/mission.dart';
import '../constants/app_colors.dart';

class SwipeableMissionCard extends StatefulWidget {
  final Mission mission;
  final Widget child;
  final Future<void> Function() onComplete;
  final Future<void> Function() onDelete;

  const SwipeableMissionCard({
    super.key,
    required this.mission,
    required this.child,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  State<SwipeableMissionCard> createState() => _SwipeableMissionCardState();
}

class _SwipeableMissionCardState extends State<SwipeableMissionCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0.0;
  final double _actionThreshold = 0.35; // 35% of screen width triggers action

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.addListener(() {
      setState(() {
        _dragExtent = _controller.value * _dragExtent.sign * MediaQuery.of(context).size.width;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.primaryDelta!;
    });
  }

  void _handleDragEnd(DragEndDetails details) async {
    final width = MediaQuery.of(context).size.width;
    final progress = _dragExtent / width;

    if (progress > _actionThreshold) {
      // Swiped right -> Complete
      await widget.onComplete();
      _snapBack();
    } else if (progress < -_actionThreshold) {
      // Swiped left -> Delete
      await widget.onDelete();
      // Snap back because the item will be removed by the provider
      _snapBack();
    } else {
      // Snap back without action
      _snapBack();
    }
  }

  void _snapBack() {
    _controller.value = _dragExtent.abs() / MediaQuery.of(context).size.width;
    _controller.animateTo(0.0, curve: Curves.easeOutBack);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final progress = (_dragExtent / width).clamp(-1.0, 1.0);
    final absProgress = progress.abs();

    return Stack(
      children: [
        // Background Actions Layer
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: progress > 0 ? AppColors.success : AppColors.error,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                // Complete Action (Left side, Swiping Right)
                if (progress > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 30.0),
                      child: Transform.scale(
                        scale: Curves.easeOutBack.transform((absProgress / _actionThreshold).clamp(0.0, 1.0)),
                        child: Transform.rotate(
                          angle: (1 - (absProgress / _actionThreshold).clamp(0.0, 1.0)) * -0.5,
                          child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 36),
                        ),
                      ),
                    ),
                  ),
                // Delete Action (Right side, Swiping Left)
                if (progress < 0)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 30.0),
                      child: Transform.scale(
                        scale: Curves.easeOutBack.transform((absProgress / _actionThreshold).clamp(0.0, 1.0)),
                        child: Transform.rotate(
                          angle: (1 - (absProgress / _actionThreshold).clamp(0.0, 1.0)) * 0.5,
                          child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 36),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Foreground Card Layer
        GestureDetector(
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          child: Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
