import 'package:spella/core/models/player.dart';
import 'package:spella/core/models/social.dart';
import 'package:stacked/stacked.dart';

/// Everything about other people: friends, invites, the activity feed and the
/// leaderboard.
///
/// [EmptySocialService] backs this with nothing at all, which is the honest
/// state of a device with no backend behind it. The Firestore implementation
/// drops in behind the same interface.
abstract class SocialService implements ListenableServiceMixin {
  /// Friends the player has added.
  List<Player> get friends;

  /// Friends currently online, most recently active first.
  List<Player> get onlineFriends;

  /// Players the matchmaker thinks are a good fit.
  List<Player> get suggestedMatches;

  /// Challenges waiting on the player's response.
  List<GameInvite> get pendingInvites;

  /// Recent friend activity for the home feed.
  List<FriendActivity> get activityFeed;

  /// Leaderboard rows for [scope], already ranked.
  List<LeaderboardEntry> leaderboard(LeaderboardScope scope);

  /// Ranking points for [player], on the same scale the leaderboard uses.
  ///
  /// Lets the current user be slotted into a board without duplicating the
  /// formula in a view model.
  int rankPointsFor(Player player);

  /// Friends whose username contains [query]. An empty query returns every
  /// friend.
  List<Player> searchFriends(String query);

  /// Accepts [invite] and removes it from the pending list.
  GameInvite? acceptInvite(String inviteId);

  /// Declines [invite].
  void declineInvite(String inviteId);

  /// Toggles the like state of an activity feed entry.
  void toggleLike(String activityId);
}

/// An empty social graph, used until the backend is connected.
///
/// Everything here returns nothing rather than a plausible-looking sample. A
/// seeded friends list makes the app demo well and lie about what it does: the
/// leaderboard ranks people who do not exist, the feed reports matches that
/// were never played, and every empty state - the ones a real first run
/// actually shows - goes untested and unseen.
///
/// The mutating methods are still implemented rather than throwing, so the
/// screens that call them stay correct the moment real data arrives.
class EmptySocialService with ListenableServiceMixin implements SocialService {
  EmptySocialService() {
    listenToReactiveValues(<dynamic>[_invites, _activity]);
  }

  /// Held as reactive values, empty, so the UI is already wired to update the
  /// instant a backend starts filling them.
  final ReactiveValue<List<GameInvite>> _invites = ReactiveValue<List<GameInvite>>(
    const <GameInvite>[],
  );

  final ReactiveValue<List<FriendActivity>> _activity =
      ReactiveValue<List<FriendActivity>>(const <FriendActivity>[]);

  @override
  List<Player> get friends => const <Player>[];

  @override
  List<Player> get onlineFriends => const <Player>[];

  @override
  List<Player> get suggestedMatches => const <Player>[];

  @override
  List<GameInvite> get pendingInvites => List<GameInvite>.unmodifiable(_invites.value);

  @override
  List<FriendActivity> get activityFeed =>
      List<FriendActivity>.unmodifiable(_activity.value);

  @override
  List<LeaderboardEntry> leaderboard(LeaderboardScope scope) =>
      const <LeaderboardEntry>[];

  @override
  int rankPointsFor(Player player) => pointsFor(player);

  /// Ranking points for [player].
  ///
  /// Real scoring logic rather than sample data, so a board built from live
  /// players ranks correctly the day one exists.
  static int pointsFor(Player player) => player.wins * 95 + player.level * 40;

  @override
  List<Player> searchFriends(String query) => const <Player>[];

  @override
  GameInvite? acceptInvite(String inviteId) {
    GameInvite? accepted;
    _invites.value = _invites.value
        .where((GameInvite invite) {
          final bool isMatch = invite.id == inviteId;
          if (isMatch) accepted = invite;
          return !isMatch;
        })
        .toList(growable: false);

    return accepted;
  }

  @override
  void declineInvite(String inviteId) {
    _invites.value = _invites.value
        .where((GameInvite invite) => invite.id != inviteId)
        .toList(growable: false);
  }

  @override
  void toggleLike(String activityId) {
    _activity.value = _activity.value
        .map(
          (FriendActivity entry) =>
              entry.id == activityId ? entry.copyWith(isLiked: !entry.isLiked) : entry,
        )
        .toList(growable: false);
  }
}
