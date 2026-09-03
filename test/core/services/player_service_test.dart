import 'package:flutter_test/flutter_test.dart';
import 'package:spella/core/models/game_match.dart';
import 'package:spella/core/models/game_mode.dart';
import 'package:spella/core/models/game_round.dart';
import 'package:spella/core/models/letter_tile.dart';
import 'package:spella/core/models/score_breakdown.dart';
import 'package:spella/core/models/slot_bonus.dart';
import 'package:spella/core/models/word_play.dart';
import 'package:spella/core/models/match_result.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/core/services/player_service.dart';

const Player _me = Player(
  id: 'me',
  username: 'Player',
  avatar: '🦸',
  coins: 200,
  gems: 20,
);

const Player _rival = Player(id: 'them', username: 'Rival', avatar: '🐙');

/// One decided round, taken by the host, so the result reads as a real win
/// rather than as a goalless draw.
const GameRound _hostTakesIt = GameRound(
  index: 0,
  rack: <LetterTile>[],
  bonuses: <SlotBonus>[],
  bestPossibleWord: 'quartz',
  hostPlay: WordPlay(
    playerId: 'me',
    word: 'quartz',
    breakdown: ScoreBreakdown(letterPoints: 40),
    secondsTaken: 12,
  ),
  guestPlay: WordPlay(
    playerId: 'them',
    word: 'rat',
    breakdown: ScoreBreakdown(letterPoints: 6),
    secondsTaken: 20,
  ),
);

MatchResult _win({int coins = 120, int xp = 45, int gems = 10}) => MatchResult(
  match: const GameMatch(
    id: 'm',
    mode: GameMode.classic,
    host: _me,
    guest: _rival,
    rounds: <GameRound>[_hostTakesIt],
  ),
  xpEarned: xp,
  coinsEarned: coins,
  gemsEarned: gems,
  isMvp: false,
  levelledUp: false,
);

void main() {
  late PlayerService service;

  setUp(() => service = LocalPlayerService(initialPlayer: _me));

  // Every one of these went through a reactive value whose setter drops the
  // write when the new value equals the old. While the player compared equal
  // on id alone, that meant none of them took effect: coins were spent for
  // free, matches paid out nothing, and the shop handed over avatars without
  // charging. They are all one bug, so they are all covered here.
  group('progression actually lands', () {
    test('replacing the player takes effect', () {
      service.setPlayer(_me.copyWith(coins: 500));

      expect(service.currentPlayer.coins, 500);
    });

    test('spending coins deducts them', () {
      expect(service.spendCoins(50), isTrue);

      expect(service.currentPlayer.coins, 150);
    });

    test('spending more than the balance changes nothing', () {
      expect(service.spendCoins(1000), isFalse);

      expect(service.currentPlayer.coins, 200);
    });

    test('spending nothing is refused', () {
      expect(service.spendCoins(0), isFalse);
      expect(service.currentPlayer.coins, 200);
    });

    test('awarded coins are credited', () {
      service.awardCoins(80);

      expect(service.currentPlayer.coins, 280);
    });

    test('a finished match pays out', () {
      service.applyMatchResult(_win());

      final Player player = service.currentPlayer;
      expect(player.coins, 320);
      expect(player.gems, 30);
      expect(player.xp, 45);
      expect(player.wins, 1);
      expect(player.streak, 1);
    });

    test('enough XP rolls the level over', () {
      service.applyMatchResult(_win(xp: 250));

      expect(service.currentPlayer.level, greaterThan(1));
    });

    test('buying an avatar charges gems and equips it', () {
      expect(service.unlockAvatar('🦊', 15), isTrue);

      final Player player = service.currentPlayer;
      expect(player.gems, 5);
      expect(player.avatar, '🦊');
      expect(player.owns('🦸'), isTrue, reason: 'the old one is kept');
    });

    test('an avatar beyond the gem balance is refused', () {
      expect(service.unlockAvatar('🦊', 999), isFalse);

      expect(service.currentPlayer.avatar, '🦸');
      expect(service.currentPlayer.gems, 20);
    });

    test('successive spends each land', () {
      service
        ..spendCoins(50)
        ..spendCoins(50)
        ..spendCoins(25);

      expect(service.currentPlayer.coins, 75);
    });
  });

  group('player equality', () {
    test('two records differing only in coins are not equal', () {
      expect(_me.copyWith(coins: 1) == _me.copyWith(coins: 2), isFalse);
    });

    test('an identical record is equal and hashes the same', () {
      final Player copy = _me.copyWith();

      expect(copy, _me);
      expect(copy.hashCode, _me.hashCode);
    });

    test('owned avatars count towards equality regardless of order', () {
      const Player a = Player(
        id: 'me',
        username: 'Player',
        avatar: '🦸',
        ownedAvatars: <String>{'🦊', '🐙'},
      );
      const Player b = Player(
        id: 'me',
        username: 'Player',
        avatar: '🦸',
        ownedAvatars: <String>{'🐙', '🦊'},
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different people are never equal', () {
      expect(_me == _rival, isFalse);
    });
  });
}
