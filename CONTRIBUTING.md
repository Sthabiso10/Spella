# Contributing to Spella

Thanks for taking a look. This is a small enough codebase that a first PR
shouldn't need a guided tour — the sections below are the whole of it.

By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

## Getting set up

```bash
git clone https://github.com/Sthabiso10/Spella.git
cd Spella
flutter pub get
flutter run
```

Requires Flutter with Dart SDK `^3.12.2` (developed against Flutter 3.44.8).
No API keys, no backend, no configuration — the game is fully playable offline
on first run.

```bash
flutter analyze                 # lints (flutter_lints)
flutter test                    # full suite, 188 tests
dart format lib test            # formatting
```

CI runs all three on every pull request, plus a check that `pubspec.lock`
matches what `flutter pub get` actually resolves. Running them locally first is
the fastest way to a green build.

> **If a Dependabot PR fails the lockfile check:** Dependabot resolves pub
> packages without the Flutter SDK's constraints, so it can pin transitive
> packages to versions the SDK then resolves back down. Check the branch out,
> run `flutter pub get`, and commit the corrected `pubspec.lock`.

## Where things go

```
lib/
├── app/           service locator + router
├── core/
│   ├── models/    immutable game state
│   ├── data/      letter values, curated word bank
│   └── services/  the rules: engine, dictionary, scoring, rack generator, bot
└── ui/
    ├── common/    design tokens
    ├── views/     one folder per screen: view + viewmodel + its widgets
    └── widgets/   shared components
```

Three rules carry most of the architecture. See
[Architecture](README.md#architecture) for the reasoning.

1. **`lib/core/` stays pure Dart.** Rules and scoring must not import
   `package:flutter` — that's what keeps them testable without a widget tree.
   A PR that adds a Flutter import under `lib/core/services/` will be asked to
   move the logic.
2. **Decisions live in view models, not the widget tree.** Views are
   declarative; no `setState` scattered through screens, no business logic in
   `build()`.
3. **Anything network-shaped goes behind an interface.** `OpponentService`,
   `PlayerService`, `SocialService` and `DefinitionService` exist so a backend
   can land as a locator change rather than a rewrite. Keep that seam.

## Tests

Engine and view-model changes need tests. UI-only changes usually don't, though
a widget test is welcome.

Determinism is handled by injecting `Random` and `Uuid` into the engine — if
your test needs a specific deal, seed one rather than asserting on luck.

## Pull requests

1. **Fork and branch off `main`** with a descriptive name
   (`fix/rack-shuffle-seed`, `feat/daily-challenge-picker`).
2. **Keep it scoped.** One fix or one feature per PR. Unrelated formatting or
   refactors belong in a separate PR — they make a reviewable change
   unreviewable.
3. **Run `flutter analyze`, `flutter test` and `dart format` before opening.**
4. **Open against `main`** with a short description of what changed and why.
   Screenshots or a screen recording are appreciated for UI changes.

Commits don't need to follow a strict convention, but a present-tense summary
line under ~72 characters (`Fix rack shuffle losing the seed`) is appreciated.

## Good first contributions

The [Roadmap](README.md#roadmap) lists the interfaces already in place for
backend, multiplayer, social and daily-challenge work. Those are the
highest-value places to contribute, because the seams to build against already
exist:

- **Daily Challenge picker** — modeled end-to-end in the engine, just not wired
  into the mode selector.
- **Light theme toggle** — the light theme is already kept in sync; it needs a
  setting to expose it.
- **`SocialService` implementation** — Ranks and Friends are fully built
  against the interface and currently render real empty states.

Issues labelled [`good first issue`][gfi] are the curated version of this list.

[gfi]: https://github.com/Sthabiso10/Spella/labels/good%20first%20issue

## Reporting things

- **Bug or feature idea** — open an [issue][issues]. Reproduction steps for
  bugs, or the problem you're trying to solve for feature ideas, are more
  useful than a proposed implementation.
- **Security vulnerability** — do not open a public issue. See
  [SECURITY.md](SECURITY.md).

[issues]: https://github.com/Sthabiso10/Spella/issues

## Licensing of contributions

Spella is [MIT licensed](LICENSE). Contributions are accepted under the same
licence — there's no CLA to sign.

If your change adds a dependency or bundles third-party data, add it to
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) in the same PR, and make sure
the licence is permissive (MIT, BSD, Apache-2.0, ISC, Unlicense, OFL for
fonts). Copyleft dependencies can't be accepted.
