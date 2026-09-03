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

  /// Full value equality, not identity by [id].
  ///
  /// This matters more than it looks. The signed-in player is held in a
  /// stacked `ReactiveValue`, whose setter drops the write when the new value
  /// `==` the old one. With equality defined as "same id", every progression
  /// update - coins spent on a power-up, XP and rewards from a finished match,
  /// an avatar bought in the shop - compared equal to the player it was
  /// derived from and was silently discarded. Comparing the whole record is
  /// what makes a change actually register as one.
  ///
  /// To ask whether two references are the same person, compare [id] directly.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Player &&
        other.id == id &&
        other.username == username &&
        other.avatar == avatar &&
        other.level == level &&
        other.xp == xp &&
        other.coins == coins &&
        other.gems == gems &&
        other.wins == wins &&
        other.losses == losses &&
        other.streak == streak &&
        other.isOnline == isOnline &&
        other.isBot == isBot &&
        other.ownedAvatars.length == ownedAvatars.length &&
        other.ownedAvatars.containsAll(ownedAvatars);
  }

  @override
  int get hashCode => Object.hash(
    id,
    username,
    avatar,
    level,
    xp,
    coins,
    gems,
    wins,
    losses,
    streak,
    isOnline,
    isBot,
    Object.hashAllUnordered(ownedAvatars),
  );
}
