import 'dart:math';

import 'package:spella/core/models/game_match.dart';
import 'package:spella/core/models/game_mode.dart';
import 'package:spella/core/models/game_round.dart';
import 'package:spella/core/models/letter_tile.dart';
import 'package:spella/core/models/match_result.dart';
import 'package:spella/core/models/play_validation.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/core/models/round_board.dart';
import 'package:spella/core/models/score_breakdown.dart';
import 'package:spella/core/models/word_play.dart';
import 'package:spella/core/services/dictionary_service.dart';
import 'package:spella/core/services/rack_generator_service.dart';
import 'package:spella/core/services/scoring_service.dart';
import 'package:uuid/uuid.dart';

/// The rules of Spella.
///
/// Creates matches, deals rounds, validates and scores plays and works out
/// what a finished match pays out. Holds no state of its own - callers pass a
/// match in and get an updated one back - which keeps it trivially testable
/// and safe to reuse across screens.
class GameEngineService {
  GameEngineService(
    this._dictionary,
    this._rackGenerator,
    this._scoring, {
    Random? random,
    Uuid? uuid,
  }) : _random = random ?? Random(),
       _uuid = uuid ?? const Uuid();

  final DictionaryService _dictionary;
  final RackGeneratorService _rackGenerator;
  final ScoringService _scoring;
  final Random _random;
  final Uuid _uuid;

  /// Shortest word the game will accept.
  static const int minimumWordLength = 3;

  /// Starts a match with its first round already dealt.
  GameMatch createMatch({
    required GameMode mode,
    required Player host,
    required Player guest,
  }) {
    return GameMatch(
      id: _uuid.v4(),
      mode: mode,
      host: host,
      guest: guest,
      rounds: <GameRound>[_dealRound(mode, 0)],
    );
  }

  /// Advances to the next round, dealing a fresh rack.
  ///
  /// Returns the match unchanged once every round has been played.
  GameMatch advanceRound(GameMatch match) {
    if (match.isComplete) return match;

    final int nextIndex = match.currentRoundIndex + 1;
    final List<GameRound> rounds = List<GameRound>.of(match.rounds);
    if (nextIndex >= rounds.length) {
      rounds.add(_dealRound(match.mode, nextIndex));
    }

    return match.copyWith(rounds: rounds, currentRoundIndex: nextIndex);
  }

  /// Builds a fresh board for the round currently in play.
  RoundBoard boardFor(GameMatch match) {
    final GameRound round = match.currentRound!;
    return RoundBoard(rack: round.rack, bonuses: round.bonuses);
  }

  /// A fresh board for any dealt [round].
  ///
  /// A pass-and-play game hands the same round to each player in turn, and each
  /// of them needs their own board to build on - so the board cannot be derived
  /// from a match the way a duel's is.
  RoundBoard boardForRound(GameRound round) =>
      RoundBoard(rack: round.rack, bonuses: round.bonuses);

  /// Deals a standalone round for [mode].
  ///
  /// [createMatch] and [advanceRound] deal rounds into a duel. Local party
  /// games own their own round list, so they deal through here instead - same
  /// rack generator, same best-word search, no duel attached.
  GameRound dealRound({required GameMode mode, required int index}) =>
      _dealRound(mode, index);

  /// Checks what is on [board] and prices it up.
  ///
  /// [secondsRemaining] feeds the speed bonus, so the preview the player sees
  /// while the clock runs is the score they will actually bank.
  PlayValidation validate({
    required RoundBoard board,
    required GameMode mode,
    required int secondsRemaining,
  }) {
    final String word = board.word;

    if (word.isEmpty) {
      return const PlayValidation.invalid(word: '', reason: PlayRejection.empty);
    }
    if (word.length < minimumWordLength) {
      return PlayValidation.invalid(word: word, reason: PlayRejection.tooShort);
    }
    if (!_dictionary.canPlay(word, board.rack.map((LetterTile tile) => tile.letter))) {
      return PlayValidation.invalid(
        word: word,
        reason: _dictionary.isValidWord(word)
            ? PlayRejection.notInRack
            : PlayRejection.notAWord,
      );
    }

    return PlayValidation.valid(
      word: word,
      breakdown: _scoring.scoreArrangement(
        tiles: board.placed,
        bonuses: board.bonuses,
        rackSize: mode.rackSize,
        secondsRemaining: secondsRemaining,
        secondsTotal: mode.secondsPerRound,
      ),
    );
  }

  /// Records the host's play for the current round.
  GameMatch submitHostPlay(GameMatch match, WordPlay play) =>
      _recordPlay(match, hostPlay: play);

  /// Records the opponent's play for the current round.
  GameMatch submitGuestPlay(GameMatch match, WordPlay play) =>
      _recordPlay(match, guestPlay: play);

  /// The strongest word available on [round], used by the hint power-up and
  /// shown in the round recap.
  String bestWordFor(GameRound round) => round.bestPossibleWord;

  /// A good-but-not-perfect suggestion, so a hint helps without simply playing
  /// the round for you.
  String? hintFor(GameRound round) {
    final List<String> solutions = _solutions(round);
    if (solutions.isEmpty) return null;

    final int ceiling = max(1, (solutions.length * 0.35).round());
    return solutions[_random.nextInt(ceiling)];
  }

  /// Works out XP, currency and MVP status for a finished match.
  MatchResult buildResult(GameMatch match) {
    final MatchOutcome outcome = match.outcome;
    final WordPlay? hostBest = match.hostBestPlay;
    final WordPlay? guestBest = match.guestBestPlay;

    final bool isMvp =
        outcome == MatchOutcome.won &&
        hostBest != null &&
        hostBest.score >= (guestBest?.score ?? 0);

    final int baseXp = switch (outcome) {
      MatchOutcome.won => 45,
      MatchOutcome.draw => 25,
      MatchOutcome.lost => 15,
    };
    final int baseCoins = switch (outcome) {
      MatchOutcome.won => 120,
      MatchOutcome.draw => 70,
      MatchOutcome.lost => 40,
    };

    final int xpEarned = baseXp + (match.hostScore ~/ 25) + (isMvp ? 10 : 0);
    final int coinsEarned = baseCoins + (match.hostScore ~/ 10) * 2;
    final int gemsEarned = switch (outcome) {
      MatchOutcome.won => isMvp ? 15 : 10,
      MatchOutcome.draw => 5,
      MatchOutcome.lost => 0,
    };

    return MatchResult(
      match: match,
      xpEarned: xpEarned,
      coinsEarned: coinsEarned,
      gemsEarned: gemsEarned,
      isMvp: isMvp,
      levelledUp: match.host.xp + xpEarned >= match.host.xpForNextLevel,
    );
  }

  GameRound _dealRound(GameMode mode, int index) {
    final RackDraw draw = _rackGenerator.deal(mode);
    return GameRound(
      index: index,
      rack: draw.tiles,
      bonuses: draw.bonuses,
      bestPossibleWord: _findBestWord(draw, mode),
    );
  }

  /// Highest *scoring* word on the rack, which is not always the longest.
  String _findBestWord(RackDraw draw, GameMode mode) {
    final List<String> solutions = _dictionary.solutionsFor(
      draw.letters,
      minLength: minimumWordLength,
    );
    if (solutions.isEmpty) return '';

    String best = solutions.first;
    int bestScore = -1;

    for (final String word in solutions) {
      final ScoreBreakdown breakdown = _scoring.bestScoreFor(
        word: word,
        bonuses: draw.bonuses,
        rackSize: mode.rackSize,
      );
      if (breakdown.total > bestScore) {
        bestScore = breakdown.total;
        best = word;
      }
    }
    return best;
  }

  List<String> _solutions(GameRound round) => _dictionary.solutionsFor(
    round.rack.map((LetterTile tile) => tile.letter),
    minLength: minimumWordLength,
  );

  GameMatch _recordPlay(GameMatch match, {WordPlay? hostPlay, WordPlay? guestPlay}) {
    final GameRound? round = match.currentRound;
    if (round == null) return match;

    final List<GameRound> rounds = List<GameRound>.of(match.rounds);
    rounds[match.currentRoundIndex] = round.copyWith(
      hostPlay: hostPlay,
      guestPlay: guestPlay,
    );
    return match.copyWith(rounds: rounds);
  }
}
