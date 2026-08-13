/// Multiplier attached to a slot on the word board.
///
/// Letter bonuses multiply the tile dropped on them; word bonuses multiply the
/// whole word once, which is what makes slot ordering a real decision.
enum SlotBonus {
  none(label: '', letterMultiplier: 1, wordMultiplier: 1),
  doubleLetter(label: '2L', letterMultiplier: 2, wordMultiplier: 1),
  tripleLetter(label: '3L', letterMultiplier: 3, wordMultiplier: 1),
  doubleWord(label: 'x2', letterMultiplier: 1, wordMultiplier: 2),
  tripleWord(label: 'x3', letterMultiplier: 1, wordMultiplier: 3);

  const SlotBonus({
    required this.label,
    required this.letterMultiplier,
    required this.wordMultiplier,
  });

  /// Short badge text drawn on the slot.
  final String label;

  /// Applied to the value of the tile placed here.
  final int letterMultiplier;

  /// Applied to the whole word total when a tile occupies this slot.
  final int wordMultiplier;

  bool get isWordBonus => wordMultiplier > 1;

  bool get isNone => this == SlotBonus.none;

  /// Bonuses that can be randomly assigned to a board.
  static const List<SlotBonus> assignable = <SlotBonus>[
    SlotBonus.doubleLetter,
    SlotBonus.tripleLetter,
    SlotBonus.doubleWord,
    SlotBonus.tripleWord,
  ];
}
