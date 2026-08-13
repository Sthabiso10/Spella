import 'package:spella/core/models/score_breakdown.dart';

/// One player's submission for a round.
class WordPlay {
  const WordPlay({
    required this.playerId,
    required this.word,
    required this.breakdown,
    required this.secondsTaken,
  });

  /// A round the player let time out on, or skipped.
  factory WordPlay.passed({required String playerId, required int secondsTaken}) =>
      WordPlay(
        playerId: playerId,
        word: '',
        breakdown: ScoreBreakdown.empty,
        secondsTaken: secondsTaken,
      );

  final String playerId;

  /// Lowercase; empty when the player passed or ran out of time.
  final String word;

  final ScoreBreakdown breakdown;
  final int secondsTaken;

  int get score => breakdown.total;

  bool get isPass => word.isEmpty;

  String get display => word.toUpperCase();
}
