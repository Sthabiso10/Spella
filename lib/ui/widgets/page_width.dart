import 'package:flutter/material.dart';

/// Holds a screen's content to a comfortable measure and centres it.
///
/// A phone layout stretched across a tablet is not a tablet layout: lines of
/// text run past the point the eye can track back, a full-width button becomes
/// a target the thumb cannot reach either end of, and the game board grows
/// tiles the size of coasters. Capping the measure keeps every screen at the
/// proportions it was designed at, and lets the extra width read as margin.
///
/// Wrapped around the scrolling view rather than inside it, so the scrollbar
/// and the overscroll glow still belong to the full window.
class PageWidth extends StatelessWidget {
  const PageWidth({required this.child, this.maxWidth = 560, super.key});

  final Widget child;

  /// Roughly the width of a large phone. Past this, prose starts to sprawl and
  /// a two-handed layout would be the honest answer - which this app does not
  /// have the content to justify.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    // `heightFactor: 1` is load bearing. Without it this is a Center, and a
    // Center takes the *largest* height its constraints allow - which is fine
    // inside a page body, but catastrophic anywhere the parent passes loose
    // full-screen constraints and expects the child to shrink-wrap. The tab
    // bar is exactly that: it would grow to fill the window and paint its
    // surface over the whole app. Taking the child's height keeps this widget
    // purely horizontal, which is all it was ever meant to be.
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
