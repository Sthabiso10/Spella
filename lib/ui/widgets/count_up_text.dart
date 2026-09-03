import 'package:flutter/material.dart';
import 'package:spella/ui/common/ui_helpers.dart';

/// A number that rolls to its new value instead of snapping to it.
///
/// A score jumping from 40 to 88 between frames is information the player can
/// miss. Counting it up costs a quarter of a second and turns a state change
/// into a moment - which, in a game about beating a friend, is the point.
class CountUpText extends StatefulWidget {
  const CountUpText({
    required this.value,
    required this.style,
    this.from,
    this.formatter,
    this.duration = AppMotion.entrance,
    super.key,
  });

  final int value;
  final TextStyle style;

  /// Where the very first roll starts from.
  ///
  /// `null` - the default - means the figure simply appears at [value] and only
  /// rolls on later changes, which is what a running total wants. Pass `0` for
  /// a number whose arrival is the event: a final score, a round result. That
  /// case needs saying explicitly, because a widget that is built once with its
  /// final value has no change to animate and would otherwise just pop into
  /// place.
  final int? from;

  /// How to render the running value. Defaults to grouped thousands.
  final String Function(int)? formatter;

  final Duration duration;

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late int _start = widget.from ?? widget.value;
  late int _end = widget.value;

  /// The figure on screen this frame.
  int get _running {
    final double t = Curves.easeOutCubic.transform(_controller.value);
    return (_start + (_end - _start) * t).round();
  }

  @override
  void initState() {
    super.initState();
    if (_start != _end) _controller.forward();
  }

  @override
  void didUpdateWidget(CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == _end) return;

    // Always roll on from whatever is currently showing, so a value that
    // changes again mid-roll continues rather than jumping back.
    _start = _running;
    _end = widget.value;
    _controller
      ..duration = widget.duration
      ..forward(from: 0);
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
      builder: (BuildContext context, Widget? child) =>
          Text((widget.formatter ?? formatPoints)(_running), style: widget.style),
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
