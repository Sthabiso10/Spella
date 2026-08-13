import 'dart:math';

import 'package:flutter/widgets.dart';

/// Shakes [child] horizontally whenever [trigger] flips to `true`.
///
/// Used to reject an invalid word without needing a dialog or a snackbar.
class Shake extends StatefulWidget {
  const Shake({
    required this.trigger,
    required this.child,
    this.amplitude = 10,
    this.duration = const Duration(milliseconds: 500),
    super.key,
  });

  final bool trigger;
  final Widget child;

  /// Peak horizontal offset in logical pixels.
  final double amplitude;

  final Duration duration;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void didUpdateWidget(Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      // The child is built once and reused across every animation frame.
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        // Three decaying oscillations.
        final double decay = 1 - _controller.value;
        final double offset = sin(_controller.value * pi * 6) * widget.amplitude * decay;
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
    );
  }
}
