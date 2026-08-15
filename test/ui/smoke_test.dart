import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spella/app/app.locator.dart';
import 'package:spella/core/models/game_mode.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/core/services/dictionary_service.dart';
import 'package:spella/main.dart';
import 'package:spella/ui/views/startup/startup_view.dart';
import 'package:spella/ui/common/app_theme.dart';
import 'package:spella/ui/views/friends/friends_view.dart';
import 'package:spella/ui/views/home/home_view.dart';
import 'package:spella/ui/views/match/match_view.dart';
import 'package:spella/ui/views/ranks/ranks_view.dart';
import 'package:spella/ui/views/root/root_view.dart';
import 'package:spella/ui/views/shop/shop_view.dart';
import 'package:spella/ui/widgets/letter_tile_view.dart';
import 'package:stacked_services/stacked_services.dart';

import 'package:spella/app/app.router.dart' as router;

const Player _opponent = Player(
  id: 'guest',
  username: 'WordNinja99',
  avatar: '🥷',
  level: 24,
  isOnline: true,
);

/// Wraps [child] in the minimum app scaffolding the views expect.
///
/// Built on the dark theme because that is what the app ships with, so a
/// screen that only survives on the light palette fails here.
Widget hostApp(Widget child) => MaterialApp(
  theme: AppTheme.dark,
  navigatorKey: StackedService.navigatorKey,
  onGenerateRoute: router.onGenerateRoute,
  home: child,
);

void main() {
  setUpAll(() async {
    setupLocator();
    await locator<DictionaryService>().initialise();
  });

  group('screens build without error', () {
    testWidgets('home', (WidgetTester tester) async {
      await tester.pumpWidget(hostApp(const HomeView()));
      await tester.pump();

      expect(find.byType(HomeView), findsOneWidget);
      expect(find.text('Quick match'), findsOneWidget);
    });

    // The app ships with no social data behind it, so the friends tab opens on
    // its empty state rather than on a list. That state is what a real first
    // run shows, which makes it the one worth asserting on.
    testWidgets('friends', (WidgetTester tester) async {
      await tester.pumpWidget(hostApp(const FriendsView()));
      await tester.pump();

      expect(find.text('Friends'), findsOneWidget);
      expect(find.text('No friends yet'), findsOneWidget);
    });

    testWidgets('ranks', (WidgetTester tester) async {
      await tester.pumpWidget(hostApp(const RanksView()));
      await tester.pump();

      expect(find.text('Leaderboard'), findsOneWidget);
    });

    testWidgets('shop', (WidgetTester tester) async {
      await tester.pumpWidget(hostApp(const ShopView()));
      await tester.pump();

      expect(find.text('Shop'), findsOneWidget);
      expect(find.text('Avatars'), findsOneWidget);
    });

    testWidgets('root shell shows the tab bar', (WidgetTester tester) async {
      await tester.pumpWidget(hostApp(const RootView()));
      await tester.pump();

      expect(find.text('Ranks'), findsOneWidget);
    });
  });

  testWidgets('the app boots from startup into the shell', (WidgetTester tester) async {
    await tester.pumpWidget(const SpellaApp());
    await tester.pump();
    expect(find.byType(StartupView), findsOneWidget);

    // Splash holds briefly, then hands over to the tab shell.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byType(RootView), findsOneWidget);
    expect(find.text('Quick match'), findsOneWidget);
  });

  group('match screen', () {
    testWidgets('deals a rack and lets the player build a word', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hostApp(_matchView(GameMode.classic)));

      // The deal overlay covers the board first.
      await tester.pump();
      expect(find.text('ROUND 1'), findsOneWidget);

      // Then the clock starts and the rack becomes interactive.
      await tester.pump(const Duration(milliseconds: 1200));
      expect(find.text('ROUND 1'), findsNothing);
      expect(_rackTiles, findsNWidgets(GameMode.classic.rackSize));
      expect(_placedTiles, findsNothing);

      // Playing a tile moves it out of the rack and into the word.
      await tester.tap(_rackTiles.first);
      await tester.pump();
      expect(_placedTiles, findsOneWidget);

      // Clearing sends it back.
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(_placedTiles, findsNothing);
    });

    testWidgets('sizes the board to the rack of the chosen mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hostApp(_matchView(GameMode.marathon)));
      await tester.pump(const Duration(milliseconds: 1200));

      expect(_rackTiles, findsNWidgets(GameMode.marathon.rackSize));
      expect(find.byType(WordSlotView), findsNWidgets(GameMode.marathon.rackSize));
    });
  });
}

Widget _matchView(GameMode mode) => MatchView(
  arguments: router.MatchViewArguments(mode: mode, opponent: _opponent),
);

/// Tiles still available in the rack.
final Finder _rackTiles = find.byWidgetPredicate(
  (Widget widget) => widget is LetterTileView && widget.variant == TileVariant.rack,
);

/// Tiles placed into the word being built.
final Finder _placedTiles = find.byWidgetPredicate(
  (Widget widget) => widget is LetterTileView && widget.variant == TileVariant.placed,
);
