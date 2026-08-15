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

/// The home dashboard: who you are, how far along you are, who is waiting on
/// you, and the fastest route into a game.
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

  /// The modes on the grid.
  ///
  /// [GameMode.party] sits alongside the solo modes because that is where a
  /// player looks for "a different way to play", even though it is the one
  /// entry that opens a setup screen instead of dealing a rack.
  List<GameMode> get gameModes => const <GameMode>[
    GameMode.classic,
    GameMode.blitz,
    GameMode.marathon,
    GameMode.party,
  ];

  /// What the one-tap play button starts.
  ///
  /// Named separately from the grid so the hero can say out loud which mode it
  /// is about to deal - a button that starts *a* game without saying which one
  /// is a button people hesitate over.
  GameMode get quickMatchMode => GameMode.classic;

  List<FriendActivity> get activityFeed => _socialService.activityFeed;

  /// Opponents shown as waiting on the player.
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

  /// Whether the player has finished a match yet.
  ///
  /// Gates the record strip: four zeroes tell a new player nothing about
  /// themselves and quite a lot about how empty the app is.
  bool get hasPlayed => player.gamesPlayed > 0;

  /// Whether to offer the nudge towards adding people.
  ///
  /// Home used to carry a permanent "nothing yet" feed and a leaderboard that
  /// never appeared. Both are now silent when they have nothing to say, and
  /// this single prompt - which has an action attached - stands in for them.
  bool get showFriendsPrompt =>
      _socialService.friends.isEmpty && activityFeed.isEmpty && topSpellers.isEmpty;

  String get greeting {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 18) return 'Afternoon';
    return 'Evening';
  }

  /// Headline for the hero, in priority order: something is waiting on you, you
  /// have a run going, you have never played, or you are simply back.
  ///
  /// One line, never a hard-wrapped two. A baked-in newline breaks the moment
  /// the text scale or the screen width moves.
  String get heroTitle {
    if (waitingFriends.isNotEmpty) return 'Your move';
    if (player.streak >= 2) return '${player.streak} in a row';
    if (!hasPlayed) return 'Ready to spell?';
    return 'Back for another?';
  }

  String get heroSubtitle {
    final int waiting = waitingFriends.length;
    if (waiting > 0) {
      return '$waiting friend${waiting == 1 ? ' is' : 's are'} waiting on your turn. '
          "Don't leave them hanging.";
    }
    if (player.streak >= 2) return 'Take one more and the run keeps going.';
    // With nothing played yet, the honest pitch is the game itself rather than
    // a social loop the player has no one to take part in.
    if (!hasPlayed) {
      return 'Build the best word you can from the tiles you are dealt. '
          'Highest total after five rounds wins.';
    }
    return 'Jump straight back in, or pick a different mode below.';
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
