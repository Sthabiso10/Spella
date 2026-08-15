import 'package:spella/app/app.locator.dart';
import 'package:spella/app/app.router.dart';
import 'package:spella/core/models/game_mode.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/core/models/social.dart';
import 'package:spella/core/services/opponent_service.dart';
import 'package:spella/core/services/player_service.dart';
import 'package:spella/core/services/social_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

/// Find people, answer challenges, start games.
class FriendsViewModel extends ReactiveViewModel {
  final SocialService _socialService = locator<SocialService>();
  final PlayerService _playerService = locator<PlayerService>();
  final NavigationService _navigation = locator<NavigationService>();

  /// Below this many friends, a search field costs more than it saves - the
  /// whole list is already on one screen, and a permanently empty input at the
  /// top of the page is an affordance that never pays out.
  static const int _searchThreshold = 6;

  String _query = '';

  @override
  List<ListenableServiceMixin> get listenableServices => <ListenableServiceMixin>[
    _socialService,
    _playerService,
  ];

  String get query => _query;

  List<GameInvite> get invites => _socialService.pendingInvites;

  /// Everyone matching the current search, in one flat list.
  ///
  /// While searching there is no online/offline split: dividing three results
  /// into two labelled sections buries the answer the player is looking for
  /// under headings that exist to organise a list they are not reading.
  List<Player> get searchResults => _socialService.searchFriends(_query);

  List<Player> get onlineFriends => _socialService.onlineFriends;

  /// Friends who are not around right now.
  List<Player> get offlineFriends => _socialService.friends
      .where((Player friend) => !friend.isOnline)
      .toList(growable: false);

  List<Player> get suggestedMatches => _socialService.suggestedMatches;

  bool get hasFriends => _socialService.friends.isNotEmpty;

  /// Total friends, ignoring the current search, for the header count.
  int get friendCount => _socialService.friends.length;

  /// Friends online right now, ignoring the current search.
  int get onlineCount => _socialService.onlineFriends.length;

  bool get isSearching => _query.trim().isNotEmpty;

  bool get showSearch => friendCount >= _searchThreshold;

  /// The line under the page title. Absent rather than "0 friends · 0 online",
  /// which announces the emptiness before the page has said anything else.
  String? get headerSubtitle {
    if (!hasFriends) return null;
    return '$friendCount friend${friendCount == 1 ? '' : 's'} · $onlineCount online';
  }

  void search(String value) {
    _query = value;
    rebuildUi();
  }

  void clearSearch() => search('');

  /// Accepts a challenge and drops straight into the match.
  Future<void> acceptInvite(GameInvite invite) async {
    final GameInvite? accepted = _socialService.acceptInvite(invite.id);
    if (accepted == null) return;

    await _startMatch(accepted.from, accepted.mode);
  }

  void declineInvite(GameInvite invite) => _socialService.declineInvite(invite.id);

  Future<void> challenge(Player opponent, {GameMode mode = GameMode.classic}) =>
      _startMatch(opponent, mode);

  /// Hands the phone round the table.
  ///
  /// The one way to play with other people that works today, with no account,
  /// no connection and no friends list - which is why the empty state leads
  /// with it rather than with an apology.
  Future<void> startPassAndPlay() =>
      _navigation.navigateTo(Routes.partySetup) ?? Future<void>.value();

  Future<void> playBot() =>
      _startMatch(botOpponentFor(_playerService.currentPlayer), GameMode.classic);

  Future<void> _startMatch(Player opponent, GameMode mode) =>
      _navigation.navigateTo(
        Routes.match,
        arguments: MatchViewArguments(mode: mode, opponent: opponent),
      ) ??
      Future<void>.value();
}
