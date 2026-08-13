import 'package:flutter_test/flutter_test.dart';
import 'package:spella/core/models/letter_tile.dart';
import 'package:spella/core/models/round_board.dart';
import 'package:spella/core/models/slot_bonus.dart';

/// Builds a board from [letters] with no bonus slots unless [bonuses] is given.
RoundBoard boardOf(String letters, {List<SlotBonus>? bonuses}) {
  final List<LetterTile> rack = <LetterTile>[
    for (int i = 0; i < letters.length; i++) LetterTile.of(letters[i], index: i),
  ];
  return RoundBoard(
    rack: rack,
    bonuses: bonuses ?? List<SlotBonus>.filled(letters.length, SlotBonus.none),
  );
}

void main() {
  group('RoundBoard', () {
    test('places tiles into the word in tap order', () {
      final RoundBoard board = boardOf('cat');

      board
        ..place(board.rack[2])
        ..place(board.rack[0])
        ..place(board.rack[1]);

      expect(board.word, 'tca');
    });

    test('refuses to place a tile that is already in the word', () {
      final RoundBoard board = boardOf('cat');
      final LetterTile tile = board.rack.first;

      expect(board.place(tile), isTrue);
      expect(board.place(tile), isFalse);
      expect(board.word, 'c');
    });

    test('closes the gap when a tile is removed from the middle', () {
      final RoundBoard board = boardOf('cat');
      for (final LetterTile tile in board.rack) {
        board.place(tile);
      }

      board.removeAt(1);

      expect(board.word, 'ct');
    });

    test('shuffling the rack leaves the word intact', () {
      final RoundBoard board = boardOf('spella');
      board.place(board.rack.first);
      final String before = board.word;

      board.shuffleRack();

      expect(board.word, before);
      expect(board.rack, hasLength(6));
    });

    test('spell picks matching tiles, including duplicates', () {
      final RoundBoard board = boardOf('lleorh');

      expect(board.spell('hello'), isTrue);
      expect(board.word, 'hello');
    });

    test('spell fails when the rack cannot cover the word', () {
      final RoundBoard board = boardOf('helo');

      expect(board.spell('hello'), isFalse);
      expect(board.word, isEmpty);
    });

    test('is full once every slot is used', () {
      final RoundBoard board = boardOf('cat');
      for (final LetterTile tile in board.rack) {
        board.place(tile);
      }

      expect(board.isFull, isTrue);
      expect(board.place(LetterTile.of('s', index: 99)), isFalse);
    });
  });
}
