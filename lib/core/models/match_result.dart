import 'package:spella/core/models/game_match.dart';

/// The rewards a finished match paid out, alongside the match itself.
///
/// Produced by the game engine so the results screen never has to work out
/// what a win is worth.
class MatchResult {
  const MatchResult({
    required this.match,
    required this.xpEarned,
    required this.coinsEarned,
    required this.gemsEarned,
    required this.isMvp,
    required this.levelledUp,
  });

  final GameMatch match;
  final int xpEarned;
  final int coinsEarned;
  final int gemsEarned;

  /// Awarded when the host both won and played the best word of the match.
  final bool isMvp;

  /// `true` when the earned XP pushed the player over a level boundary.
  final bool levelledUp;

  MatchOutcome get outcome => match.outcome;

  bool get didWin => outcome == MatchOutcome.won;

  String get headline => switch (outcome) {
    MatchOutcome.won => 'You Won the Match',
    MatchOutcome.lost => 'You Lost This One',
    MatchOutcome.draw => 'It Ended in a Draw',
  };
}
