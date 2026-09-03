# Spella

A fast-paced word game built in Flutter. Players get a rack of letters and a
countdown, and race to build the highest-scoring word they can see.

Spella is a portfolio project written to production standards: a layered
architecture, a pure-Dart rules engine with no Flutter imports, dependency
injection behind swappable interfaces, and 188 passing tests.

**Stack:** Flutter · Dart 3.12 · Stacked (MVVM) · get_it · Android + iOS

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
| **Daily Challenge** | 1 | 8 tiles | 90s |
| **Pass & Play** | 3 | 7 tiles | 45s |

Everything that varies between modes lives in a single enum, so adding a mode
never means touching the engine or the UI.

**Pass & Play** is a party mode: 2–6 people share one device and take turns on
the same rack. Guests are a separate type from real players, which is what
stops party scores leaking into anyone's account. Each turn is counted in,
covers the board during the handoff so nobody reads the rack over your
shoulder, and ends on your own result before the device moves on.

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
rarely told a real word isn't one. Generation — racks, hints, the bot's move —
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
letters on the biggest letter multipliers — so pairing two sorted lists is
optimal, and no permutation search is needed.

**A bot that scales with you.** `BotOpponentService` plays from the same
dictionary the player does, and its strength tracks the player's level, so it
stays a fair test as they improve rather than becoming a wall or a pushover.
It implements the same `OpponentService` interface real-time multiplayer will.

**One clock, extracted.** Both game modes ran the same timer, and a countdown
that can be paused, extended by a power-up and interrupted by a phone call has
more edge cases than a game screen should carry inline.
[`RoundClock`](lib/core/services/round_clock.dart) owns them, with the
invariant that `remaining` never exceeds `allotted` — so a frozen round reads
as a longer round, not one that has somehow gone past full.

**Interruptions don't cost you the round.** Both view models observe the app
lifecycle and hold the game when it backgrounds, so a round can't drain away
while the phone is in a pocket.

---

## Design

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

188 tests across 16 files — roughly 2,900 lines of test to 13,600 lines of app.

```bash
flutter test
```

- **Unit** — scoring maths, dictionary lookup, rack generation, match
  progression, party rules, clock edge cases (pause, extend, expiry).
- **View model** — the match and party turn cycles driven directly, without a
  widget tree.
- **Widget** — every screen builds in both empty and populated states.
- **Responsive** — layouts hold at tablet widths and maximum text scale.

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
configuration — the game is fully playable offline on first run.

```bash
flutter analyze   # lints (flutter_lints)
flutter test      # full suite
```

---

## Roadmap

The interfaces for these already exist; the implementations are what's
outstanding.

- [ ] **Backend + auth** — replace `LocalPlayerService` with real accounts and
      persisted progression.
- [ ] **Real-time multiplayer** — `OpponentService` becomes a thin wrapper over
      a live match channel; nothing above it changes.
- [ ] **Friends and leaderboards** — swap `EmptySocialService` for a real
      social graph.
- [ ] **Daily challenge** — a shared seeded rack, same for everyone, once a day.

> **Note on `convex_flutter`:** the Convex client is commented out in
> [`pubspec.yaml`](pubspec.yaml). Its bundled cargokit Gradle plugin calls
> `project.exec {}`, which Gradle 9 removed, so the Android build fails before
> compiling any app code — and 3.0.1 is the latest release, so there's no fixed
> version to move to. Nothing in `lib/` imports it, so it's parked rather than
> holding up the build.
