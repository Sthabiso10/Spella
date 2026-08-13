import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:spella/core/models/game_match.dart';
import 'package:spella/core/models/game_mode.dart';
import 'package:spella/core/models/letter_tile.dart';
import 'package:spella/core/models/match_result.dart';
import 'package:spella/core/models/play_validation.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/core/models/round_board.dart';
import 'package:spella/core/models/score_breakdown.dart';
import 'package:spella/core/models/slot_bonus.dart';
import 'package:spella/core/models/word_play.dart';
import 'package:spella/core/services/dictionary_service.dart';
import 'package:spella/core/services/game_engine_service.dart';
import 'package:spella/core/services/opponent_service.dart';
import 'package:spella/core/services/rack_generator_service.dart';
import 'package:spella/core/services/scoring_service.dart';

const Player _host = Player(id: 'host', username: 'Host', avatar: '🦸', level: 20);
const Player _guest = Player(
  id: 'guest',
  username: 'Guest',
  avatar: '🥷',
  level: 20,
  isBot: true,
);

/// A play worth exactly [score] points, for testing the flow rather than the
/// scoring rules.
WordPlay _playOf(String playerId, int score) => WordPlay(
  playerId: playerId,
  word: 'cat',
  breakdown: ScoreBreakdown(letterPoints: score),
  secondsTaken: 5,
);

void main() {
  late DictionaryService dictionary;
  late ScoringService scoring;
  late GameEngineService engine;

  setUpAll(() async {
    dictionary = DictionaryService();
    await dictionary.initialise();
    scoring = ScoringService();
  });

  setUp(() {
    // Fixed seeds keep deals reproducible across runs.
    engine = GameEngineService(
      dictionary,
      RackGeneratorService(dictionary, random: Random(7)),
      scoring,
      random: Random(7),
    );
  });

  GameMatch newMatch([GameMode mode = GameMode.classic]) =>
      engine.createMatch(mode: mode, host: _host, guest: _guest);

  /// A finished single round match with the given scores.
  GameMatch finished({required int hostScore, required int guestScore}) {
    GameMatch match = newMatch(GameMode.daily);
    match = engine.submitHostPlay(match, _playOf(_host.id, hostScore));
    match = engine.submitGuestPlay(match, _playOf(_guest.id, guestScore));
    return match;
  }

  group('dealing', () {
    test('starts a match with one round ready to play', () {
      final GameMatch match = newMatch();

      expect(match.rounds, hasLength(1));
      expect(match.currentRoundIndex, 0);
      expect(match.isComplete, isFalse);
    });

    for (final GameMode mode in GameMode.values) {
      test('${mode.label} deals ${mode.rackSize} tiles and matching slots', () {
        final GameMatch match = newMatch(mode);

        expect(match.currentRound!.rack, hasLength(mode.rackSize));
        expect(match.currentRound!.bonuses, hasLength(mode.rackSize));
      });
    }

    test('every deal is solvable', () {
      for (final GameMode mode in GameMode.values) {
        for (int i = 0; i < 25; i++) {
          final GameMatch match = newMatch(mode);
          expect(
            match.currentRound!.bestPossibleWord,
            isNotEmpty,
            reason: '${mode.label} deal $i had no playable word',
          );
        }
      }
    });

    test('never lays out more bonuses than the mode allows', () {
      for (int i = 0; i < 20; i++) {
        final GameMatch match = newMatch(GameMode.marathon);
        final int bonusCount = match.currentRound!.bonuses
            .where((SlotBonus bonus) => !bonus.isNone)
            .length;

        expect(bonusCount, lessThanOrEqualTo(GameMode.marathon.bonusSlots));
      }
    });
  });

  group('validation', () {
    test('rejects an empty board', () {
      final GameMatch match = newMatch();

      final PlayValidation result = engine.validate(
        board: engine.boardFor(match),
        mode: match.mode,
        secondsRemaining: 30,
      );

      expect(result.isValid, isFalse);
      expect(result.rejection, PlayRejection.empty);
    });

    test('rejects a word under the minimum length', () {
      final GameMatch match = newMatch();
      final RoundBoard board = engine.boardFor(match);
      board.place(board.rack.first);

      final PlayValidation result = engine.validate(
        board: board,
        mode: match.mode,
        secondsRemaining: 30,
      );

      expect(result.rejection, PlayRejection.tooShort);
    });

    test('rejects a letter sequence that is not a word', () {
      final GameMatch match = newMatch();
      final RoundBoard board = RoundBoard(
        rack: <LetterTile>[
          for (int i = 0; i < 'xqz'.length; i++) LetterTile.of('xqz'[i], index: i),
        ],
        bonuses: match.currentRound!.bonuses.take(3).toList(),
      )..spell('xqz');

      final PlayValidation result = engine.validate(
        board: board,
        mode: match.mode,
        secondsRemaining: 10,
      );

      expect(result.rejection, PlayRejection.notAWord);
    });

    test('accepts and prices the best available word', () {
      final GameMatch match = newMatch();
      final RoundBoard board = engine.boardFor(match)
        ..spell(match.currentRound!.bestPossibleWord);

      final PlayValidation result = engine.validate(
        board: board,
        mode: match.mode,
        secondsRemaining: 30,
      );

      expect(result.isValid, isTrue);
      expect(result.score, greaterThan(0));
    });

    test('a fuller clock is worth more than a nearly empty one', () {
      final GameMatch match = newMatch();
      final RoundBoard board = engine.boardFor(match)
        ..spell(match.currentRound!.bestPossibleWord);

      final int early = engine
          .validate(board: board, mode: match.mode, secondsRemaining: 40)
          .score;
      final int late = engine
          .validate(board: board, mode: match.mode, secondsRemaining: 2)
          .score;

      expect(early, greaterThan(late));
    });

    test('a hint always spells something playable', () {
      for (int i = 0; i < 15; i++) {
        final GameMatch match = newMatch();
        final String? hint = engine.hintFor(match.currentRound!);

        expect(hint, isNotNull);
        final RoundBoard board = engine.boardFor(match);
        expect(board.spell(hint!), isTrue);
        expect(
          engine.validate(board: board, mode: match.mode, secondsRemaining: 10).isValid,
          isTrue,
        );
      }
    });
  });

  group('match flow', () {
    test('a round is only complete once both players have answered', () {
      GameMatch match = newMatch();

      match = engine.submitHostPlay(match, _playOf(_host.id, 40));
      expect(match.currentRound!.isComplete, isFalse);

      match = engine.submitGuestPlay(match, _playOf(_guest.id, 20));
      expect(match.currentRound!.isComplete, isTrue);
      expect(match.hostScore, 40);
      expect(match.guestScore, 20);
    });

    test('advancing deals a fresh round', () {
      GameMatch match = newMatch();
      match = engine.submitHostPlay(match, _playOf(_host.id, 10));
      match = engine.submitGuestPlay(match, _playOf(_guest.id, 10));

      match = engine.advanceRound(match);

      expect(match.rounds, hasLength(2));
      expect(match.currentRoundIndex, 1);
    });

    test('completes after the round count and will not advance further', () {
      GameMatch match = newMatch(GameMode.blitz);

      for (int round = 0; round < GameMode.blitz.totalRounds; round++) {
        match = engine.submitHostPlay(match, _playOf(_host.id, 30));
        match = engine.submitGuestPlay(match, _playOf(_guest.id, 10));
        if (round < GameMode.blitz.totalRounds - 1) {
          match = engine.advanceRound(match);
        }
      }

      expect(match.isComplete, isTrue);
      expect(match.outcome, MatchOutcome.won);
      expect(engine.advanceRound(match).currentRoundIndex, match.currentRoundIndex);
    });

    test('equal scores end in a draw', () {
      expect(finished(hostScore: 25, guestScore: 25).outcome, MatchOutcome.draw);
    });

    test('passes score nothing and never count as a best word', () {
      GameMatch match = newMatch(GameMode.daily);
      match = engine.submitHostPlay(
        match,
        WordPlay.passed(playerId: _host.id, secondsTaken: 90),
      );
      match = engine.submitGuestPlay(match, _playOf(_guest.id, 15));

      expect(match.hostScore, 0);
      expect(match.hostBestPlay, isNull);
      expect(match.outcome, MatchOutcome.lost);
    });
  });

  group('rewards', () {
    test('a win pays more than a loss', () {
      final MatchResult win = engine.buildResult(finished(hostScore: 90, guestScore: 10));
      final MatchResult loss = engine.buildResult(
        finished(hostScore: 10, guestScore: 90),
      );

      expect(win.coinsEarned, greaterThan(loss.coinsEarned));
      expect(win.xpEarned, greaterThan(loss.xpEarned));
      expect(win.gemsEarned, greaterThan(loss.gemsEarned));
    });

    test('MVP requires winning with the best word of the match', () {
      expect(engine.buildResult(finished(hostScore: 90, guestScore: 10)).isMvp, isTrue);
      expect(engine.buildResult(finished(hostScore: 10, guestScore: 90)).isMvp, isFalse);
    });
  });

  group('bot opponent', () {
    test('plays a word that is valid for the rack it was given', () async {
      final BotOpponentService bot = BotOpponentService(
        dictionary,
        scoring,
        random: Random(3),
      );
      final GameMatch match = newMatch();

      final WordPlay play = await bot.playRound(
        round: match.currentRound!,
        mode: match.mode,
        opponent: _guest,
      );

      expect(play.isPass, isFalse);
      expect(
        dictionary.canPlay(
          play.word,
          match.currentRound!.rack.map((LetterTile tile) => tile.letter),
        ),
        isTrue,
      );
      expect(play.secondsTaken, inInclusiveRange(1, match.mode.secondsPerRound));
    });

    test('a high level bot outscores a low level one on the same rack', () async {
      final BotOpponentService bot = BotOpponentService(
        dictionary,
        scoring,
        random: Random(11),
      );
      final GameMatch match = newMatch(GameMode.marathon);

      int strongTotal = 0;
      int weakTotal = 0;

      for (int i = 0; i < 12; i++) {
        final WordPlay strong = await bot.playRound(
          round: match.currentRound!,
          mode: match.mode,
          opponent: _guest.copyWith(level: 40),
        );
        final WordPlay weak = await bot.playRound(
          round: match.currentRound!,
          mode: match.mode,
          opponent: _guest.copyWith(level: 2),
        );
        strongTotal += strong.score;
        weakTotal += weak.score;
      }

      expect(strongTotal, greaterThan(weakTotal));
    });
  });
}
