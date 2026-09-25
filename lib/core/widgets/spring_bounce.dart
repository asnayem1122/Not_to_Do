import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A tactile wrapper that replaces standard Material ripples with physical
/// spring-based scaling and haptic feedback.
/// 
/// The widget slightly shrinks on tap down (with a light haptic tap), 
/// and springs back with overshoot on release (triggering the action).
class SpringBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  
  /// How much the widget shrinks when pressed (1.0 = no shrink, 0.95 = 5% shrink).
  final double pressedScale;

  const SpringBounce({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.95,
  });

  @override
  State<SpringBounce> createState() => _SpringBounceState();
}

class _SpringBounceState extends State<SpringBounce> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Fast press down, springy bounce back
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 300),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.pressedScale).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.elasticOut, // Generates the physical bounce overshoot
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact(); // Micro-vibration on touch
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap(); // Execute the actual action
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
