import 'package:flutter/widgets.dart';

/// The spacing scale.
///
/// Everything in the app is laid out on multiples of four. Named steps rather
/// than loose numbers is what keeps the vertical rhythm identical from screen
/// to screen, and it makes "this feels cramped" a one-token fix.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Gap between major sections of a screen.
  static const double section = 48;

  /// Bottom padding that clears the floating tab bar.
  static const double navClearance = 108;
}

/// Corner radii.
///
/// Restrained on purpose: a small control and a large panel are different
/// objects and should not share a radius, but nothing here is so round that it
/// reads as a bubble.
class AppRadius {
  const AppRadius._();

  /// Small controls - chips, badges, tile corners.
  static const Radius xs = Radius.circular(8);

  /// Buttons and inputs.
  static const Radius sm = Radius.circular(11);

  /// Cards and list rows.
  static const Radius md = Radius.circular(15);

  /// Large surfaces - sheets, hero panels.
  static const Radius lg = Radius.circular(20);

  static const BorderRadius control = BorderRadius.all(sm);
  static const BorderRadius card = BorderRadius.all(md);
  static const BorderRadius sheet = BorderRadius.vertical(top: lg);
  static const BorderRadius tile = BorderRadius.all(xs);

  /// Reserved for things that are semantically a token: status, rank, tag,
  /// game mode. Never for a button or a card.
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

/// Shared animation timings, so motion across the app feels like one system.
///
/// The rule of thumb: the smaller the thing that moved, the faster it moves.
/// Anything slower than [entrance] starts to feel like the app is thinking
/// rather than responding.
class AppMotion {
  const AppMotion._();

  /// Press states, hovers, colour changes.
  static const Duration instant = Duration(milliseconds: 120);

  /// Selection, small layout shifts, chip transitions.
  static const Duration quick = Duration(milliseconds: 180);

  /// The default. Content swaps, sheets, progress.
  static const Duration normal = Duration(milliseconds: 260);

  /// Screen-level entrances and celebratory beats.
  static const Duration entrance = Duration(milliseconds: 420);

  /// Decelerating - things arriving.
  static const Curve enter = Curves.easeOutCubic;

  /// Symmetric - things moving between two known states.
  static const Curve standard = Curves.easeInOutCubic;

  /// A single restrained overshoot. Used sparingly, for a value landing.
  static const Curve settle = Cubic(0.2, 1.1, 0.3, 1);
}

/// [base] grown in step with the reader's text size.
///
/// A horizontal strip has to declare a height before it knows what is in it, so
/// any strip holding text needs that height to follow the text. Growth is
/// capped: past about half again, the strip has stopped being a strip, and the
/// right answer is to let the content ellipsise rather than to keep growing.
double scaledSize(BuildContext context, double base, {double maxFactor = 1.6}) {
  final double scaled = MediaQuery.textScalerOf(context).scale(base);
  return scaled.clamp(base, base * maxFactor);
}

/// Vertical gap of [height] logical pixels.
Widget verticalSpace(double height) => SizedBox(height: height);

/// Horizontal gap of [width] logical pixels.
Widget horizontalSpace(double width) => SizedBox(width: width);

/// Formats [seconds] as `m:ss`.
String formatClock(int seconds) {
  final int safe = seconds < 0 ? 0 : seconds;
  final String secondsPart = (safe % 60).toString().padLeft(2, '0');
  return '${safe ~/ 60}:$secondsPart';
}

/// Compact "2m ago" style timestamp for feeds.
String formatRelativeTime(DateTime moment) {
  final Duration elapsed = DateTime.now().difference(moment);

  if (elapsed.inMinutes < 1) return 'just now';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
  if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
  return '${elapsed.inDays}d ago';
}

/// Formats large numbers as `12,450`.
String formatPoints(int points) {
  final String digits = points.abs().toString();
  final StringBuffer buffer = StringBuffer(points.isNegative ? '-' : '');

  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
