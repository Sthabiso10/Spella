import 'package:spella/app/app.locator.dart';
import 'package:spella/app/app.router.dart';
import 'package:spella/core/models/game_mode.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/core/models/social.dart';
import 'package:spella/core/services/app_tab_service.dart';
import 'package:spella/core/services/opponent_service.dart';
import 'package:spella/core/services/player_service.dart';
import 'package:spella/core/services/social_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

/// The home dashboard: who you are, who is waiting on you, and the fastest
/// route into a game.
class HomeViewModel extends ReactiveViewModel {
  final PlayerService _playerService = locator<PlayerService>();
  final SocialService _socialService = locator<SocialService>();
  final AppTabService _tabService = locator<AppTabService>();
  final NavigationService _navigation = locator<NavigationService>();

  @override
  List<ListenableServiceMixin> get listenableServices => <ListenableServiceMixin>[
    _playerService,
    _socialService,
  ];

  Player get player => _playerService.currentPlayer;

  /// Modes offered on the quick play row.
  ///
  /// [GameMode.party] sits alongside the solo modes because that is where a
  /// player looks for "a different way to play", even though it is the one
  /// entry that opens a setup screen instead of dealing a rack.
  List<GameMode> get quickPlayModes => const <GameMode>[
    GameMode.classic,
    GameMode.blitz,
    GameMode.marathon,
    GameMode.party,
  ];

  List<FriendActivity> get activityFeed => _socialService.activityFeed;

  /// Opponents shown as "waiting on you" in the hero card.
  List<Player> get waitingFriends =>
      _socialService.onlineFriends.take(3).toList(growable: false);

  /// The opponent a quick match is played against.
  ///
  /// Always the bot for now. Once matchmaking exists this becomes the only line
  /// that has to change.
  Player get quickMatchOpponent => botOpponentFor(player);

  /// Leaderboard preview - just the podium.
  List<LeaderboardEntry> get topSpellers => _socialService
      .leaderboard(LeaderboardScope.friends)
      .take(3)
      .toList(growable: false);

  String get greeting {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 18) return 'Afternoon';
    return 'Evening';
  }

  /// Headline for the hero card, driven by how much is waiting on the player.
  String get heroTitle =>
      waitingFriends.isEmpty ? 'Ready to\nspell?' : 'Your move,\n${player.username}';

  String get heroSubtitle {
    final int waiting = waitingFriends.length;
    // With nobody added yet, the honest pitch is the game itself rather than a
    // social loop the player has no one to take part in.
    if (waiting == 0) {
      return 'Play a round against the bot, or pass a phone round the table.';
    }
    return "You have $waiting friend${waiting == 1 ? '' : 's'} waiting for their "
        "turn. Don't leave them hanging!";
  }

  /// Starts a match in [mode].
  ///
  /// Pass & Play has no remote opponent to pick, so it detours through the
  /// setup screen to collect the names of everyone in the room. Everything else
  /// is played against the bot.
  Future<void> startQuickMatch(GameMode mode) async {
    if (mode == GameMode.party) {
      await _openPartySetup();
      return;
    }

    await _openMatch(mode: mode, opponent: quickMatchOpponent);
  }

  /// Challenges a specific player.
  Future<void> challenge(Player opponent, {GameMode mode = GameMode.classic}) =>
      _openMatch(mode: mode, opponent: opponent);

  void toggleLike(String activityId) => _socialService.toggleLike(activityId);

  void openFriends() => _tabService.goTo(AppTab.friends);

  void openLeaderboard() => _tabService.goTo(AppTab.ranks);

  Future<void> _openMatch({required GameMode mode, required Player opponent}) =>
      _navigation.navigateTo(
        Routes.match,
        arguments: MatchViewArguments(mode: mode, opponent: opponent),
      ) ??
      Future<void>.value();

  Future<void> _openPartySetup() =>
      _navigation.navigateTo(Routes.partySetup) ?? Future<void>.value();
}
