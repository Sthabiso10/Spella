/// A person (or bot) taking part in a match.
///
/// Immutable - progression changes produce a new instance via [copyWith] so
/// state updates stay explicit and easy to trace once a backend is wired in.
class Player {
  const Player({
    required this.id,
    required this.username,
    required this.avatar,
    this.level = 1,
    this.xp = 0,
    this.coins = 0,
    this.gems = 0,
    this.wins = 0,
    this.losses = 0,
    this.streak = 0,
    this.isOnline = false,
    this.isBot = false,
    this.ownedAvatars = const <String>{},
  });

  final String id;
  final String username;

  /// Emoji stand-in for a profile picture until image uploads are wired up.
  final String avatar;

  final int level;
  final int xp;
  final int coins;
  final int gems;
  final int wins;
  final int losses;

  /// Consecutive wins; drives the flame indicator on the home screen.
  final int streak;

  final bool isOnline;
  final bool isBot;

  /// Avatars unlocked in the shop. The equipped one is [avatar].
  final Set<String> ownedAvatars;

  /// `true` when [candidate] is equipped or already unlocked.
  bool owns(String candidate) => candidate == avatar || ownedAvatars.contains(candidate);

  /// XP required to reach the next level. Grows gently so early levels feel
  /// quick and later ones still mean something.
  int get xpForNextLevel => 100 + (level - 1) * 50;

  /// Progress through the current level, clamped to 0..1.
  double get levelProgress => (xp / xpForNextLevel).clamp(0.0, 1.0);

  int get gamesPlayed => wins + losses;

  /// Win rate as a percentage; `0` before any games are played.
  int get winRate => gamesPlayed == 0 ? 0 : ((wins / gamesPlayed) * 100).round();

  Player copyWith({
    String? username,
    String? avatar,
    int? level,
    int? xp,
    int? coins,
    int? gems,
    int? wins,
    int? losses,
    int? streak,
    bool? isOnline,
    Set<String>? ownedAvatars,
  }) {
    return Player(
      id: id,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      streak: streak ?? this.streak,
      isOnline: isOnline ?? this.isOnline,
      isBot: isBot,
      ownedAvatars: ownedAvatars ?? this.ownedAvatars,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Player && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
