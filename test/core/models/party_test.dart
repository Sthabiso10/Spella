import 'package:flutter_test/flutter_test.dart';
import 'package:spella/core/models/game_mode.dart';
import 'package:spella/core/models/game_round.dart';
import 'package:spella/core/models/letter_tile.dart';
import 'package:spella/core/models/party.dart';
import 'package:spella/core/models/score_breakdown.dart';
import 'package:spella/core/models/slot_bonus.dart';
import 'package:spella/core/models/word_play.dart';

const PartyPlayer _ana = PartyPlayer(id: 'a', name: 'Ana', avatar: '🦊');
const PartyPlayer _ben = PartyPlayer(id: 'b', name: 'Ben', avatar: '🐙');
const PartyPlayer _cal = PartyPlayer(id: 'c', name: 'Cal', avatar: '🦉');

/// A round with no tiles. The party model never inspects the rack - it only
/// tracks who played what - so an empty deal keeps these tests about scoring.
PartyRound _round() => const PartyRound(
  deal: GameRound(
    index: 0,
    rack: <LetterTile>[],
    bonuses: <SlotBonus>[],
    bestPossibleWord: 'crate',
  ),
);

WordPlay _play(String playerId, String word, int score) => WordPlay(
  playerId: playerId,
  word: word,
  breakdown: ScoreBreakdown(letterPoints: score),
  secondsTaken: 10,
);

PartyMatch _matchOf(List<PartyRound> rounds, {List<PartyPlayer>? players}) => PartyMatch(
  id: 'match',
  mode: GameMode.party,
  players: players ?? const <PartyPlayer>[_ana, _ben, _cal],
  rounds: rounds,
);

void main() {
  group('PartyRound', () {
    test('is only complete once every player has had a turn', () {
      PartyRound round = _round();
      expect(round.isPlayedBy(3), isFalse);

      round = round.withPlay('a', _play('a', 'crate', 12));
      round = round.withPlay('b', _play('b', 'cart', 8));
      expect(round.isPlayedBy(3), isFalse);

      round = round.withPlay('c', _play('c', 'rat', 4));
      expect(round.isPlayedBy(3), isTrue);
    });

    test('everyone on the top score shares the round', () {
      final PartyRound round = _round()
          .withPlay('a', _play('a', 'crate', 12))
          .withPlay('b', _play('b', 'trace', 12))
          .withPlay('c', _play('c', 'rat', 4));

      expect(round.winnerIds, <String>{'a', 'b'});
      expect(round.topScore, 12);
    });

    test('a round nobody scored in has no winner', () {
      final PartyRound round = _round()
          .withPlay('a', WordPlay.passed(playerId: 'a', secondsTaken: 45))
          .withPlay('b', WordPlay.passed(playerId: 'b', secondsTaken: 45));

      expect(round.winnerIds, isEmpty);
      expect(round.topScore, 0);
    });
  });

  group('PartyMatch standings', () {
    test('rank by total points, highest first', () {
      final PartyMatch match = _matchOf(<PartyRound>[
        _round()
            .withPlay('a', _play('a', 'crate', 10))
            .withPlay('b', _play('b', 'cart', 30))
            .withPlay('c', _play('c', 'rat', 20)),
      ]);

      expect(match.standings.map((PartyStanding s) => s.player.name), <String>[
        'Ben',
        'Cal',
        'Ana',
      ]);
      expect(match.standings.map((PartyStanding s) => s.rank), <int>[1, 2, 3]);
    });

    test('players level on points share a rank rather than being split', () {
      final PartyMatch match = _matchOf(<PartyRound>[
        _round()
            .withPlay('a', _play('a', 'crate', 20))
            .withPlay('b', _play('b', 'trace', 20))
            .withPlay('c', _play('c', 'rat', 5)),
      ]);

      expect(match.standings.map((PartyStanding s) => s.rank), <int>[1, 1, 3]);
      expect(match.winners.length, 2);
    });

    test('totals accumulate across rounds', () {
      final PartyMatch match = _matchOf(<PartyRound>[
        _round().withPlay('a', _play('a', 'crate', 10)),
        _round().withPlay('a', _play('a', 'trace', 15)),
      ]);

      expect(match.totalFor('a'), 25);
      expect(match.totalFor('b'), 0);
    });

    test('rounds won counts shared rounds too', () {
      final PartyMatch match = _matchOf(<PartyRound>[
        _round()
            .withPlay('a', _play('a', 'crate', 20))
            .withPlay('b', _play('b', 'trace', 20)),
        _round()
            .withPlay('a', _play('a', 'cart', 30))
            .withPlay('b', _play('b', 'rat', 5)),
      ]);

      expect(match.roundsWonBy('a'), 2);
      expect(match.roundsWonBy('b'), 1);
    });

    test('best play ignores passes and keeps the highest scorer', () {
      final PartyMatch match = _matchOf(<PartyRound>[
        _round().withPlay('a', _play('a', 'rat', 5)),
        _round().withPlay('a', _play('a', 'crate', 22)),
        _round().withPlay('a', WordPlay.passed(playerId: 'a', secondsTaken: 45)),
      ]);

      expect(match.bestPlayFor('a')?.word, 'crate');
      expect(match.bestPlayFor('b'), isNull);
    });
  });

  group('PartyMatch progress', () {
    test('is complete only on the final round with everyone played', () {
      final PartyRound full = _round()
          .withPlay('a', _play('a', 'crate', 10))
          .withPlay('b', _play('b', 'cart', 8))
          .withPlay('c', _play('c', 'rat', 4));

      final PartyMatch midway = _matchOf(<PartyRound>[full]);
      expect(midway.isRoundComplete, isTrue);
      expect(midway.isFinalRound, isFalse);
      expect(midway.isComplete, isFalse);

      final PartyMatch last = PartyMatch(
        id: 'match',
        mode: GameMode.party,
        players: const <PartyPlayer>[_ana, _ben, _cal],
        rounds: <PartyRound>[full, full, full],
        currentRoundIndex: GameMode.party.totalRounds - 1,
      );
      expect(last.isFinalRound, isTrue);
      expect(last.isComplete, isTrue);
    });

    test('nextPlayer runs out at the end of the turn order', () {
      final PartyMatch match = _matchOf(<PartyRound>[_round()]);

      expect(match.currentPlayer, _ana);
      expect(match.nextPlayer, _ben);
      expect(match.copyWith(turnIndex: 2).nextPlayer, isNull);
    });
  });
}
