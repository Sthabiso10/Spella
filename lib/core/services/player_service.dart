import 'package:spella/core/models/game_match.dart';
import 'package:spella/core/models/match_result.dart';
import 'package:spella/core/models/player.dart';
import 'package:stacked/stacked.dart';

/// Owns the signed-in player and their progression.
///
/// Auth and persistence land behind this interface later; today
/// [LocalPlayerService] keeps everything in memory so the game is fully
/// playable without a backend.
abstract class PlayerService implements ListenableServiceMixin {
  /// The player using the app.
  Player get currentPlayer;

  /// Applies the rewards from a finished match, including level ups and the
  /// win streak.
  void applyMatchResult(MatchResult result);

  /// Deducts [amount] coins. Returns `false` when the player cannot afford it.
  bool spendCoins(int amount);

  /// Credits [amount] coins, e.g. from a daily challenge.
  void awardCoins(int amount);

  /// Buys [avatar] for [gemCost] gems and equips it. Returns `false` when the
  /// player cannot afford it.
  bool unlockAvatar(String avatar, int gemCost);

  /// Equips an avatar the player already owns.
  void equipAvatar(String avatar);

  /// Replaces the player, used when a profile is edited or a session restored.
  void setPlayer(Player player);
}

/// In-memory [PlayerService]. Swap the starting player for the authenticated
/// one when login is wired up.
class LocalPlayerService with ListenableServiceMixin implements PlayerService {
  LocalPlayerService({Player? initialPlayer})
    : _player = ReactiveValue<Player>(initialPlayer ?? _defaultPlayer) {
    listenToReactiveValues(<ReactiveValue<Player>>[_player]);
  }

  /// A brand new account: level one, nothing earned, nothing spent.
  ///
  /// Every figure here is zero on purpose. Seeding a player with a level, a
  /// win record and a wallet makes the whole app look like a screenshot, and
  /// hides the empty states that a real first run has to get right.
  static const Player _defaultPlayer = Player(
    id: 'me',
    username: 'Player',
    avatar: '🦸',
    isOnline: true,
  );

  final ReactiveValue<Player> _player;

  @override
  Player get currentPlayer => _player.value;

  @override
  void setPlayer(Player player) => _player.value = player;

  @override
  void applyMatchResult(MatchResult result) {
    final Player player = currentPlayer;
    final bool won = result.outcome == MatchOutcome.won;

    int level = player.level;
    int xp = player.xp + result.xpEarned;

    // Roll over as many levels as the XP covers, so a big win can grant more
    // than one.
    while (xp >= _xpNeeded(level)) {
      xp -= _xpNeeded(level);
      level++;
    }

    _player.value = player.copyWith(
      level: level,
      xp: xp,
      coins: player.coins + result.coinsEarned,
      gems: player.gems + result.gemsEarned,
      wins: won ? player.wins + 1 : player.wins,
      losses: result.outcome == MatchOutcome.lost ? player.losses + 1 : player.losses,
      streak: won ? player.streak + 1 : 0,
    );
  }

  @override
  bool spendCoins(int amount) {
    final Player player = currentPlayer;
    if (amount <= 0 || player.coins < amount) return false;

    _player.value = player.copyWith(coins: player.coins - amount);
    return true;
  }

  @override
  void awardCoins(int amount) {
    if (amount <= 0) return;
    _player.value = currentPlayer.copyWith(coins: currentPlayer.coins + amount);
  }

  @override
  bool unlockAvatar(String avatar, int gemCost) {
    final Player player = currentPlayer;
    if (player.owns(avatar)) {
      equipAvatar(avatar);
      return true;
    }
    if (player.gems < gemCost) return false;

    _player.value = player.copyWith(
      gems: player.gems - gemCost,
      avatar: avatar,
      ownedAvatars: <String>{...player.ownedAvatars, player.avatar, avatar},
    );
    return true;
  }

  @override
  void equipAvatar(String avatar) {
    final Player player = currentPlayer;
    if (!player.owns(avatar) || player.avatar == avatar) return;

    _player.value = player.copyWith(
      avatar: avatar,
      ownedAvatars: <String>{...player.ownedAvatars, player.avatar},
    );
  }

  static int _xpNeeded(int level) => 100 + (level - 1) * 50;
}
