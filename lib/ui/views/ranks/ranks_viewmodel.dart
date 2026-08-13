import 'package:spella/app/app.locator.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/core/models/social.dart';
import 'package:spella/core/services/player_service.dart';
import 'package:spella/core/services/social_service.dart';
import 'package:stacked/stacked.dart';

/// The full leaderboard, plus where the player sits on it.
class RanksViewModel extends ReactiveViewModel {
  final SocialService _socialService = locator<SocialService>();
  final PlayerService _playerService = locator<PlayerService>();

  LeaderboardScope _scope = LeaderboardScope.friends;

  @override
  List<ListenableServiceMixin> get listenableServices => <ListenableServiceMixin>[
    _socialService,
    _playerService,
  ];

  LeaderboardScope get scope => _scope;

  List<LeaderboardScope> get scopes => LeaderboardScope.values;

  Player get player => _playerService.currentPlayer;

  /// The board with the player slotted in and everything re-ranked, so their
  /// position is always honest rather than pinned to the bottom.
  List<LeaderboardEntry> get entries {
    final List<LeaderboardEntry> board = <LeaderboardEntry>[
      ..._socialService.leaderboard(_scope),
      LeaderboardEntry(
        rank: 0,
        player: player,
        points: _socialService.rankPointsFor(player),
        isCurrentUser: true,
      ),
    ]..sort((LeaderboardEntry a, LeaderboardEntry b) => b.points.compareTo(a.points));

    return <LeaderboardEntry>[
      for (int i = 0; i < board.length; i++)
        LeaderboardEntry(
          rank: i + 1,
          player: board[i].player,
          points: board[i].points,
          isCurrentUser: board[i].isCurrentUser,
        ),
    ];
  }

  /// Whether there is anyone to rank the player against.
  ///
  /// The player is always slotted into their own board, so a board of one is
  /// not a leaderboard - it is an empty one with the reader standing on it.
  /// Calling that "1st place" would be the app congratulating them for being
  /// alone.
  bool get hasBoard => entries.length > 1;

  /// The top three, for the podium.
  List<LeaderboardEntry> get podium => entries.take(3).toList(growable: false);

  /// Everyone below the podium.
  List<LeaderboardEntry> get rest => entries.skip(3).toList(growable: false);

  /// The player's own row, pinned at the bottom of the screen.
  LeaderboardEntry get myEntry =>
      entries.firstWhere((LeaderboardEntry entry) => entry.isCurrentUser);

  void setScope(LeaderboardScope value) {
    if (_scope == value) return;
    _scope = value;
    rebuildUi();
  }
}
