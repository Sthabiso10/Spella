import 'package:spella/core/models/score_breakdown.dart';

/// Why a word cannot be played, or that it can.
enum PlayRejection {
  /// Nothing placed yet.
  empty,

  /// Fewer letters than the minimum word length.
  tooShort,

  /// Spelled from tiles that are not in the rack. Defensive - the board should
  /// make this impossible.
  notInRack,

  /// Not in the dictionary.
  notAWord,
}

/// The result of checking the word currently on the board.
///
/// Carries the live score so the UI can preview what a play is worth before
/// the player commits to it.
class PlayValidation {
  const PlayValidation._({required this.word, required this.breakdown, this.rejection});

  const PlayValidation.valid({required String word, required ScoreBreakdown breakdown})
    : this._(word: word, breakdown: breakdown);

  const PlayValidation.invalid({required String word, required PlayRejection reason})
    : this._(word: word, breakdown: ScoreBreakdown.empty, rejection: reason);

  final String word;
  final ScoreBreakdown breakdown;
  final PlayRejection? rejection;

  bool get isValid => rejection == null;

  int get score => breakdown.total;

  /// Short message shown under the word slots.
  String get message => switch (rejection) {
    null => 'Nice one',
    PlayRejection.empty => 'Tap tiles to build a word',
    PlayRejection.tooShort => 'Words need at least 3 letters',
    PlayRejection.notInRack => 'Those tiles are not in your rack',
    PlayRejection.notAWord => 'Not in the dictionary',
  };
}
