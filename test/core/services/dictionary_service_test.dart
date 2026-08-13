import 'package:flutter_test/flutter_test.dart';
import 'package:spella/core/services/dictionary_service.dart';

void main() {
  // rootBundle needs the binding up before the word list asset can be read.
  TestWidgetsFlutterBinding.ensureInitialized();

  late DictionaryService dictionary;

  setUpAll(() async {
    dictionary = DictionaryService();
    await dictionary.initialise();
  });

  group('loading', () {
    test('loads the bundled word list', () {
      expect(dictionary.isReady, isTrue);
      expect(dictionary.wordCount, greaterThan(100000));
    });

    test('keeps the curated generation list much smaller', () {
      expect(dictionary.commonWordCount, greaterThan(1000));
      expect(dictionary.commonWordCount, lessThan(dictionary.wordCount));
    });

    test('initialising twice is a no-op', () async {
      final int before = dictionary.wordCount;
      await dictionary.initialise();

      expect(dictionary.wordCount, before);
    });
  });

  group('validation tier', () {
    test('accepts real words and rejects nonsense, ignoring case', () {
      expect(dictionary.isValidWord('planet'), isTrue);
      expect(dictionary.isValidWord('PLANET'), isTrue);
      expect(dictionary.isValidWord('zzzqx'), isFalse);
    });

    test('accepts obscure words the curated list has never heard of', () {
      // These live only in the bundled list. Players should not be told a real
      // word is not a word.
      for (final String word in <String>['aalii', 'syzygy', 'quixotry', 'phaeton']) {
        expect(dictionary.isValidWord(word), isTrue, reason: word);
      }
    });

    test('respects the letter count, not just the letter set', () {
      // Only one "l" available, so "hello" is out of reach.
      expect(dictionary.canPlay('hello', 'helo'.split('')), isFalse);
      expect(dictionary.canPlay('hello', 'hellox'.split('')), isTrue);
    });

    test('an obscure word is playable when the rack covers it', () {
      expect(dictionary.canPlay('syzygy', 'syzygy'.split('')), isTrue);
    });
  });

  group('generation tier', () {
    test('finds only words spellable from the given letters', () {
      final List<String> solutions = dictionary.solutionsFor('planet'.split(''));

      expect(solutions, contains('plane'));
      expect(solutions, contains('plant'));
      expect(solutions, isNot(contains('planets')));
    });

    test('never surfaces obscure words to hints, bots or reveals', () {
      // "aalii" is spellable from these letters and is a valid play, but it is
      // not the kind of word the game should teach or the bot should play.
      final List<String> solutions = dictionary.solutionsFor('aaliix'.split(''));

      expect(dictionary.isValidWord('aalii'), isTrue);
      expect(solutions, isNot(contains('aalii')));
    });

    test('honours the minimum length filter', () {
      final List<String> solutions = dictionary.solutionsFor(
        'planet'.split(''),
        minLength: 5,
      );

      expect(solutions.every((String word) => word.length >= 5), isTrue);
    });

    test('caps results when a limit is given', () {
      final List<String> solutions = dictionary.solutionsFor(
        'planets'.split(''),
        limit: 5,
      );

      expect(solutions, hasLength(lessThanOrEqualTo(5)));
    });

    test('every seed word is itself a valid play', () {
      expect(dictionary.seedWords, isNotEmpty);
      for (final String seed in dictionary.seedWords.take(200)) {
        expect(dictionary.isValidWord(seed), isTrue, reason: 'seed "$seed"');
      }
    });
  });
}
