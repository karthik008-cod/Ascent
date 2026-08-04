import 'package:flutter/material.dart';
import '../../features/tasks/data/models/mission.dart';
import '../constants/app_colors.dart';

class SwipeableMissionCard extends StatefulWidget {
  final Mission mission;
  final Widget child;
  final Future<void> Function() onComplete;
  final Future<void> Function() onDelete;
  final Future<bool> Function()? confirmComplete;
  final Future<bool> Function()? confirmDelete;

  const SwipeableMissionCard({
    super.key,
    required this.mission,
    required this.child,
    required this.onComplete,
    required this.onDelete,
    this.confirmComplete,
    this.confirmDelete,
  });

  @override
  State<SwipeableMissionCard> createState() => _SwipeableMissionCardState();
}

class _SwipeableMissionCardState extends State<SwipeableMissionCard> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _collapseController;
  double _dragExtent = 0.0;
  final double _actionThreshold = 0.35;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _collapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _collapseController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_dismissed) return;
    setState(() {
      _dragExtent += details.primaryDelta!;
    });
  }

  void _handleDragEnd(DragEndDetails details) async {
    if (_dismissed) return;
    final width = MediaQuery.of(context).size.width;
    final progress = _dragExtent / width;

    if (progress > _actionThreshold) {
      if (widget.confirmComplete != null) {
        bool proceed = await widget.confirmComplete!();
        if (!proceed) {
          _snapBack();
          return;
        }
      }
      await _dismiss(isComplete: true);
    } else if (progress < -_actionThreshold) {
      if (widget.confirmDelete != null) {
        bool proceed = await widget.confirmDelete!();
        if (!proceed) {
          _snapBack();
          return;
        }
      }
      await _dismiss(isComplete: false);
    } else {
      _snapBack();
    }
  }

  Future<void> _dismiss({required bool isComplete}) async {
    if (_dismissed) return;
    _dismissed = true;

    final width = MediaQuery.of(context).size.width;
    final direction = isComplete ? 1.0 : -1.0;
    final startProgress = (_dragExtent / width).abs();

    // Phase 1: Slide card off screen
    _slideController.value = startProgress;
    await _slideController.animateTo(1.0, curve: Curves.easeOut);
    if (!mounted) return;

    // Update the drag extent to be fully off screen
    setState(() {
      _dragExtent = direction * width;
    });

    // Phase 2: Collapse height smoothly
    await _collapseController.animateTo(1.0, curve: Curves.easeInOut);
    if (!mounted) return;

    // Phase 3: Fire the action
    if (isComplete) {
      await widget.onComplete();
    } else {
      await widget.onDelete();
    }
  }

  void _snapBack() {
    final width = MediaQuery.of(context).size.width;
    final startProgress = (_dragExtent / width).abs();
    _slideController.value = startProgress;

    final sign = _dragExtent.sign;
    _slideController.animateTo(0.0, curve: Curves.easeOutBack).then((_) {
      if (mounted && !_dismissed) {
        setState(() => _dragExtent = 0.0);
      }
    });

    _slideController.addListener(_snapBackListener);
  }

  void _snapBackListener() {
    if (!mounted || _dismissed) {
      _slideController.removeListener(_snapBackListener);
      return;
    }
    final width = MediaQuery.of(context).size.width;
    setState(() {
      _dragExtent = _slideController.value * _dragExtent.sign * width;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final progress = (_dragExtent / width).clamp(-1.0, 1.0);
    final absProgress = progress.abs();

    return SizeTransition(
      sizeFactor: Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _collapseController, curve: Curves.easeInOut),
      ),
      child: Stack(
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
      ),
    );
  }
}
