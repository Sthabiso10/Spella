import 'package:spella/core/models/letter_tile.dart';
import 'package:spella/core/models/slot_bonus.dart';
import 'package:spella/core/models/word_play.dart';

/// A single round of a match: one shared rack, one play from each side.
///
/// Both players get the identical rack and bonus layout, so the round is a
/// pure test of who sees the better word.
class GameRound {
  const GameRound({
    required this.index,
    required this.rack,
    required this.bonuses,
    required this.bestPossibleWord,
    this.hostPlay,
    this.guestPlay,
  });

  /// Zero based position in the match.
  final int index;

  /// The tiles dealt this round.
  final List<LetterTile> rack;

  /// Bonus layout for the word slots, same length as [rack].
  final List<SlotBonus> bonuses;

  /// Highest scoring word the dictionary can make from this rack. Shown after
  /// the round so players learn something even when they lose.
  final String bestPossibleWord;

  final WordPlay? hostPlay;
  final WordPlay? guestPlay;

  /// Human friendly round number.
  int get number => index + 1;

  bool get isComplete => hostPlay != null && guestPlay != null;

  int get hostScore => hostPlay?.score ?? 0;

  int get guestScore => guestPlay?.score ?? 0;

  bool get isDraw => isComplete && hostScore == guestScore;

  /// `true` when the host took the round outright.
  bool get hostWon => isComplete && hostScore > guestScore;

  GameRound copyWith({WordPlay? hostPlay, WordPlay? guestPlay}) {
    return GameRound(
      index: index,
      rack: rack,
      bonuses: bonuses,
      bestPossibleWord: bestPossibleWord,
      hostPlay: hostPlay ?? this.hostPlay,
      guestPlay: guestPlay ?? this.guestPlay,
    );
  }
}
