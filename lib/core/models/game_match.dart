import 'package:spella/core/models/game_mode.dart';
import 'package:spella/core/models/game_round.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/core/models/word_play.dart';

/// How a finished match turned out, from the local player's point of view.
enum MatchOutcome { won, lost, draw }

/// A full duel between two players.
///
/// The local player is always the [host]; the [guest] is whoever they are up
/// against. Rounds are appended as they are dealt, so [rounds] doubles as the
/// match history.
class GameMatch {
  const GameMatch({
    required this.id,
    required this.mode,
    required this.host,
    required this.guest,
    required this.rounds,
    this.currentRoundIndex = 0,
  });

  final String id;
  final GameMode mode;

  /// The local player.
  final Player host;

  /// The opponent.
  final Player guest;

  final List<GameRound> rounds;

  /// Index into [rounds] of the round being played.
  final int currentRoundIndex;

  /// The round in progress, or `null` once the match is over.
  GameRound? get currentRound =>
      currentRoundIndex < rounds.length ? rounds[currentRoundIndex] : null;

  /// Rounds that have both plays recorded.
  List<GameRound> get completedRounds =>
      rounds.where((GameRound round) => round.isComplete).toList(growable: false);

  int get hostScore =>
      completedRounds.fold(0, (int sum, GameRound round) => sum + round.hostScore);

  int get guestScore =>
      completedRounds.fold(0, (int sum, GameRound round) => sum + round.guestScore);

  /// Rounds still to be played, including the current one.
  int get roundsRemaining => mode.totalRounds - completedRounds.length;

  bool get isComplete => completedRounds.length >= mode.totalRounds;

  MatchOutcome get outcome {
    if (hostScore > guestScore) return MatchOutcome.won;
    if (hostScore < guestScore) return MatchOutcome.lost;
    return MatchOutcome.draw;
  }

  /// The host's highest scoring word of the match, if they played one.
  WordPlay? get hostBestPlay =>
      _bestPlay(rounds.map((GameRound round) => round.hostPlay));

  /// The guest's highest scoring word of the match, if they played one.
  WordPlay? get guestBestPlay =>
      _bestPlay(rounds.map((GameRound round) => round.guestPlay));

  static WordPlay? _bestPlay(Iterable<WordPlay?> plays) {
    WordPlay? best;
    for (final WordPlay? play in plays) {
      if (play == null || play.isPass) continue;
      if (best == null || play.score > best.score) best = play;
    }
    return best;
  }

  GameMatch copyWith({List<GameRound>? rounds, int? currentRoundIndex}) {
    return GameMatch(
      id: id,
      mode: mode,
      host: host,
      guest: guest,
      rounds: rounds ?? this.rounds,
      currentRoundIndex: currentRoundIndex ?? this.currentRoundIndex,
    );
  }
}
