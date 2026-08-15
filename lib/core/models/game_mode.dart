/// The rule sets a match can be played under.
///
/// Everything that varies between modes lives here - rack size, round count
/// and clock - so adding a new mode never means touching the engine or the UI.
enum GameMode {
  classic(
    id: 'classic',
    label: 'Classic',
    tagline: 'Best of 5 · 7 tiles',
    rackSize: 7,
    totalRounds: 5,
    secondsPerRound: 45,
    bonusSlots: 2,
  ),
  blitz(
    id: 'blitz',
    label: 'Blitz',
    tagline: 'Fast 3 rounds · 6 tiles',
    rackSize: 6,
    totalRounds: 3,
    secondsPerRound: 25,
    bonusSlots: 1,
  ),
  marathon(
    id: 'marathon',
    label: 'Marathon',
    tagline: '7 rounds · 9 tiles',
    rackSize: 9,
    totalRounds: 7,
    secondsPerRound: 60,
    bonusSlots: 3,
  ),
  daily(
    id: 'daily',
    label: 'Daily Challenge',
    tagline: 'One rack · one shot',
    rackSize: 8,
    totalRounds: 1,
    secondsPerRound: 90,
    bonusSlots: 2,
  ),

  /// Everyone on one device, taking turns on the same rack.
  ///
  /// Three rounds rather than five: with a full table of six that is already
  /// eighteen turns, and a party game that outlasts the room has failed.
  party(
    id: 'party',
    label: 'Pass & Play',
    tagline: 'One device · 2 to 6 players',
    rackSize: 7,
    totalRounds: 3,
    secondsPerRound: 45,
    bonusSlots: 2,
  );

  const GameMode({
    required this.id,
    required this.label,
    required this.tagline,
    required this.rackSize,
    required this.totalRounds,
    required this.secondsPerRound,
    required this.bonusSlots,
  });

  /// Stable identifier, safe to persist.
  final String id;

  /// Human readable name shown in the UI.
  final String label;

  /// Short description shown on mode cards.
  final String tagline;

  /// How many tiles each player is dealt per round. Also the number of word
  /// slots on the board.
  final int rackSize;

  /// Rounds played before a winner is declared.
  final int totalRounds;

  /// Clock each player gets to build their word.
  final int secondsPerRound;

  /// How many slots carry a bonus multiplier.
  final int bonusSlots;

  /// Resolves a mode from its persisted [id], defaulting to [GameMode.classic].
  static GameMode fromId(String id) => GameMode.values.firstWhere(
    (GameMode mode) => mode.id == id,
    orElse: () => GameMode.classic,
  );
}
