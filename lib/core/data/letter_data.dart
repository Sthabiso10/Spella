/// Static letter tables used when generating racks and scoring words.
class LetterData {
  const LetterData._();

  /// Point value of every letter. Rarer letters are worth more, which is what
  /// makes tile placement on bonus slots an interesting decision.
  static const Map<String, int> values = <String, int>{
    'a': 1,
    'b': 3,
    'c': 3,
    'd': 2,
    'e': 1,
    'f': 4,
    'g': 2,
    'h': 4,
    'i': 1,
    'j': 8,
    'k': 5,
    'l': 1,
    'm': 3,
    'n': 1,
    'o': 1,
    'p': 3,
    'q': 10,
    'r': 1,
    's': 1,
    't': 1,
    'u': 1,
    'v': 4,
    'w': 4,
    'x': 8,
    'y': 4,
    'z': 10,
  };

  /// Relative frequency used when padding a rack with filler letters. Mirrors
  /// English letter distribution so racks stay playable.
  static const Map<String, int> frequencies = <String, int>{
    'a': 9,
    'b': 2,
    'c': 2,
    'd': 4,
    'e': 12,
    'f': 2,
    'g': 3,
    'h': 2,
    'i': 9,
    'j': 1,
    'k': 1,
    'l': 4,
    'm': 2,
    'n': 6,
    'o': 8,
    'p': 2,
    'q': 1,
    'r': 6,
    's': 4,
    't': 6,
    'u': 4,
    'v': 2,
    'w': 2,
    'x': 1,
    'y': 2,
    'z': 1,
  };

  /// Value of [letter], or `0` when the character is not a letter.
  static int valueOf(String letter) => values[letter.toLowerCase()] ?? 0;

  /// Flattened frequency table, e.g. `['a','a', ... ,'b','b', ...]`, so a
  /// filler letter can be drawn with a single random index.
  static final List<String> weightedAlphabet = List<String>.unmodifiable(<String>[
    for (final MapEntry<String, int> entry in frequencies.entries)
      ...List<String>.filled(entry.value, entry.key),
  ]);
}
