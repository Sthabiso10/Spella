import 'package:spella/core/data/letter_data.dart';
import 'package:spella/core/models/letter_tile.dart';
import 'package:spella/core/models/score_breakdown.dart';
import 'package:spella/core/models/slot_bonus.dart';

/// Turns a placed word into points.
///
/// Pure functions only - no state, no dependencies. Every rule the players
/// need to reason about is expressed here in one place.
class ScoringService {
  /// Points awarded per letter past [_freeLength].
  static const int lengthBonusPerLetter = 5;

  /// Bonus for using every tile in the rack.
  static const int fullRackBonus = 25;

  /// Maximum points the clock can contribute, so a 60 second mode does not
  /// out-earn a 25 second one just by being longer.
  static const int maxSpeedBonus = 20;

  static const int _freeLength = 4;

  /// Scores the word exactly as the player arranged it, honouring which tile
  /// landed on which bonus slot.
  ScoreBreakdown scoreArrangement({
    required List<LetterTile> tiles,
    required List<SlotBonus> bonuses,
    required int rackSize,
    int secondsRemaining = 0,
    int secondsTotal = 0,
  }) {
    if (tiles.isEmpty) return ScoreBreakdown.empty;

    int letterPoints = 0;
    int wordMultiplier = 1;

    for (int i = 0; i < tiles.length; i++) {
      final SlotBonus bonus = i < bonuses.length ? bonuses[i] : SlotBonus.none;
      letterPoints += tiles[i].value * bonus.letterMultiplier;
      wordMultiplier *= bonus.wordMultiplier;
    }

    return _assemble(
      letterPoints: letterPoints,
      wordMultiplier: wordMultiplier,
      wordLength: tiles.length,
      rackSize: rackSize,
      secondsRemaining: secondsRemaining,
      secondsTotal: secondsTotal,
    );
  }

  /// The best score [word] could possibly earn on this bonus layout.
  ///
  /// Because the word multiplier applies no matter how the tiles are ordered,
  /// the optimum is simply the highest value letters on the biggest letter
  /// multipliers - so pairing the two sorted lists is provably optimal.
  ScoreBreakdown bestScoreFor({
    required String word,
    required List<SlotBonus> bonuses,
    required int rackSize,
    int secondsRemaining = 0,
    int secondsTotal = 0,
  }) {
    if (word.isEmpty) return ScoreBreakdown.empty;

    final List<int> letterValues =
        word.split('').map(LetterData.valueOf).toList(growable: false)
          ..sort((int a, int b) => b.compareTo(a));

    final List<SlotBonus> covered = bonuses.take(word.length).toList(growable: false);
    final List<int> letterMultipliers =
        covered.map((SlotBonus bonus) => bonus.letterMultiplier).toList(growable: false)
          ..sort((int a, int b) => b.compareTo(a));

    int letterPoints = 0;
    for (int i = 0; i < letterValues.length; i++) {
      final int multiplier = i < letterMultipliers.length ? letterMultipliers[i] : 1;
      letterPoints += letterValues[i] * multiplier;
    }

    final int wordMultiplier = covered.fold(
      1,
      (int product, SlotBonus bonus) => product * bonus.wordMultiplier,
    );

    return _assemble(
      letterPoints: letterPoints,
      wordMultiplier: wordMultiplier,
      wordLength: word.length,
      rackSize: rackSize,
      secondsRemaining: secondsRemaining,
      secondsTotal: secondsTotal,
    );
  }

  ScoreBreakdown _assemble({
    required int letterPoints,
    required int wordMultiplier,
    required int wordLength,
    required int rackSize,
    required int secondsRemaining,
    required int secondsTotal,
  }) {
    return ScoreBreakdown(
      letterPoints: letterPoints,
      wordMultiplier: wordMultiplier,
      lengthBonus: wordLength > _freeLength
          ? (wordLength - _freeLength) * lengthBonusPerLetter
          : 0,
      fullRackBonus: wordLength >= rackSize ? ScoringService.fullRackBonus : 0,
      speedBonus: _speedBonus(secondsRemaining, secondsTotal),
    );
  }

  int _speedBonus(int secondsRemaining, int secondsTotal) {
    if (secondsTotal <= 0 || secondsRemaining <= 0) return 0;
    final double ratio = (secondsRemaining / secondsTotal).clamp(0.0, 1.0);
    return (ratio * maxSpeedBonus).round();
  }
}
