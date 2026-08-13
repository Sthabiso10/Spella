import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:spella/core/data/word_bank.dart';

/// Number of letters in the alphabet the game plays with.
const int _alphabetSize = 26;
const int _codeUnitA = 97;

/// Asset holding the full validation word list.
const String _wordListAsset = 'assets/dictionary/words_en.txt';

/// A dictionary word plus its pre-computed letter histogram, so checking
/// whether a rack can spell it is a fixed 26-step comparison rather than a
/// string search.
class _IndexedWord {
  _IndexedWord(this.word) : counts = _histogram(word);

  final String word;
  final Uint8List counts;

  int get length => word.length;
}

Uint8List _histogram(String word) {
  final Uint8List counts = Uint8List(_alphabetSize);
  for (int i = 0; i < word.length; i++) {
    final int index = word.codeUnitAt(i) - _codeUnitA;
    if (index >= 0 && index < _alphabetSize) counts[index]++;
  }
  return counts;
}

/// Parses the raw asset into a word set. Top level so it can run in an
/// isolate via [compute], keeping the 300k word parse off the UI thread.
Set<String> _parseWordList(String raw) {
  final Set<String> words = <String>{};

  for (final String line in raw.split('\n')) {
    final String word = line.trim();
    if (word.length >= 2) words.add(word);
  }
  return words;
}

/// The game's dictionary, in two tiers.
///
/// **Validation** runs against a large bundled list (~300k words), so players
/// are rarely told a real word is not a word.
///
/// **Generation** - racks, hints, the best-word reveal and the bot's move -
/// runs against a smaller curated list of words people actually know. Those
/// features exist to teach and to feel fair, and a bot that plays "aalii" does
/// neither.
///
/// Both are local on purpose. The engine's core question is "every word
/// spellable from these letters", which no dictionary API can answer, and
/// rounds are timed so lookups cannot depend on the network.
class DictionaryService {
  /// Words accepted as valid plays.
  final Set<String> _validWords = <String>{};

  /// Curated words, indexed for fast letter-set enumeration.
  final List<_IndexedWord> _commonWords = <_IndexedWord>[];

  final List<String> _seeds = <String>[];

  bool _isReady = false;

  /// `true` once [initialise] has completed.
  bool get isReady => _isReady;

  /// Number of words that will be accepted as a play.
  int get wordCount => _validWords.length;

  /// Number of words the generator and bot draw on.
  int get commonWordCount => _commonWords.length;

  /// Words eligible to seed a rack, guaranteeing every deal is solvable.
  List<String> get seedWords => List<String>.unmodifiable(_seeds);

  /// Loads both tiers. Safe to call more than once - later calls are no-ops.
  ///
  /// If the asset cannot be read the curated list still stands in, so a broken
  /// bundle degrades the dictionary rather than breaking the game.
  Future<void> initialise() async {
    if (_isReady) return;

    for (final String word in _tokenise(WordBank.words)) {
      if (_validWords.add(word)) _commonWords.add(_IndexedWord(word));
    }
    for (final String word in _tokenise(WordBank.seeds)) {
      // A seed has to be a word the generator itself knows.
      if (_validWords.contains(word) && word.length >= 4) _seeds.add(word);
    }

    _validWords.addAll(await _loadBundledWords());
    _isReady = true;
  }

  /// `true` when [word] is a real word.
  bool isValidWord(String word) => _validWords.contains(word.toLowerCase());

  /// Every *common* word that can be spelled using [letters], longest first.
  ///
  /// Deliberately narrower than [isValidWord]: this drives hints, the bot and
  /// the best-word reveal, which should surface words worth learning.
  List<String> solutionsFor(Iterable<String> letters, {int minLength = 3, int? limit}) {
    final Uint8List available = _countsOf(letters);
    final int maxLength = letters.length;
    final List<String> matches = <String>[];

    for (final _IndexedWord entry in _commonWords) {
      if (entry.length < minLength || entry.length > maxLength) continue;
      if (_canSpell(entry.counts, available)) matches.add(entry.word);
    }

    matches.sort((String a, String b) => b.length.compareTo(a.length));
    if (limit != null && matches.length > limit) {
      return matches.sublist(0, limit);
    }
    return matches;
  }

  /// `true` when [word] is valid *and* spellable from [letters].
  bool canPlay(String word, Iterable<String> letters) {
    final String normalised = word.toLowerCase();
    if (!isValidWord(normalised)) return false;

    return _canSpell(_histogram(normalised), _countsOf(letters));
  }

  Future<Set<String>> _loadBundledWords() async {
    try {
      final String raw = await rootBundle.loadString(_wordListAsset);
      return compute(_parseWordList, raw);
    } on Object catch (error) {
      debugPrint(
        'Spella: bundled word list unavailable ($error). '
        'Falling back to the curated list.',
      );
      return const <String>{};
    }
  }

  Uint8List _countsOf(Iterable<String> letters) {
    final Uint8List counts = Uint8List(_alphabetSize);
    for (final String letter in letters) {
      final int index = letter.toLowerCase().codeUnitAt(0) - _codeUnitA;
      if (index >= 0 && index < _alphabetSize) counts[index]++;
    }
    return counts;
  }

  static bool _canSpell(Uint8List required, Uint8List available) {
    for (int i = 0; i < _alphabetSize; i++) {
      if (required[i] > available[i]) return false;
    }
    return true;
  }

  static Iterable<String> _tokenise(String raw) sync* {
    for (final String token in raw.split(RegExp(r'\s+'))) {
      final String word = token.trim().toLowerCase();
      if (word.length < 2) continue;
      if (!RegExp(r'^[a-z]+$').hasMatch(word)) continue;
      yield word;
    }
  }
}
