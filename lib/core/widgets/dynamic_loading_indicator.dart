import 'dart:async';
import 'package:flutter/material.dart';

class DynamicLoadingIndicator extends StatefulWidget {
  final List<String> messages;
  final Duration interval;
  final Color? color;
  final TextStyle? textStyle;
  final bool isHorizontal;

  const DynamicLoadingIndicator({
    super.key,
    required this.messages,
    this.interval = const Duration(milliseconds: 1500),
    this.color,
    this.textStyle,
    this.isHorizontal = false,
  });

  @override
  State<DynamicLoadingIndicator> createState() => _DynamicLoadingIndicatorState();
}

class _DynamicLoadingIndicatorState extends State<DynamicLoadingIndicator> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.messages.length > 1) {
      _timer = Timer.periodic(widget.interval, (timer) {
        if (!mounted) return;
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.messages.length;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spinner = SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        color: widget.color ?? Colors.white,
        strokeWidth: 2.5,
      ),
    );

    final textWidget = Text(
      widget.messages[_currentIndex],
      key: ValueKey<int>(_currentIndex),
      style: widget.textStyle ??
          TextStyle(
            color: widget.color ?? Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
      textAlign: TextAlign.center,
    );

    if (widget.isHorizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          spinner,
          const SizedBox(width: 12),
          textWidget,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        spinner,
        const SizedBox(height: 16),
        textWidget,
      ],
    );
  }
}
