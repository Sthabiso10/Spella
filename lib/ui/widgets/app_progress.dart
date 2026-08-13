import 'package:flutter/material.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/ui_helpers.dart';

/// A thin, animated progress track.
///
/// Deliberately hairline. Progress in this app is ambient information - how
/// much clock is left, how far through a level - and a chunky bar turns
/// ambient information into a demand for attention.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    required this.value,
    this.color,
    this.height = 3,
    this.trackColor,
    super.key,
  });

  /// 0..1. Values outside the range are clamped.
  final double value;

  final Color? color;
  final double height;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return ClipRRect(
      borderRadius: AppRadius.pill,
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ColoredBox(color: trackColor ?? palette.recess),
            // A fraction rather than a fixed width, so the bar is correct at
            // any screen size without anyone measuring the parent.
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value.clamp(0, 1),
                child: AnimatedContainer(
                  duration: AppMotion.normal,
                  curve: AppMotion.enter,
                  color: color ?? palette.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One mark per round, filled in as rounds are decided.
///
/// Reads as a scoreline at a glance in a way a "3/5" label never does: you can
/// see both how far in the match is and who has been taking it.
class SegmentedProgress extends StatelessWidget {
  const SegmentedProgress({
    required this.total,
    required this.colorFor,
    this.width = 14,
    this.height = 3,
    super.key,
  });

  final int total;

  /// Colour of segment [index], letting the caller encode who won each round.
  final Color Function(int index) colorFor;

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < total; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedContainer(
              duration: AppMotion.normal,
              curve: AppMotion.enter,
              width: width,
              height: height,
              decoration: BoxDecoration(color: colorFor(i), borderRadius: AppRadius.pill),
            ),
          ),
      ],
    );
  }
}

/// An indeterminate progress line, for waits with no known end.
class AppIndeterminateBar extends StatelessWidget {
  const AppIndeterminateBar({this.width = 120, this.color, super.key});

  final double width;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: AppRadius.pill,
        child: LinearProgressIndicator(
          minHeight: 3,
          backgroundColor: palette.recess,
          valueColor: AlwaysStoppedAnimation<Color>(color ?? palette.accent),
        ),
      ),
    );
  }
}
