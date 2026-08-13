import 'package:spella/core/models/game_mode.dart';
import 'package:spella/core/models/player.dart';

/// Kinds of events that can show up in the friend activity feed.
enum ActivityKind { wordPlayed, badgeUnlocked, matchWon, levelUp }

/// One entry in the home screen activity feed.
class FriendActivity {
  const FriendActivity({
    required this.id,
    required this.player,
    required this.kind,
    required this.headline,
    required this.detail,
    required this.occurredAt,
    this.isLiked = false,
  });

  final String id;
  final Player player;
  final ActivityKind kind;

  /// e.g. `just spelled QUARTZ`.
  final String headline;

  /// e.g. `for 50 points`.
  final String detail;

  final DateTime occurredAt;
  final bool isLiked;

  FriendActivity copyWith({bool? isLiked}) => FriendActivity(
    id: id,
    player: player,
    kind: kind,
    headline: headline,
    detail: detail,
    occurredAt: occurredAt,
    isLiked: isLiked ?? this.isLiked,
  );
}

/// A pending challenge from another player.
class GameInvite {
  const GameInvite({
    required this.id,
    required this.from,
    required this.mode,
    required this.sentAt,
  });

  final String id;
  final Player from;
  final GameMode mode;
  final DateTime sentAt;
}

/// Which population a leaderboard covers.
enum LeaderboardScope {
  friends(label: 'Friends'),
  global(label: 'Global');

  const LeaderboardScope({required this.label});

  final String label;
}

/// A row on the leaderboard.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.player,
    required this.points,
    this.isCurrentUser = false,
  });

  final int rank;
  final Player player;
  final int points;
  final bool isCurrentUser;

  bool get isPodium => rank <= 3;
}
