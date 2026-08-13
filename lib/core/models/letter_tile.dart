import 'package:spella/core/data/letter_data.dart';

/// A single lettered tile sitting in a player's rack.
///
/// Tiles carry an [id] because a rack can legitimately hold duplicates of the
/// same letter and the board needs to tell them apart.
class LetterTile {
  const LetterTile({required this.id, required this.letter, required this.value});

  /// Builds a tile, deriving its point [value] from [LetterData].
  factory LetterTile.of(String letter, {required int index}) {
    final String normalised = letter.toLowerCase();
    return LetterTile(
      id: '$normalised-$index',
      letter: normalised,
      value: LetterData.valueOf(normalised),
    );
  }

  /// Unique within a rack.
  final String id;

  /// Always lowercase; the UI upper-cases for display.
  final String letter;

  /// Base point value before any slot multiplier.
  final int value;

  /// Uppercase letter for display.
  String get display => letter.toUpperCase();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LetterTile && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'LetterTile($id)';
}
