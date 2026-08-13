/// Itemised result of scoring a word, kept separate from the total so the UI
/// can show players exactly where their points came from.
class ScoreBreakdown {
  const ScoreBreakdown({
    this.letterPoints = 0,
    this.wordMultiplier = 1,
    this.lengthBonus = 0,
    this.fullRackBonus = 0,
    this.speedBonus = 0,
  });

  /// An empty breakdown, used before a word is built or when it is invalid.
  static const ScoreBreakdown empty = ScoreBreakdown();

  /// Sum of tile values after per-slot letter multipliers.
  final int letterPoints;

  /// Product of every word multiplier the word covered.
  final int wordMultiplier;

  /// Reward for going long: applies past four letters.
  final int lengthBonus;

  /// Awarded for using every tile in the rack.
  final int fullRackBonus;

  /// Points for the time left on the clock.
  final int speedBonus;

  /// Letter points after the word multiplier, before flat bonuses.
  int get multipliedPoints => letterPoints * wordMultiplier;

  /// Final score for the play.
  int get total => multipliedPoints + lengthBonus + fullRackBonus + speedBonus;

  bool get isEmpty => total == 0;

  @override
  String toString() => 'ScoreBreakdown(total: $total)';
}
