/// What a played word actually means.
///
/// Shown after a round so a match teaches you something, not just who scored
/// more. Every field except [word] is optional because dictionary coverage is
/// uneven and a missing pronunciation must never block the UI.
class WordDefinition {
  const WordDefinition({
    required this.word,
    required this.definition,
    this.partOfSpeech,
    this.pronunciation,
    this.example,
    this.sourceName,
    this.sourceUrl,
    this.licenseName,
  });

  final String word;

  /// The primary sense, trimmed to something readable at a glance.
  final String definition;

  /// e.g. `noun`, `verb`.
  final String? partOfSpeech;

  /// IPA, e.g. `/kwɪp/`.
  final String? pronunciation;

  /// A usage example, when the source has one.
  final String? example;

  /// Where the entry came from, e.g. `Wiktionary`.
  final String? sourceName;

  final String? sourceUrl;

  /// Licence the entry is published under. The source requires attribution,
  /// so this is displayed alongside the definition.
  final String? licenseName;

  String get display => word.toUpperCase();

  /// Attribution line, e.g. `Wiktionary - CC BY-SA 4.0`.
  String? get attribution {
    if (sourceName == null && licenseName == null) return null;
    return <String?>[sourceName, licenseName].whereType<String>().join(' - ');
  }
}
