<div align="center">

<img src="assets/branding/spella_logo_horizontal_readme.png" alt="Spella" width="380">

A fast-paced word game built in Flutter. Players get a rack of letters and a
countdown, and race to build the highest-scoring word they can see.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-3DDC84)](#running-it)
[![Tests](https://img.shields.io/badge/Tests-188%20passing-2ea44f)](#testing)
[![Architecture](https://img.shields.io/badge/Architecture-MVVM%20%2F%20Stacked-6f42c1)](#architecture)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

Spella is a portfolio project written to production standards: a layered
architecture, a pure-Dart rules engine with no Flutter imports, dependency
injection behind swappable interfaces, and 188 passing tests.

## Why this repo is worth a look

- **Engine has zero Flutter imports.** The rules scoring, dictionary,
  rack generation, the bot are pure Dart, unit-tested without a widget tree.
- **188 tests**, ~2,900 lines of test against 13,600 lines of app, covering
  unit, view model, widget and responsive layers.
- **Everything that varies is data, not code.** Game modes live in a single
  enum; adding one never touches the engine or the UI.
- **Built for a backend that doesn't exist yet.** Every network-shaped concern
  sits behind an interface (`OpponentService`, `PlayerService`,
  `SocialService`) so swapping in real multiplayer is a locator change, not a
  rewrite.

## Contents

- [The game](#the-game)
- [How to play](#how-to-play)
- [Architecture](#architecture)
- [Design](#design)
- [Testing](#testing)
- [Running it](#running-it)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## The game

| | |
|---|---|
| **Rack** | Each round deals a rack of letters, guaranteed to contain at least one strong word. |
| **Board** | Word slots carry bonus multipliers (`2L`, `3L`, `x2`, `x3`), so *where* a letter goes matters as much as *which* letter. |
| **Clock** | Every round is timed. Finishing early earns a speed bonus, capped so a 60-second mode can't out-earn a 25-second one. |
| **Scoring** | Letter values × slot bonuses × word multiplier, plus a length bonus past four letters and 25 points for using the whole rack. |
| **Power-ups** | Spend coins on **Hint**, **Freeze** (+15s) or **Swap**. Charged only when the effect actually lands. |

### Modes

| Mode | Rounds | Rack | Clock |
|---|---|---|---|
| **Classic** | 5 | 7 tiles | 45s |
| **Blitz** | 3 | 6 tiles | 25s |
| **Marathon** | 7 | 9 tiles | 60s |
| **Daily Challenge**¹ | 1 | 8 tiles | 90s |
| **Pass & Play** | 3 | 7 tiles | 45s |

Everything that varies between modes lives in a single enum, so adding a mode
never means touching the engine or the UI.

**Pass & Play** is a party mode: 2–6 people share one device and take turns on
the same rack. Guests are a separate type from real players, which is what
stops party scores leaking into anyone's account. Each turn is counted in,
covers the board during the handoff so nobody reads the rack over your
shoulder, and ends on your own result before the device moves on.

¹ Modeled end-to-end in the engine but not yet wired into the mode picker —
see [Roadmap](#roadmap).

---

## How to play

**Start a match.** From Home, tap **Play** for an instant Classic match
against the bot, or pick a mode from the grid Classic, Blitz and Marathon
start right away against the bot; **Pass & Play** goes to a roster screen
first, where the host adds 2–6 players by name before the game deals.

**Build a word.** Tap rack tiles in the order you want them each tap fills
the next open slot on the board; tapping a placed tile sends it back to the
rack. The status panel above updates live as you build, so you always know
whether the current word is valid and what it's worth before you commit.
**Play Word** submits it, **Clear** empties the board, and shuffle reorders
the rack if a fresh look helps. Running out the clock auto-submits a valid
word left on the board, or passes the round.

**Spend a power-up.** Once per round, pay coins to reveal a **Hint** (spells
out a strong word for you), buy 15 seconds with **Freeze**, or **Swap** your
unused tiles for a fresh draw. A power-up only charges you if it actually
changes something tapping Swap with every tile already placed costs
nothing.

**See the round out.** Submitting cuts to the opponent "thinking," then a
recap: both words side by side with their scoring breakdown, the best word
that rack could have made, and a definition for whichever word is worth
showing.

**Pass & Play handoff.** Between turns the board is hidden entirely — not
just visually, it's absent from the widget tree behind a screen naming the
next player, who confirms they're ready and gets a three-second count-in
before the clock starts, so nobody is dropped onto a timer already running.
Each player sees their own result before the phone moves on.

**After the match.** Results show the final score and each side's best word,
plus outside Pass & Play, which pays out nothing so a guest's turn can't
land in the host's account coins, gems and XP earned. Coins buy power-ups
mid-match; gems unlock avatars in the **Shop**. **Ranks** is a leaderboard and
**Friends** covers search, challenges and activity; both are fully built
against a `SocialService` interface that currently returns nothing, so they
render real empty states rather than fake sample data until a backend is
live.

---

## Architecture

```
lib/
├── app/           service locator + router
├── core/
│   ├── models/    immutable game state (match, round, board, play, score)
│   ├── data/      letter values, curated word bank
│   └── services/  the rules: engine, dictionary, scoring, rack generator, bot
└── ui/
    ├── common/    palette, typography, spacing, motion — the design system
    ├── views/     one folder per screen: view + viewmodel + its widgets
    └── widgets/   shared components
```

**MVVM via Stacked.** Views are dumb and declarative; every decision lives in a
view model. No business logic in the widget tree, no `setState` scattered
through screens.

**A rules engine with no Flutter in it.** `GameEngineService` holds no state —
you pass a match in and get an updated one back. `ScoringService` is pure
functions. Both are trivially unit-testable and safe to reuse across screens,
and neither imports `package:flutter`.

**Interfaces over implementations.** Anything that will eventually talk to a
network is registered against an abstract type — `OpponentService`,
`PlayerService`, `SocialService`, `DefinitionService`. Today they resolve to a
local bot, in-memory progression and an empty social graph. When the backend
lands, the right-hand side of the locator changes and no view model does.

**A hand-written locator.** [`app.locator.dart`](lib/app/app.locator.dart) is
deliberately not generated, so the whole dependency graph is readable in one
screen.

### Some decisions worth calling out

**A two-tier dictionary.** Validation runs against ~315k words so players are
rarely told a real word isn't one. Generation racks, hints, the bot's move
runs against a smaller curated list, because a bot that plays `aalii` teaches
nothing and feels unfair. Every word is stored with a pre-computed 26-slot
letter histogram, so "can this rack spell this word?" is a fixed-length
comparison rather than a string search. The 300k-word parse runs in an isolate
via `compute` to keep it off the UI thread.

Both tiers are local on purpose: the engine's core question is *every word
spellable from these letters*, which no dictionary API can answer, and rounds
are timed so lookups can't depend on the network.

**A provably optimal best-word search.** Because the word multiplier applies
regardless of tile order, the best arrangement is just the highest-value
letters on the biggest letter multipliers so pairing two sorted lists is
optimal, and no permutation search is needed.

**A bot that scales with you.** `BotOpponentService` plays from the same
dictionary the player does, and its strength tracks the player's level, so it
stays a fair test as they improve rather than becoming a wall or a pushover.
It implements the same `OpponentService` interface real-time multiplayer will.

**One clock, extracted.** Both game modes ran the same timer, and a countdown
that can be paused, extended by a power-up and interrupted by a phone call has
more edge cases than a game screen should carry inline.
[`RoundClock`](lib/core/services/round_clock.dart) owns them, with the
invariant that `remaining` never exceeds `allotted` so a frozen round reads
as a longer round, not one that has somehow gone past full.

**Interruptions don't cost you the round.** Both view models observe the app
lifecycle and hold the game when it backgrounds, so a round can't drain away
while the phone is in a pocket.

---

## Design

<img src="assets/branding/spella_icon.png" alt="Spella icon" width="72" align="right">

Dark-first, built on a token layer rather than ad-hoc values: `AppPalette`,
`AppTypography`, `AppSpacing`, `AppRadius`, `AppMotion`. A light theme is kept
in sync so it can be offered as a setting later.

The UI treats feedback as a first-class feature. Scores count up rather than
jumping, because a number changing between frames is information the player can
miss. Tiles are keyed by identity and positioned by index rather than laid out
in a `Wrap`, so pulling a letter out of the middle of a word makes the rest
walk left into the gap instead of teleporting. Layouts are tested at the
largest system text scale and on tablet widths.

---

## Testing

188 tests across 16 files roughly 2,900 lines of test to 13,600 lines of app.

```bash
flutter test
```

- **Unit** scoring maths, dictionary lookup, rack generation, match
  progression, party rules, clock edge cases (pause, extend, expiry).
- **View model** the match and party turn cycles driven directly, without a
  widget tree.
- **Widget** every screen builds in both empty and populated states.
- **Responsive** layouts hold at tablet widths and maximum text scale.

Determinism is handled by injecting `Random` and `Uuid` into the engine, so
tests that need a specific deal seed one rather than asserting on luck.

---

## Running it

```bash
git clone https://github.com/Sthabiso10/Spella.git
cd Spella
flutter pub get
flutter run
```

Requires Flutter with Dart SDK ^3.12.2. No API keys, no backend, no
configuration the game is fully playable offline on first run.

```bash
flutter analyze   # lints (flutter_lints)
flutter test      # full suite
```

---

## Roadmap

The interfaces for these already exist; the implementations are what's
outstanding.

- [ ] **Backend + auth** replace `LocalPlayerService` with real accounts and
      persisted progression.
- [ ] **Real-time multiplayer** `OpponentService` becomes a thin wrapper over
      a live match channel; nothing above it changes.
- [ ] **Friends and leaderboards** swap `EmptySocialService` for a real
      social graph.
- [ ] **Daily challenge** a shared seeded rack, same for everyone, once a day.

> **Note on `convex_flutter`:** the Convex client is commented out in
> [`pubspec.yaml`](pubspec.yaml). Its bundled cargokit Gradle plugin calls
> `project.exec {}`, which Gradle 9 removed, so the Android build fails before
> compiling any app code — and 3.0.1 is the latest release, so there's no fixed
> version to move to. Nothing in `lib/` imports it, so it's parked rather than
> holding up the build.

---

## Contributing

Contributions are welcome this is a small enough codebase that a first PR
shouldn't need a guided tour.

1. **Fork the repo and branch off `main`.** Use a descriptive branch name
   (`fix/rack-shuffle-seed`, `feat/daily-challenge-picker`).
2. **Match the existing shape.** Rules and scoring belong in
   `lib/core/services/` and must stay pure Dart — no `package:flutter`
   imports, so they're testable without a widget tree. UI logic belongs in a
   view model, not the widget tree (see [Architecture](#architecture)).
3. **Add tests for engine or view model changes.** The project has no CI yet,
   so `flutter analyze` and `flutter test` passing locally is what stands in
   for a green build run both before opening a PR:

   ```bash
   flutter analyze
   flutter test
   ```
4. **Keep PRs scoped.** One fix or one feature per PR makes it reviewable;
   unrelated formatting or refactors belong in a separate PR.
5. **Open the PR against `main`** with a short description of what changed
   and why. Screenshots or a screen recording are appreciated for UI changes.

Found a bug or have an idea that isn't a code change yet? Open an
[issue](https://github.com/Sthabiso10/Spella/issues) reproduction steps for
bugs, or the problem you're trying to solve for feature ideas, are more useful
than a proposed implementation.

The [Roadmap](#roadmap) above lists the interfaces already in place for
backend, multiplayer, social and daily-challenge work those are the
highest-value places to contribute, since the seams to build against already
exist.

---

## License

[MIT](LICENSE) — use it, fork it, learn from it.
