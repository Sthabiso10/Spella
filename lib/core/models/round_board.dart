import 'dart:math';

import 'package:spella/core/models/letter_tile.dart';
import 'package:spella/core/models/slot_bonus.dart';

/// The playable surface for one round: a rack of tiles plus the ordered word
/// the player is building from them.
///
/// This is deliberately plain Dart with no Flutter imports - all of the rules
/// about what may be placed where live here, so they can be unit tested and so
/// the view model only ever forwards intent.
class RoundBoard {
  RoundBoard({required List<LetterTile> rack, required List<SlotBonus> bonuses})
    : assert(rack.length == bonuses.length, 'Every slot needs a bonus entry'),
      _rack = List<LetterTile>.of(rack),
      _bonuses = List<SlotBonus>.unmodifiable(bonuses);

  final List<LetterTile> _rack;
  final List<SlotBonus> _bonuses;
  final List<LetterTile> _placed = <LetterTile>[];

  /// Tiles in rack order. Order changes when the player shuffles.
  List<LetterTile> get rack => List<LetterTile>.unmodifiable(_rack);

  /// Bonus attached to each slot, indexed by position in the word.
  List<SlotBonus> get bonuses => _bonuses;

  /// Tiles currently forming the word, in play order.
  List<LetterTile> get placed => List<LetterTile>.unmodifiable(_placed);

  /// Number of slots, which always matches the rack size for the mode.
  int get slotCount => _bonuses.length;

  /// The word as currently spelled, lowercase.
  String get word => _placed.map((LetterTile tile) => tile.letter).join();

  bool get isEmpty => _placed.isEmpty;

  bool get isFull => _placed.length == slotCount;

  /// True when [tile] has already been placed on the board.
  bool isPlaced(LetterTile tile) => _placed.contains(tile);

  /// Bonus for [slotIndex], or [SlotBonus.none] when out of range.
  SlotBonus bonusAt(int slotIndex) => slotIndex >= 0 && slotIndex < _bonuses.length
      ? _bonuses[slotIndex]
      : SlotBonus.none;

  /// The tile occupying [slotIndex], or `null` when the slot is still empty.
  LetterTile? tileAt(int slotIndex) =>
      slotIndex >= 0 && slotIndex < _placed.length ? _placed[slotIndex] : null;

  /// Appends [tile] to the word. Returns `false` when the tile is already in
  /// play or the board is full.
  bool place(LetterTile tile) {
    if (isFull || isPlaced(tile)) return false;
    _placed.add(tile);
    return true;
  }

  /// Removes the tile at [slotIndex], closing the gap so the word stays
  /// contiguous. Returns `false` when the slot is empty.
  bool removeAt(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= _placed.length) return false;
    _placed.removeAt(slotIndex);
    return true;
  }

  /// Removes [tile] from the word wherever it sits.
  bool remove(LetterTile tile) => _placed.remove(tile);

  /// Returns every tile to the rack.
  void clear() => _placed.clear();

  /// Randomises rack order without disturbing the word being built.
  void shuffleRack([Random? random]) => _rack.shuffle(random);

  /// Replaces the word with [letters], picking tiles from the rack. Used by
  /// the hint power-up. Returns `false` if the word cannot be spelled from the
  /// tiles available.
  bool spell(String letters) {
    final List<LetterTile> available = List<LetterTile>.of(_rack);
    final List<LetterTile> picked = <LetterTile>[];

    for (final String letter in letters.toLowerCase().split('')) {
      final int index = available.indexWhere((LetterTile tile) => tile.letter == letter);
      if (index == -1) return false;
      picked.add(available.removeAt(index));
    }
    if (picked.length > slotCount) return false;

    _placed
      ..clear()
      ..addAll(picked);
    return true;
  }
}
