import 'dart:math';

import 'package:spella/core/data/letter_data.dart';
import 'package:spella/core/models/game_mode.dart';
import 'package:spella/core/models/letter_tile.dart';
import 'package:spella/core/models/slot_bonus.dart';
import 'package:spella/core/services/dictionary_service.dart';

/// A dealt rack: the tiles plus the bonus layout of the slots they play into.
class RackDraw {
  const RackDraw({required this.tiles, required this.bonuses});

  final List<LetterTile> tiles;
  final List<SlotBonus> bonuses;

  /// The raw letters, handy for dictionary lookups.
  List<String> get letters =>
      tiles.map((LetterTile tile) => tile.letter).toList(growable: false);
}

/// Deals racks that are guaranteed to be playable.
///
/// Every rack is built around a real dictionary word, then padded with letters
/// drawn from an English frequency table. That rules out the dead rack of
/// seven consonants that makes word games feel unfair.
class RackGeneratorService {
  RackGeneratorService(this._dictionary, {Random? random}) : _random = random ?? Random();

  final DictionaryService _dictionary;
  final Random _random;

  static const String _vowels = 'aeiou';

  /// Minimum vowels a rack must contain, scaled to its size.
  static int _minVowelsFor(int rackSize) => (rackSize / 3).floor().clamp(1, 4);

  /// Deals a rack sized and laid out for [mode].
  RackDraw deal(GameMode mode) {
    final List<String> letters = _drawLetters(mode.rackSize);
    return RackDraw(
      tiles: <LetterTile>[
        for (int i = 0; i < letters.length; i++) LetterTile.of(letters[i], index: i),
      ],
      bonuses: _layOutBonuses(mode),
    );
  }

  /// Replaces [count] letters in an existing rack, preserving the rest. Backs
  /// the swap power-up.
  List<LetterTile> redraw(List<LetterTile> keep, {required int count}) {
    final List<LetterTile> replacements = <LetterTile>[
      for (int i = 0; i < count; i++)
        LetterTile.of(_randomLetter(), index: keep.length + i + _random.nextInt(1000)),
    ];
    return <LetterTile>[...keep, ...replacements]..shuffle(_random);
  }

  List<String> _drawLetters(int rackSize) {
    final List<String> letters = <String>[..._seedFor(rackSize).split('')];

    while (letters.length < rackSize) {
      letters.add(_randomLetter());
    }
    if (letters.length > rackSize) {
      letters.removeRange(rackSize, letters.length);
    }

    _ensureVowels(letters);
    return letters..shuffle(_random);
  }

  /// Picks a seed word close to, but no longer than, the rack size so there is
  /// room for a couple of wildcard letters.
  String _seedFor(int rackSize) {
    final List<String> seeds = _dictionary.seedWords;
    if (seeds.isEmpty) {
      return List<String>.generate(rackSize, (_) => _randomLetter()).join();
    }

    final int maxLength = rackSize;
    final int minLength = (rackSize - 2).clamp(4, rackSize);

    // A bounded number of attempts keeps this O(1) even if the seed list has
    // few words of the requested length.
    for (int attempt = 0; attempt < 40; attempt++) {
      final String candidate = seeds[_random.nextInt(seeds.length)];
      if (candidate.length >= minLength && candidate.length <= maxLength) {
        return candidate;
      }
    }

    final List<String> fallback = seeds
        .where((String word) => word.length <= maxLength)
        .toList(growable: false);
    return fallback.isEmpty
        ? seeds.first.substring(0, min(maxLength, seeds.first.length))
        : fallback[_random.nextInt(fallback.length)];
  }

  /// Swaps consonants out for vowels until the rack is comfortably playable.
  void _ensureVowels(List<String> letters) {
    final int required = _minVowelsFor(letters.length);

    int vowelCount() => letters.where((String letter) => _vowels.contains(letter)).length;

    while (vowelCount() < required) {
      final int index = letters.indexWhere((String letter) => !_vowels.contains(letter));
      if (index == -1) return;
      letters[index] = _vowels[_random.nextInt(_vowels.length)];
    }
  }

  String _randomLetter() =>
      LetterData.weightedAlphabet[_random.nextInt(LetterData.weightedAlphabet.length)];

  /// Places bonuses on the board, biased towards the earlier slots that short
  /// words can actually reach, and capped at one word multiplier per round.
  List<SlotBonus> _layOutBonuses(GameMode mode) {
    final List<SlotBonus> layout = List<SlotBonus>.filled(
      mode.rackSize,
      SlotBonus.none,
      growable: false,
    );

    // Weighted pool: slot 0 appears rackSize times, the last slot once.
    final List<int> pool = <int>[
      for (int slot = 0; slot < mode.rackSize; slot++)
        ...List<int>.filled(mode.rackSize - slot, slot),
    ];

    bool wordBonusPlaced = false;
    int placed = 0;

    while (placed < mode.bonusSlots && pool.isNotEmpty) {
      final int slot = pool[_random.nextInt(pool.length)];
      if (layout[slot] != SlotBonus.none) {
        pool.removeWhere((int candidate) => candidate == slot);
        continue;
      }

      final SlotBonus bonus = _randomBonus(allowWordBonus: !wordBonusPlaced);
      if (bonus.isWordBonus) wordBonusPlaced = true;
      layout[slot] = bonus;
      placed++;
    }

    return layout;
  }

  SlotBonus _randomBonus({required bool allowWordBonus}) {
    final int roll = _random.nextInt(100);
    if (roll < 40) return SlotBonus.doubleLetter;
    if (roll < 65) return SlotBonus.tripleLetter;
    if (!allowWordBonus) return SlotBonus.doubleLetter;
    return roll < 92 ? SlotBonus.doubleWord : SlotBonus.tripleWord;
  }
}
