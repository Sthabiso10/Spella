import 'package:spella/core/models/game_mode.dart';
import 'package:spella/core/models/game_round.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/core/models/word_play.dart';

/// Someone playing on the shared device.
///
/// Deliberately not a [Player]: a party guest has no account, no progression
/// and no history - they typed a name into a box thirty seconds ago. Keeping
/// them a separate type is what stops party scores leaking into anyone's real
/// record.
class PartyPlayer {
  const PartyPlayer({required this.id, required this.name, required this.avatar});

  final String id;
  final String name;

  /// Emoji assigned at setup, so players can find their own row at a glance.
  final String avatar;

  /// A display-only [Player] view of this guest.
  ///
  /// The avatar and row widgets are written against [Player] because that is
  /// what everyone on screen normally is. Rather than duplicate them for the
  /// party flow, a guest presents itself as one - for rendering only. Nothing
  /// built from this is ever persisted.
  Player get asPlayer => Player(id: id, username: name, avatar: avatar);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PartyPlayer && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// One round of a party game: a single rack, played by everyone in turn.
///
/// Everybody gets the identical rack and bonus layout, exactly as in a duel, so
/// the round stays a pure test of who sees the better word.
class PartyRound {
  const PartyRound({required this.deal, this.plays = const <String, WordPlay>{}});

  /// The rack, its bonus layout and the best word available on it.
  final GameRound deal;

  /// What each player submitted, keyed by player id.
  final Map<String, WordPlay> plays;

  int scoreFor(String playerId) => plays[playerId]?.score ?? 0;

  WordPlay? playFor(String playerId) => plays[playerId];

  /// `true` once every player in the game has had their turn.
  bool isPlayedBy(int playerCount) => plays.length >= playerCount;

  /// The highest score anyone managed this round.
  int get topScore => plays.values.fold(
    0,
    (int best, WordPlay play) => play.score > best ? play.score : best,
  );

  /// Everyone who tied for the round. Empty when nobody scored.
  Set<String> get winnerIds {
    final int best = topScore;
    if (best <= 0) return const <String>{};

    return <String>{
      for (final MapEntry<String, WordPlay> entry in plays.entries)
        if (entry.value.score == best) entry.key,
    };
  }

  PartyRound withPlay(String playerId, WordPlay play) =>
      PartyRound(deal: deal, plays: <String, WordPlay>{...plays, playerId: play});
}

/// A player's position on the final table.
class PartyStanding {
  const PartyStanding({
    required this.rank,
    required this.player,
    required this.points,
    required this.roundsWon,
    this.bestPlay,
  });

  final int rank;
  final PartyPlayer player;
  final int points;

  /// How many rounds this player took outright or shared.
  final int roundsWon;

  /// Their highest scoring word of the game.
  final WordPlay? bestPlay;

  bool get isWinner => rank == 1;
}

/// A local pass-and-play game between two or more people on one device.
///
/// Immutable, like [GameMatch] - each turn produces a new instance - so the
/// view model never has to reason about who mutated what.
class PartyMatch {
  const PartyMatch({
    required this.id,
    required this.mode,
    required this.players,
    required this.rounds,
    this.currentRoundIndex = 0,
    this.turnIndex = 0,
  });

  final String id;
  final GameMode mode;

  /// Turn order, fixed for the whole game so players know who is next.
  final List<PartyPlayer> players;

  final List<PartyRound> rounds;
  final int currentRoundIndex;

  /// Index into [players] of whoever is holding the device.
  final int turnIndex;

  /// Smallest and largest party the setup screen will allow.
  static const int minPlayers = 2;
  static const int maxPlayers = 6;

  PartyPlayer get currentPlayer => players[turnIndex];

  PartyRound get currentRound => rounds[currentRoundIndex];

  /// Whoever plays after the current player, or `null` at the end of a round.
  PartyPlayer? get nextPlayer =>
      turnIndex + 1 < players.length ? players[turnIndex + 1] : null;

  int get roundNumber => currentRoundIndex + 1;

  bool get isRoundComplete => currentRound.isPlayedBy(players.length);

  bool get isFinalRound => currentRoundIndex >= mode.totalRounds - 1;

  bool get isComplete => isFinalRound && isRoundComplete;

  /// Rounds with every play in, for the progress markers.
  int get completedRounds =>
      rounds.where((PartyRound round) => round.isPlayedBy(players.length)).length;

  int totalFor(String playerId) =>
      rounds.fold(0, (int sum, PartyRound round) => sum + round.scoreFor(playerId));

  int roundsWonBy(String playerId) =>
      rounds.where((PartyRound round) => round.winnerIds.contains(playerId)).length;

  WordPlay? bestPlayFor(String playerId) {
    WordPlay? best;
    for (final PartyRound round in rounds) {
      final WordPlay? play = round.playFor(playerId);
      if (play == null || play.isPass) continue;
      if (best == null || play.score > best.score) best = play;
    }
    return best;
  }

  /// The table, highest score first.
  ///
  /// Ties share a rank rather than being split by an arbitrary tiebreak - two
  /// people on 84 points genuinely did draw, and saying otherwise across a
  /// kitchen table starts an argument the app cannot settle.
  List<PartyStanding> get standings {
    final List<PartyPlayer> sorted = List<PartyPlayer>.of(players)
      ..sort((PartyPlayer a, PartyPlayer b) => totalFor(b.id).compareTo(totalFor(a.id)));

    final List<PartyStanding> table = <PartyStanding>[];
    for (int i = 0; i < sorted.length; i++) {
      final PartyPlayer player = sorted[i];
      final int points = totalFor(player.id);
      final bool tiedWithPrevious = i > 0 && points == table[i - 1].points;

      table.add(
        PartyStanding(
          rank: tiedWithPrevious ? table[i - 1].rank : i + 1,
          player: player,
          points: points,
          roundsWon: roundsWonBy(player.id),
          bestPlay: bestPlayFor(player.id),
        ),
      );
    }
    return table;
  }

  /// Everyone who finished first. More than one on a draw.
  List<PartyStanding> get winners => standings
      .where((PartyStanding standing) => standing.isWinner)
      .toList(growable: false);

  PartyMatch copyWith({
    List<PartyRound>? rounds,
    int? currentRoundIndex,
    int? turnIndex,
  }) {
    return PartyMatch(
      id: id,
      mode: mode,
      players: players,
      rounds: rounds ?? this.rounds,
      currentRoundIndex: currentRoundIndex ?? this.currentRoundIndex,
      turnIndex: turnIndex ?? this.turnIndex,
    );
  }
}
