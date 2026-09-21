# Third-party notices

Spella itself is released under the [MIT License](LICENSE). It bundles and
depends on third-party work, listed here with the licence each one carries.

## Bundled data

### English word list — `assets/dictionary/words_en.txt`

The ~315,000-word validation dictionary shipped with the app is a filtered
subset of [`words_alpha.txt`][dwyl] from **dwyl/english-words**, released under
the [Unlicense][unlicense] (public domain dedication). No attribution is
required; it is recorded here so the provenance of the data is auditable.

Spella's copy drops entries shorter than two letters and any line containing a
non-`a–z` character. Every word in the bundled file is present in the upstream
list.

See [`assets/dictionary/NOTICE.md`](assets/dictionary/NOTICE.md) for the
regeneration steps.

[dwyl]: https://github.com/dwyl/english-words
[unlicense]: https://unlicense.org/

## Network services used at runtime

### Word definitions — freedictionaryapi.com

The round recap shows a definition fetched from
[freedictionaryapi.com](https://freedictionaryapi.com), which serves
**Wiktionary** content under [CC BY-SA 4.0][ccbysa]. Definitions are displayed
with that attribution in the app and are never redistributed as part of this
repository — no Wiktionary text is stored here.

Definition lookups are enrichment only. Every failure path returns `null`, so
the game is fully playable with the network off.

[ccbysa]: https://creativecommons.org/licenses/by-sa/4.0/

### Fonts — Plus Jakarta Sans

The UI uses **Plus Jakarta Sans**, licensed under the
[SIL Open Font License 1.1][ofl]. It is not committed to this repository; the
`google_fonts` package fetches it from `fonts.google.com` on first run and
caches it on device.

[ofl]: https://openfontlicense.org/

> **Network summary.** Spella contacts exactly two hosts — `fonts.google.com`
> (font download, via `google_fonts`) and `freedictionaryapi.com` (definition
> lookup). It has no analytics, no telemetry, no ads and no accounts, and it
> transmits no player data. The Android manifest requests `INTERNET` and
> nothing else.

## Dart and Flutter dependencies

Versions as resolved in [`pubspec.lock`](pubspec.lock).

| Package | Version | Licence |
|---|---|---|
| [`flutter`](https://flutter.dev) (SDK) | — | BSD-3-Clause |
| [`cupertino_icons`](https://pub.dev/packages/cupertino_icons) | 1.0.9 | MIT |
| [`http`](https://pub.dev/packages/http) | 1.6.0 | BSD-3-Clause |
| [`google_fonts`](https://pub.dev/packages/google_fonts) | 6.3.3 | BSD-3-Clause |
| [`uuid`](https://pub.dev/packages/uuid) | 4.6.0 | MIT |
| [`get_it`](https://pub.dev/packages/get_it) | 7.7.0 | MIT |
| [`stacked`](https://pub.dev/packages/stacked) | 3.4.3 | MIT |
| [`stacked_services`](https://pub.dev/packages/stacked_services) | 1.6.0 | MIT |
| [`flutter_lints`](https://pub.dev/packages/flutter_lints) (dev) | 6.0.0 | BSD-3-Clause |
| [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons) (dev) | 0.14.4 | MIT |

All of the above are permissive licences compatible with MIT redistribution.
None is copyleft, and none imposes a source-disclosure obligation on Spella.

To regenerate the full transitive licence set, including every indirect
dependency:

```bash
flutter pub deps --style=compact
```

## Branding

The Spella name, logo and app icon in [`assets/branding/`](assets/branding/)
are **not** covered by the MIT licence. They remain the author's marks. You may
fork, modify and redistribute the code under MIT, but please ship your fork
under its own name and icon rather than presenting it as Spella. See
[TRADEMARK.md](TRADEMARK.md).
