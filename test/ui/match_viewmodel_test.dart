import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spella/app/app.locator.dart';
import 'package:spella/core/models/game_mode.dart';
import 'package:spella/core/models/letter_tile.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/core/models/power_up.dart';
import 'package:spella/core/services/dictionary_service.dart';
import 'package:spella/core/services/player_service.dart';
import 'package:spella/ui/views/match/match_viewmodel.dart';

const Player _opponent = Player(id: 'them', username: 'Rival', avatar: '🐙');

/// A player who can afford anything, so affordability never masks the rule
/// actually under test.
void _seedWallet() {
  locator<PlayerService>().setPlayer(
    const Player(id: 'me', username: 'Player', avatar: '🦸', coins: 500),
  );
}

/// Runs a model up to the point the clock is live.
Future<MatchViewModel> _playing(WidgetTester tester) async {
  final MatchViewModel model = MatchViewModel(
    mode: GameMode.classic,
    opponent: _opponent,
  );
  model.initialise();

  await tester.pump(const Duration(milliseconds: 1200));
  expect(model.phase, MatchPhase.playing);
  return model;
}

void main() {
  setUpAll(() async {
    setupLocator();
    await locator<DictionaryService>().initialise();
  });

  setUp(_seedWallet);

  group('power-ups', () {
    testWidgets('swap is not offered once every tile is already placed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const SizedBox());
      final MatchViewModel model = await _playing(tester);

      expect(model.canUsePowerUp(PowerUp.swap), isTrue);

      for (final LetterTile tile in model.rack) {
        model.onRackTileTapped(tile);
      }
      expect(model.placedTiles.length, model.slotCount);

      // Nothing left to redraw, so the button is off rather than sitting there
      // waiting to take fifty coins for a no-op.
      expect(model.canUsePowerUp(PowerUp.swap), isFalse);
      model.dispose();
    });

    testWidgets('a swap with nothing to redraw is never charged for', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const SizedBox());
      final MatchViewModel model = await _playing(tester);

      for (final LetterTile tile in model.rack) {
        model.onRackTileTapped(tile);
      }

      final int before = model.me.coins;
      await model.usePowerUp(PowerUp.swap);

      expect(model.me.coins, before);
      expect(model.isPowerUpUsed(PowerUp.swap), isFalse);
      model.dispose();
    });

    testWidgets('a swap that does redraw is charged for once', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const SizedBox());
      final MatchViewModel model = await _playing(tester);

      model.onRackTileTapped(model.rack.first);
      final int before = model.me.coins;

      await model.usePowerUp(PowerUp.swap);
      expect(model.me.coins, before - PowerUp.swap.cost);
      expect(model.isPowerUpUsed(PowerUp.swap), isTrue);

      // Once per round, however many times it is tapped.
      await model.usePowerUp(PowerUp.swap);
      expect(model.me.coins, before - PowerUp.swap.cost);
      model.dispose();
    });

    testWidgets('freeze buys time without pushing the clock past full', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const SizedBox());
      final MatchViewModel model = await _playing(tester);

      await tester.pump(const Duration(seconds: 2));
      final int before = model.secondsRemaining;

      await model.usePowerUp(PowerUp.freeze);

      expect(model.secondsRemaining, before + PowerUp.freezeSeconds);
      // The bar has to keep reading as draining, so the round grows rather
      // than the clock overflowing the round it belongs to.
      expect(model.clockProgress, lessThanOrEqualTo(1));
      expect(model.clockProgress, greaterThan(0));
      model.dispose();
    });

    testWidgets('a frozen round still records the time the play took', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const SizedBox());
      final MatchViewModel model = await _playing(tester);

      await tester.pump(const Duration(seconds: 3));
      await model.usePowerUp(PowerUp.freeze);
      await tester.pump(const Duration(seconds: 2));

      // Five seconds of play, whatever was bought in the middle of them.
      // This used to go negative, because the time taken was measured against
      // the mode's clock rather than the round's.
      expect(model.clockProgress, lessThanOrEqualTo(1));
      model.dispose();
    });
  });

  group('interruptions', () {
    testWidgets('leaving the foreground pauses rather than draining the clock', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const SizedBox());
      final MatchViewModel model = await _playing(tester);

      await tester.pump(const Duration(seconds: 4));
      final int atPause = model.secondsRemaining;

      model.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(model.phase, MatchPhase.paused);
      expect(model.isPaused, isTrue);

      // The round would previously have run down inside a phone call.
      await tester.pump(const Duration(seconds: 30));
      expect(model.secondsRemaining, atPause);

      model.resumeFromPause();
      expect(model.phase, MatchPhase.playing);

      await tester.pump(const Duration(seconds: 2));
      expect(model.secondsRemaining, atPause - 2);
      model.dispose();
    });

    testWidgets('the board stays covered while the game is paused', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const SizedBox());
      final MatchViewModel model = await _playing(tester);

      expect(model.isBoardRevealed, isTrue);

      model.didChangeAppLifecycleState(AppLifecycleState.inactive);
      expect(model.isBoardRevealed, isFalse);
      expect(model.isInteractive, isFalse);

      model.resumeFromPause();
      expect(model.isBoardRevealed, isTrue);
      model.dispose();
    });

    testWidgets('an interruption during the deal does not start the clock', (
      WidgetTester tester,
    ) async {
      final MatchViewModel model = MatchViewModel(
        mode: GameMode.classic,
        opponent: _opponent,
      );
      await tester.pumpWidget(const SizedBox());
      model.initialise();

      expect(model.phase, MatchPhase.dealing);
      model.didChangeAppLifecycleState(AppLifecycleState.paused);

      // The deal timer comes and goes while the game is away. It must not
      // hand the player a round that is already running.
      await tester.pump(const Duration(seconds: 5));
      expect(model.phase, MatchPhase.paused);
      expect(model.secondsRemaining, GameMode.classic.secondsPerRound);

      model.resumeFromPause();
      expect(model.phase, MatchPhase.playing);
      expect(model.secondsRemaining, GameMode.classic.secondsPerRound);
      model.dispose();
    });
  });
}
