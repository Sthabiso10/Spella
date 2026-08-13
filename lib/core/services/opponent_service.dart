import 'dart:math';

import 'package:spella/core/models/game_mode.dart';
import 'package:spella/core/models/game_round.dart';
import 'package:spella/core/models/letter_tile.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/core/models/score_breakdown.dart';
import 'package:spella/core/models/word_play.dart';
import 'package:spella/core/services/dictionary_service.dart';
import 'package:spella/core/services/scoring_service.dart';

/// Supplies the opposing player's move for a round.
///
/// Implemented today by [BotOpponentService]. When real-time multiplayer
/// arrives it becomes a thin wrapper over the live match channel, and nothing
/// above this interface changes.
abstract class OpponentService {
  /// Produces the opponent's play for [round].
  Future<WordPlay> playRound({
    required GameRound round,
    required GameMode mode,
    required Player opponent,
  });
}

/// The built-in opponent.
///
/// Every match in the app is already resolved by [BotOpponentService]; until
/// real opponents arrive this simply gives it a name and a face of its own
/// rather than borrowing a stranger's from a seeded friends list.
///
/// Its level tracks [player]'s, so the bot stays a fair test as they improve
/// instead of becoming either a wall or a pushover.
Player botOpponentFor(Player player) => Player(
  id: 'spella-bot',
  username: 'Spella Bot',
  avatar: '🤖',
  level: player.level.clamp(1, 60),
  isOnline: true,
  isBot: true,
);

/// A local opponent that plays from the same dictionary the player does.
///
/// Strength scales with the opponent's level: a low level bot picks from the
/// weaker end of the solution list and often takes its time, a high level one
/// homes in on the best available word.
class BotOpponentService implements OpponentService {
  BotOpponentService(this._dictionary, this._scoring, {Random? random})
    : _random = random ?? Random();

  final DictionaryService _dictionary;
  final ScoringService _scoring;
  final Random _random;

  /// Level at which the bot plays close to optimally.
  static const int _masteryLevel = 40;

  @override
  Future<WordPlay> playRound({
    required GameRound round,
    required GameMode mode,
    required Player opponent,
  }) async {
    final List<_ScoredWord> ranked = _rankSolutions(round, mode);
    if (ranked.isEmpty) {
      return WordPlay.passed(playerId: opponent.id, secondsTaken: mode.secondsPerRound);
    }

    final double skill = (opponent.level / _masteryLevel).clamp(0.15, 0.95);
    final _ScoredWord choice = ranked[_pickIndex(ranked.length, skill)];
    final int secondsTaken = _thinkingTime(mode, skill);

    // Re-score with the clock the bot "used" so its speed bonus is earned the
    // same way the player's is.
    final ScoreBreakdown breakdown = _scoring.bestScoreFor(
      word: choice.word,
      bonuses: round.bonuses,
      rackSize: mode.rackSize,
      secondsRemaining: mode.secondsPerRound - secondsTaken,
      secondsTotal: mode.secondsPerRound,
    );

    return WordPlay(
      playerId: opponent.id,
      word: choice.word,
      breakdown: breakdown,
      secondsTaken: secondsTaken,
    );
  }

  List<_ScoredWord> _rankSolutions(GameRound round, GameMode mode) {
    final List<String> solutions = _dictionary.solutionsFor(
      round.rack.map((LetterTile tile) => tile.letter),
      minLength: 3,
    );

    final List<_ScoredWord> ranked = <_ScoredWord>[
      for (final String word in solutions)
        _ScoredWord(
          word,
          _scoring
              .bestScoreFor(word: word, bonuses: round.bonuses, rackSize: mode.rackSize)
              .total,
        ),
    ]..sort((_ScoredWord a, _ScoredWord b) => b.score.compareTo(a.score));

    return ranked;
  }

  /// Maps skill onto a slice of the ranked solution list, then picks randomly
  /// inside it so the same rack does not always produce the same word.
  int _pickIndex(int solutionCount, double skill) {
    final int window = max(1, ((1 - skill) * solutionCount * 0.6).round());
    final int offset = ((1 - skill) * solutionCount * 0.1).round();
    return min(solutionCount - 1, offset + _random.nextInt(window));
  }

  int _thinkingTime(GameMode mode, double skill) {
    final int fastest = (mode.secondsPerRound * 0.25).round();
    final int slowest = (mode.secondsPerRound * 0.9).round();
    final int spread = max(1, slowest - fastest);
    // Stronger bots answer sooner, with a little jitter either way.
    final int base = fastest + ((1 - skill) * spread).round();
    return (base + _random.nextInt(5) - 2).clamp(1, mode.secondsPerRound);
  }
}

class _ScoredWord {
  const _ScoredWord(this.word, this.score);

  final String word;
  final int score;
}
