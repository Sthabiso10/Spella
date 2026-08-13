/// In-match abilities a player can spend coins on.
enum PowerUp {
  hint(
    id: 'hint',
    label: 'Hint',
    description: 'Spells out a strong word from your rack',
    cost: 60,
  ),
  freeze(
    id: 'freeze',
    label: 'Freeze',
    description: 'Adds 15 seconds to the round clock',
    cost: 40,
  ),
  swap(
    id: 'swap',
    label: 'Swap',
    description: 'Redraws the tiles you have not used',
    cost: 50,
  );

  const PowerUp({
    required this.id,
    required this.label,
    required this.description,
    required this.cost,
  });

  final String id;
  final String label;
  final String description;

  /// Price in coins.
  final int cost;

  /// Seconds [PowerUp.freeze] adds to the clock.
  static const int freezeSeconds = 15;
}
