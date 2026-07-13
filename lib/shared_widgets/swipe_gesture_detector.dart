import 'package:flutter/material.dart';

/// A widget that detects horizontal and vertical swipe gestures.
class SwipeGestureDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final double swipeThreshold;
  final double verticalThreshold;

  const SwipeGestureDetector({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onSwipeDown,
    this.swipeThreshold = 80.0,
    this.verticalThreshold = 80.0,
  });

  @override
  State<SwipeGestureDetector> createState() => _SwipeGestureDetectorState();
}

class _SwipeGestureDetectorState extends State<SwipeGestureDetector> {
  Offset _dragStart = Offset.zero;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (details) {
        _dragStart = details.localPosition;
        _isDragging = true;
      },
      onHorizontalDragUpdate: (details) {
        // Just track, handle on end
      },
      onHorizontalDragEnd: (details) {
        if (!_isDragging) return;
        _isDragging = false;

        final delta = details.primaryVelocity ?? 0;
        final dragDistance = details.globalPosition.dx - _dragStart.dx;

        if (dragDistance.abs() < widget.swipeThreshold) return;

        if (dragDistance < 0 && widget.onSwipeLeft != null) {
          widget.onSwipeLeft!();
        } else if (dragDistance > 0 && widget.onSwipeRight != null) {
          widget.onSwipeRight!();
        }
      },
      onVerticalDragStart: (details) {
        _dragStart = details.localPosition;
        _isDragging = true;
      },
      onVerticalDragUpdate: (details) {
        // Track
      },
      onVerticalDragEnd: (details) {
        if (!_isDragging) return;
        _isDragging = false;

        final delta = details.primaryVelocity ?? 0;
        final dragDistance = details.globalPosition.dy - _dragStart.dy;

        if (dragDistance.abs() < widget.verticalThreshold) return;

        if (dragDistance < 0 && widget.onSwipeUp != null) {
          widget.onSwipeUp!();
        } else if (dragDistance > 0 && widget.onSwipeDown != null) {
          widget.onSwipeDown!();
        }
      },
      child: widget.child,
    );
  }
}
