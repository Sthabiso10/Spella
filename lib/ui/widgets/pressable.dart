import 'package:flutter/material.dart';
import 'package:spella/ui/common/ui_helpers.dart';

/// Wraps [child] so it dips slightly under the finger.
///
/// This is the app's single touch response. Material's ripple washes a bright
/// circle across a dark surface and always lands a frame late; a small scale
/// starts on touch-down, reads as physical, and costs nothing to composite.
///
/// Anything tappable that is not a plain piece of text should be wrapped in
/// one of these, so the whole app answers to a finger the same way.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.child,
    required this.onPressed,
    this.scale = 0.97,
    this.behavior = HitTestBehavior.opaque,
    this.onLongPress,
    super.key,
  });

  final Widget child;

  /// `null` disables the interaction, leaving the child untouched.
  final VoidCallback? onPressed;

  /// How far the child dips. Large surfaces need less than small ones - the
  /// same ratio moves far more pixels on a full-width card than on a chip.
  final double scale;

  final HitTestBehavior behavior;
  final VoidCallback? onLongPress;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (!_isEnabled || _isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onPressed,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _isPressed ? widget.scale : 1,
        // Faster going down than coming back up, which is how a real button
        // behaves and why the interaction feels immediate rather than springy.
        duration: _isPressed ? AppMotion.instant : AppMotion.quick,
        curve: AppMotion.enter,
        child: widget.child,
      ),
    );
  }
}
