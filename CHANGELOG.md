# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Open-source project documentation: `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`,
  `SECURITY.md`, `TRADEMARK.md` and `THIRD_PARTY_NOTICES.md`.
- GitHub Actions CI running `dart format`, `flutter analyze --fatal-infos` and
  `flutter test` on every push and pull request, plus an Android debug build.
- Issue forms for bug reports and feature requests, and a pull request
  template.
- Dependabot for pub, GitHub Actions and Gradle dependencies.
- Provenance notice for the bundled dictionary asset
  (`assets/dictionary/NOTICE.md`).

### Changed

- Application ID is now `io.github.sthabiso10.spella` on both Android and iOS,
  replacing the `flutter create` default `com.example.spella`. `com.example.*`
  is rejected by Google Play, and an application ID cannot be changed after a
  store release, so it is fixed now rather than never.
- Reformatted `lib/` and `test/` with the Dart 3.7+ formatter, and braced two
  `if` statements the reformat split across lines.

## [1.0.0] — 2026-09-21

First public release.

### Added

- **Five game modes** — Classic (5 rounds / 7 tiles / 45s), Blitz (3 / 6 / 25s),
  Marathon (7 / 9 / 60s), Pass & Play (3 / 7 / 45s) and Daily Challenge
  (modeled in the engine, not yet wired into the mode picker).
- **Pure-Dart rules engine** — scoring, dictionary, rack generation and the bot
  with no `package:flutter` imports, unit-tested without a widget tree.
- **Two-tier dictionary** — ~315k words for validation, a curated list for
  generation, each word stored with a pre-computed 26-slot letter histogram.
  The full parse runs in an isolate via `compute`.
- **Provably optimal best-word search** — pairs sorted letter values against
  sorted slot multipliers instead of searching permutations.
- **Scaling bot** — `BotOpponentService` plays from the same dictionary as the
  player, with strength tracked to the player's level.
- **Power-ups** — Hint, Freeze (+15s) and Swap, charged only when the effect
  actually lands.
- **Pass & Play** — 2–6 players on one device, with the board absent from the
  widget tree during handoff and a three-second count-in per turn. Guests are a
  separate type from players, so party scores can't leak into an account.
- **Progression** — coins, gems and XP, with a shop for avatars.
- **Ranks and Friends** — built against a `SocialService` interface that
  currently returns nothing, rendering real empty states rather than sample
  data.
- **Design system** — dark-first token layer (`AppPalette`, `AppTypography`,
  `AppSpacing`, `AppRadius`, `AppMotion`) with a light theme kept in sync.
- **188 tests** across unit, view model, widget and responsive layers.
- Word definitions in the round recap, sourced from freedictionaryapi.com
  (Wiktionary, CC BY-SA 4.0) and displayed with attribution.
- Lifecycle handling — both view models pause the game when the app
  backgrounds, so a round can't drain away in a pocket.

[Unreleased]: https://github.com/Sthabiso10/Spella/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Sthabiso10/Spella/releases/tag/v1.0.0
