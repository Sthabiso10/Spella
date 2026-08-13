import 'package:flutter/services.dart';

/// Tactile feedback for game moments.
///
/// Wrapped in a service so views never call platform channels directly, and so
/// it can be silenced in tests or behind a settings toggle.
class HapticService {
  HapticService({this.isEnabled = true});

  /// Turn off to mute all feedback, e.g. from a settings screen.
  bool isEnabled;

  /// Placing or returning a tile.
  void tileTap() => _run(HapticFeedback.selectionClick);

  /// A valid word was submitted.
  void success() => _run(HapticFeedback.mediumImpact);

  /// An invalid word was rejected.
  void error() => _run(HapticFeedback.heavyImpact);

  /// Round or match transitions.
  void notify() => _run(HapticFeedback.lightImpact);

  void _run(Future<void> Function() feedback) {
    if (!isEnabled) return;
    // Fire and forget - haptics must never block or crash the game loop.
    feedback().catchError((_) {});
  }
}
