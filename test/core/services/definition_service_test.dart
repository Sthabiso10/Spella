import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spella/core/models/word_definition.dart';
import 'package:spella/core/services/definition_service.dart';

/// A trimmed copy of a real freedictionaryapi.com payload.
const String _quipResponse = '''
{
  "word": "quip",
  "entries": [
    {
      "language": {"code": "en", "name": "English"},
      "partOfSpeech": "noun",
      "pronunciations": [
        {"type": "other", "text": "ignore me"},
        {"type": "ipa", "text": "/kwɪp/"}
      ],
      "senses": [
        {"definition": "", "examples": []},
        {
          "definition": "A smart, sarcastic turn or jest; a taunt.",
          "examples": ["She fired off a quip."]
        }
      ]
    }
  ],
  "source": {
    "url": "https://en.wiktionary.org",
    "license": {"name": "CC BY-SA 4.0"}
  }
}
''';

/// What the API returns for a word it has no entry for: 200, empty entries.
const String _unknownResponse = '''
{"word": "blorptak", "entries": [], "source": {"url": "https://en.wiktionary.org"}}
''';

/// Responds with [body] as raw UTF-8 bytes and *no* charset header, proving
/// the service decodes correctly without being told how.
MockClient _respondWith(String body, {int status = 200}) => MockClient(
  (http.Request request) async => http.Response.bytes(utf8.encode(body), status),
);

void main() {
  group('FreeDictionaryApiService', () {
    test('parses word, definition, part of speech and IPA', () async {
      final FreeDictionaryApiService service = FreeDictionaryApiService(
        client: _respondWith(_quipResponse),
      );

      final WordDefinition? result = await service.lookup('quip');

      expect(result, isNotNull);
      expect(result!.word, 'quip');
      expect(result.definition, 'A smart, sarcastic turn or jest; a taunt.');
      expect(result.partOfSpeech, 'noun');
      expect(result.pronunciation, '/kwɪp/');
      expect(result.example, 'She fired off a quip.');
    });

    test('carries the attribution the licence requires', () async {
      final FreeDictionaryApiService service = FreeDictionaryApiService(
        client: _respondWith(_quipResponse),
      );

      final WordDefinition? result = await service.lookup('quip');

      expect(result!.sourceName, 'Wiktionary');
      expect(result.licenseName, 'CC BY-SA 4.0');
      expect(result.attribution, 'Wiktionary - CC BY-SA 4.0');
    });

    test('skips senses that have no definition text', () async {
      final FreeDictionaryApiService service = FreeDictionaryApiService(
        client: _respondWith(_quipResponse),
      );

      // The payload's first sense is empty; the second is the real one.
      expect((await service.lookup('quip'))!.definition, isNotEmpty);
    });

    test('returns null for a word with no entry', () async {
      final FreeDictionaryApiService service = FreeDictionaryApiService(
        client: _respondWith(_unknownResponse),
      );

      expect(await service.lookup('blorptak'), isNull);
    });

    test('returns null rather than throwing when the request fails', () async {
      final FreeDictionaryApiService service = FreeDictionaryApiService(
        client: MockClient(
          (http.Request request) async => throw const SocketExceptionStub(),
        ),
      );

      expect(await service.lookup('quip'), isNull);
    });

    test('returns null on a non-200 response', () async {
      final FreeDictionaryApiService service = FreeDictionaryApiService(
        client: _respondWith('gateway blew up', status: 502),
      );

      expect(await service.lookup('quip'), isNull);
    });

    test('returns null on a malformed payload', () async {
      final FreeDictionaryApiService service = FreeDictionaryApiService(
        client: _respondWith('not json at all'),
      );

      expect(await service.lookup('quip'), isNull);
    });

    test('gives up rather than hanging when the API stalls', () async {
      final FreeDictionaryApiService service = FreeDictionaryApiService(
        timeout: const Duration(milliseconds: 40),
        client: MockClient((http.Request request) async {
          await Future<void>.delayed(const Duration(seconds: 5));
          return http.Response(_quipResponse, 200);
        }),
      );

      expect(await service.lookup('quip'), isNull);
    });

    test('caches hits so a repeated word is only fetched once', () async {
      int calls = 0;
      final FreeDictionaryApiService service = FreeDictionaryApiService(
        client: MockClient((http.Request request) async {
          calls++;
          return http.Response(_quipResponse, 200);
        }),
      );

      await service.lookup('quip');
      await service.lookup('QUIP');
      await service.lookup('  quip  ');

      expect(calls, 1);
    });

    test('caches misses too, so unknown words are not retried', () async {
      int calls = 0;
      final FreeDictionaryApiService service = FreeDictionaryApiService(
        client: MockClient((http.Request request) async {
          calls++;
          return http.Response(_unknownResponse, 200);
        }),
      );

      await service.lookup('blorptak');
      await service.lookup('blorptak');

      expect(calls, 1);
    });

    test('requests the English entries endpoint for the word', () async {
      late Uri requested;
      final FreeDictionaryApiService service = FreeDictionaryApiService(
        client: MockClient((http.Request request) async {
          requested = request.url;
          return http.Response(_quipResponse, 200);
        }),
      );

      await service.lookup('Quartz');

      expect(requested.host, 'freedictionaryapi.com');
      expect(requested.path, '/api/v1/entries/en/quartz');
    });

    test('ignores an empty word without calling the API', () async {
      int calls = 0;
      final FreeDictionaryApiService service = FreeDictionaryApiService(
        client: MockClient((http.Request request) async {
          calls++;
          return http.Response(_quipResponse, 200);
        }),
      );

      expect(await service.lookup('   '), isNull);
      expect(calls, 0);
    });
  });
}

/// Stand-in for a network failure, so the test does not depend on dart:io.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();

  @override
  String toString() => 'SocketExceptionStub: no connection';
}
