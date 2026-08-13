import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spella/app/app.locator.dart';
import 'package:spella/app/app.router.dart' as router;
import 'package:spella/core/models/game_mode.dart';
import 'package:spella/core/models/party.dart';
import 'package:spella/core/services/dictionary_service.dart';
import 'package:spella/ui/common/app_theme.dart';
import 'package:spella/ui/views/party/party_match_view.dart';
import 'package:spella/ui/views/party/party_setup_view.dart';
import 'package:spella/ui/widgets/letter_tile_view.dart';
import 'package:stacked_services/stacked_services.dart';

const List<PartyPlayer> _roster = <PartyPlayer>[
  PartyPlayer(id: 'a', name: 'Ana', avatar: '🦊'),
  PartyPlayer(id: 'b', name: 'Ben', avatar: '🐙'),
];

Widget _hostApp(Widget child) => MaterialApp(
  theme: AppTheme.dark,
  navigatorKey: StackedService.navigatorKey,
  onGenerateRoute: router.onGenerateRoute,
  home: child,
);

Widget _partyMatch() =>
    PartyMatchView(arguments: const router.PartyMatchViewArguments(players: _roster));

/// Tiles the current player can still use.
final Finder _rackTiles = find.byWidgetPredicate(
  (Widget widget) => widget is LetterTileView && widget.variant == TileVariant.rack,
);

/// Tiles placed into the word being built.
final Finder _placedTiles = find.byWidgetPredicate(
  (Widget widget) => widget is LetterTileView && widget.variant == TileVariant.placed,
);

void main() {
  setUpAll(() async {
    setupLocator();
    await locator<DictionaryService>().initialise();
  });

  group('party setup', () {
    testWidgets('starts with the signed-in player and needs one more', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hostApp(const PartySetupView()));
      await tester.pump();

      expect(find.text('Pass & Play'), findsOneWidget);
      expect(find.text('Add one more player'), findsOneWidget);
    });

    testWidgets('a typed name joins the table', (WidgetTester tester) async {
      await tester.pumpWidget(_hostApp(const PartySetupView()));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Ben');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.text('Ben'), findsOneWidget);
      expect(find.text('Add one more player'), findsNothing);
    });

    testWidgets('the same name cannot join twice', (WidgetTester tester) async {
      await tester.pumpWidget(_hostApp(const PartySetupView()));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Ben');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Casing should not be enough to make a second Ben.
      await tester.enterText(find.byType(TextField), 'ben');
      await tester.pump();

      expect(find.text('Someone is already called that'), findsOneWidget);
    });
  });

  group('party match', () {
    testWidgets('opens on a handoff and keeps the rack hidden', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hostApp(_partyMatch()));
      await tester.pump();

      expect(find.text('Pass to'), findsOneWidget);
      expect(find.text('Ana'), findsWidgets);

      // The board exists underneath, but nothing playable is reachable: the
      // whole point of the handoff is that the next player cannot read the rack.
      expect(find.text("I'm ready"), findsOneWidget);
    });

    testWidgets('tapping ready deals the turn and starts the clock', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hostApp(_partyMatch()));
      await tester.pump();

      await tester.tap(find.text("I'm ready"));
      await tester.pump();

      expect(find.text('Pass to'), findsNothing);
      expect(_rackTiles, findsNWidgets(GameMode.party.rackSize));
      expect(find.text('YOUR TURN'), findsOneWidget);

      // A tile moves from the rack into the word.
      await tester.tap(_rackTiles.first);
      await tester.pump();
      expect(_placedTiles, findsOneWidget);
    });

    testWidgets('passing hands the device to the next player', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hostApp(_partyMatch()));
      await tester.pump();

      await tester.tap(find.text("I'm ready"));
      await tester.pump();

      await tester.tap(find.text('Pass turn'));
      await tester.pump();

      // Back to a handoff, now naming the second player.
      expect(find.text('Pass to'), findsOneWidget);
      expect(find.text('Ben'), findsWidgets);
    });

    testWidgets('once everyone has played, the round is recapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hostApp(_partyMatch()));
      await tester.pump();

      for (int turn = 0; turn < _roster.length; turn++) {
        await tester.tap(find.text("I'm ready"));
        await tester.pump();
        await tester.tap(find.text('Pass turn'));
        await tester.pump();
      }

      expect(find.text('ROUND 1'), findsOneWidget);
      expect(find.text('Nobody scored'), findsOneWidget);
      expect(find.text('Next Round'), findsOneWidget);
    });

    testWidgets('the last round offers the standings instead of another round', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hostApp(_partyMatch()));
      await tester.pump();

      for (int round = 0; round < GameMode.party.totalRounds; round++) {
        for (int turn = 0; turn < _roster.length; turn++) {
          await tester.tap(find.text("I'm ready"));
          await tester.pump();
          await tester.tap(find.text('Pass turn'));
          await tester.pump();
        }

        if (round < GameMode.party.totalRounds - 1) {
          await tester.tap(find.text('Next Round'));
          await tester.pump();
        }
      }

      expect(find.text('See Standings'), findsOneWidget);
    });
  });
}
