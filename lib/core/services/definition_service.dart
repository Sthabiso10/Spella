import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:spella/core/models/word_definition.dart';

/// Looks up what a word means.
///
/// Strictly an enrichment: the game never waits on this and never fails
/// because of it. Every path returns `null` rather than throwing, so a flat
/// battery, an airplane-mode flight or an API outage costs you a definition
/// and nothing else.
abstract class DefinitionService {
  /// The meaning of [word], or `null` when it cannot be resolved.
  Future<WordDefinition?> lookup(String word);
}

/// [DefinitionService] backed by freedictionaryapi.com, which serves
/// Wiktionary entries under CC BY-SA 4.0.
///
/// The API answers `200` with an empty `entries` list for unknown words, so a
/// missing entry is cleanly distinguishable from a failed request - which is
/// why this is safe to consult and a status-code-only API would not be.
class FreeDictionaryApiService implements DefinitionService {
  FreeDictionaryApiService({http.Client? client, this.timeout = _defaultTimeout})
    : _client = client ?? http.Client();

  static const String _host = 'freedictionaryapi.com';
  static const String _basePath = '/api/v1/entries/en';
  static const Duration _defaultTimeout = Duration(seconds: 6);

  /// Cap on cached entries, so a long session cannot grow without bound.
  static const int _maxCacheEntries = 200;

  final http.Client _client;

  /// How long to wait before giving up on a lookup.
  final Duration timeout;

  /// Results already fetched this session, including misses (stored as `null`)
  /// so a word with no entry is not requested over and over.
  final Map<String, WordDefinition?> _cache = <String, WordDefinition?>{};

  @override
  Future<WordDefinition?> lookup(String word) async {
    final String normalised = word.trim().toLowerCase();
    if (normalised.isEmpty) return null;
    if (_cache.containsKey(normalised)) return _cache[normalised];

    final WordDefinition? definition = await _fetch(normalised);
    _remember(normalised, definition);
    return definition;
  }

  Future<WordDefinition?> _fetch(String word) async {
    try {
      final Uri uri = Uri.https(_host, '$_basePath/$word');
      final http.Response response = await _client.get(uri).timeout(timeout);

      if (response.statusCode != 200) return null;

      // Decode explicitly rather than via `response.body`, which falls back to
      // latin-1 when the server omits a charset and would mangle the IPA
      // pronunciations. JSON is UTF-8 by spec.
      return _parse(word, utf8.decode(response.bodyBytes, allowMalformed: true));
    } on Object catch (error) {
      // Network, timeout, or malformed payload - all equally non-fatal.
      debugPrint('Spella: definition lookup for "$word" failed ($error)');
      return null;
    }
  }

  /// Pulls the first usable sense out of the payload.
  ///
  /// Tolerant by design: the shape is only partly guaranteed, so every step
  /// falls back rather than throwing.
  WordDefinition? _parse(String word, String body) {
    final Object? decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return null;

    final List<dynamic> entries =
        decoded['entries'] as List<dynamic>? ?? const <dynamic>[];
    if (entries.isEmpty) return null;

    for (final dynamic rawEntry in entries) {
      if (rawEntry is! Map<String, dynamic>) continue;

      final Map<String, dynamic>? sense = _firstSenseWithDefinition(rawEntry);
      if (sense == null) continue;

      return WordDefinition(
        word: word,
        definition: (sense['definition'] as String).trim(),
        partOfSpeech: rawEntry['partOfSpeech'] as String?,
        pronunciation: _firstPronunciation(rawEntry),
        example: _firstExample(sense),
        sourceName: _sourceName(decoded),
        sourceUrl: _sourceUrl(decoded),
        licenseName: _licenseName(decoded),
      );
    }
    return null;
  }

  Map<String, dynamic>? _firstSenseWithDefinition(Map<String, dynamic> entry) {
    final List<dynamic> senses = entry['senses'] as List<dynamic>? ?? const <dynamic>[];

    for (final dynamic sense in senses) {
      if (sense is! Map<String, dynamic>) continue;

      final Object? definition = sense['definition'];
      if (definition is String && definition.trim().isNotEmpty) return sense;
    }
    return null;
  }

  String? _firstPronunciation(Map<String, dynamic> entry) {
    final List<dynamic> pronunciations =
        entry['pronunciations'] as List<dynamic>? ?? const <dynamic>[];

    for (final dynamic pronunciation in pronunciations) {
      if (pronunciation is! Map<String, dynamic>) continue;
      if (pronunciation['type'] != 'ipa') continue;

      final Object? text = pronunciation['text'];
      if (text is String && text.trim().isNotEmpty) return text.trim();
    }
    return null;
  }

  String? _firstExample(Map<String, dynamic> sense) {
    final List<dynamic> examples =
        sense['examples'] as List<dynamic>? ?? const <dynamic>[];

    for (final dynamic example in examples) {
      if (example is String && example.trim().isNotEmpty) return example.trim();
    }
    return null;
  }

  String? _sourceName(Map<String, dynamic> payload) {
    final String? url = _sourceUrl(payload);
    if (url == null) return null;

    // "https://en.wiktionary.org" -> "Wiktionary".
    return url.contains('wiktionary') ? 'Wiktionary' : Uri.tryParse(url)?.host;
  }

  String? _sourceUrl(Map<String, dynamic> payload) {
    final Object? source = payload['source'];
    if (source is! Map<String, dynamic>) return null;

    return source['url'] as String?;
  }

  String? _licenseName(Map<String, dynamic> payload) {
    final Object? source = payload['source'];
    if (source is! Map<String, dynamic>) return null;

    final Object? license = source['license'];
    if (license is! Map<String, dynamic>) return null;

    return license['name'] as String?;
  }

  void _remember(String word, WordDefinition? definition) {
    if (_cache.length >= _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[word] = definition;
  }
}
