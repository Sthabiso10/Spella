import 'dart:async';

/// The countdown a player builds their word against.
///
/// Pulled out of the view models because both of them ran the same timer, and
/// because a clock that can be paused, extended and interrupted has more edge
/// cases than a game screen should be carrying inline.
///
/// The important invariant is that [remaining] never exceeds [allotted]:
/// [extend] grows the budget as well as the balance, so a frozen round reads as
/// a longer round rather than as a round that has somehow gone past full. That
/// keeps [progress] inside 0..1 and [elapsed] non-negative no matter what the
/// player buys.
class RoundClock {
  RoundClock({required this.onTick, required this.onExpired});

  /// Fired once a second while running, after [remaining] has been decremented.
  final void Function() onTick;

  /// Fired once when the clock reaches zero. The clock stops itself first.
  final void Function() onExpired;

  Timer? _timer;
  int _allotted = 0;
  int _remaining = 0;
  bool _isPaused = false;

  /// The round's full budget, including any seconds bought with a power-up.
  int get allotted => _allotted;

  /// Seconds left to play.
  int get remaining => _remaining;

  /// Seconds spent so far. Never negative, even after an [extend].
  int get elapsed => _allotted - _remaining;

  /// `true` when the clock has been stopped by [pause] and can be resumed.
  bool get isPaused => _isPaused;

  /// `true` while seconds are actually being counted down.
  bool get isRunning => _timer != null;

  /// Fraction of the round left, always within 0..1.
  double get progress =>
      _allotted <= 0 ? 0 : (_remaining / _allotted).clamp(0.0, 1.0);

  /// Puts a fresh [seconds] on the clock without starting it.
  void reset(int seconds) {
    stop();
    _allotted = seconds;
    _remaining = seconds;
    _isPaused = false;
  }

  /// Starts counting down. Safe to call when already running.
  void start() {
    stop();
    _isPaused = false;
    if (_remaining <= 0) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      _remaining--;
      if (_remaining <= 0) {
        _remaining = 0;
        stop();
        onExpired();
        return;
      }
      onTick();
    });
  }

  /// Holds the clock where it is. [resume] picks it back up.
  ///
  /// Used for anything that takes the game out of the player's hands - a
  /// confirmation dialog, the app being backgrounded, someone at the table
  /// asking for a minute.
  void pause() {
    if (!isRunning) return;
    stop();
    _isPaused = true;
  }

  /// Restarts a [pause]d clock. Does nothing if it was not paused.
  void resume() {
    if (!_isPaused) return;
    start();
  }

  /// Adds [seconds] to both the balance and the budget, so the round simply
  /// becomes a longer round.
  void extend(int seconds) {
    if (seconds <= 0) return;
    _allotted += seconds;
    _remaining += seconds;
  }

  /// Stops counting without marking the clock paused.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Releases the timer. The clock cannot be restarted afterwards.
  void dispose() {
    stop();
    _isPaused = false;
  }
}
