import 'package:spella/app/app.locator.dart';
import 'package:spella/app/app.router.dart';
import 'package:spella/core/models/game_mode.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/core/models/social.dart';
import 'package:spella/core/services/social_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

/// Find people, answer challenges, start games.
class FriendsViewModel extends ReactiveViewModel {
  final SocialService _socialService = locator<SocialService>();
  final NavigationService _navigation = locator<NavigationService>();

  String _query = '';

  @override
  List<ListenableServiceMixin> get listenableServices => <ListenableServiceMixin>[
    _socialService,
  ];

  String get query => _query;

  List<GameInvite> get invites => _socialService.pendingInvites;

  /// Online friends matching the current search.
  List<Player> get onlineFriends => _socialService
      .searchFriends(_query)
      .where((Player friend) => friend.isOnline)
      .toList(growable: false);

  /// Everyone else matching the current search.
  List<Player> get offlineFriends => _socialService
      .searchFriends(_query)
      .where((Player friend) => !friend.isOnline)
      .toList(growable: false);

  List<Player> get suggestedMatches => _socialService.suggestedMatches;

  bool get hasResults => onlineFriends.isNotEmpty || offlineFriends.isNotEmpty;

  /// Total friends, ignoring the current search, for the header count.
  int get friendCount => _socialService.friends.length;

  /// Friends online right now, ignoring the current search.
  int get onlineCount => _socialService.onlineFriends.length;

  bool get isSearching => _query.trim().isNotEmpty;

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

  Future<void> _startMatch(Player opponent, GameMode mode) =>
      _navigation.navigateTo(
        Routes.match,
        arguments: MatchViewArguments(mode: mode, opponent: opponent),
      ) ??
      Future<void>.value();
}
