import 'package:flutter/material.dart';
import 'package:spella/ui/common/ui_helpers.dart';

/// A number that rolls to its new value instead of snapping to it.
///
/// A score jumping from 40 to 88 between frames is information the player can
/// miss. Counting it up costs a quarter of a second and turns a state change
/// into a moment - which, in a game about beating a friend, is the point.
class CountUpText extends StatelessWidget {
  const CountUpText({
    required this.value,
    required this.style,
    this.formatter,
    this.duration = AppMotion.entrance,
    super.key,
  });

  final int value;
  final TextStyle style;

  /// How to render the running value. Defaults to grouped thousands.
  final String Function(int)? formatter;

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      // The tween is rebuilt from the previous value on every change, so the
      // roll always starts where the last one finished rather than from zero.
      tween: IntTween(begin: value, end: value),
      duration: duration,
      curve: AppMotion.enter,
      builder: (BuildContext context, int running, Widget? child) =>
          Text((formatter ?? formatPoints)(running), style: style),
    );
  }
}

/// A figure that pops slightly when it changes, for the live points preview.
///
/// Paired with a colour change this is the app's "that was right" signal: a
/// small overshoot the eye catches without anything having to flash.
class PulseOnChange extends StatefulWidget {
  const PulseOnChange({
    required this.value,
    required this.child,
    this.scale = 1.06,
    super.key,
  });

  /// Changing this triggers the pulse.
  final Object? value;

  final Widget child;
  final double scale;

  @override
  State<PulseOnChange> createState() => _PulseOnChangeState();
}

class _PulseOnChangeState extends State<PulseOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.normal,
  );

  late final Animation<double> _pulse = TweenSequence<double>(<TweenSequenceItem<double>>[
    TweenSequenceItem<double>(
      tween: Tween<double>(
        begin: 1,
        end: widget.scale,
      ).chain(CurveTween(curve: AppMotion.enter)),
      weight: 35,
    ),
    TweenSequenceItem<double>(
      tween: Tween<double>(
        begin: widget.scale,
        end: 1,
      ).chain(CurveTween(curve: AppMotion.standard)),
      weight: 65,
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(PulseOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _pulse, child: widget.child);
  }
}
