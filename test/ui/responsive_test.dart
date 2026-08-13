import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spella/app/app.locator.dart';
import 'package:spella/app/app.router.dart' as router;
import 'package:spella/core/models/game_mode.dart';
import 'package:spella/core/models/party.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/core/services/dictionary_service.dart';
import 'package:spella/ui/common/app_theme.dart';
import 'package:spella/ui/views/friends/friends_view.dart';
import 'package:spella/ui/views/home/home_view.dart';
import 'package:spella/ui/views/match/match_view.dart';
import 'package:spella/ui/views/party/party_match_view.dart';
import 'package:spella/ui/views/party/party_results_view.dart';
import 'package:spella/ui/views/party/party_setup_view.dart';
import 'package:spella/ui/views/ranks/ranks_view.dart';
import 'package:spella/ui/views/root/root_view.dart';
import 'package:spella/ui/views/shop/shop_view.dart';
import 'package:spella/ui/widgets/app_bottom_nav.dart';
import 'package:stacked_services/stacked_services.dart';

/// Guards the layout against the sizes it actually ships on.
///
/// A render overflow throws during paint, so simply building each screen at a
/// given size is enough to catch one - which is what makes this cheap enough to
/// run for every screen at every size. The small phone and the largest text
/// scale are the two cases that break first, so both are covered explicitly.
const Player _opponent = Player(
  id: 'guest',
  username: 'WordNinja99',
  avatar: '🥷',
  level: 24,
  isOnline: true,
);

/// A full table, since six names is the layout that runs out of room first.
const List<PartyPlayer> _fullTable = <PartyPlayer>[
  PartyPlayer(id: 'a', name: 'Ana', avatar: '🦊'),
  PartyPlayer(id: 'b', name: 'Bartholomew', avatar: '🐙'),
  PartyPlayer(id: 'c', name: 'Cal', avatar: '🦉'),
  PartyPlayer(id: 'd', name: 'Dee', avatar: '🐉'),
  PartyPlayer(id: 'e', name: 'Ekaterina', avatar: '🐳'),
  PartyPlayer(id: 'f', name: 'Fox', avatar: '🦁'),
];

/// Logical sizes, smallest phone in common use through to a tablet.
const Map<String, Size> _viewports = <String, Size>{
  'small phone': Size(320, 568),
  'modern phone': Size(393, 852),
  'tablet': Size(834, 1112),
};

void main() {
  setUpAll(() async {
    setupLocator();
    await locator<DictionaryService>().initialise();
  });

  /// Builds [child] at [size] with [textScale] applied.
  Future<void> pumpAt(
    WidgetTester tester,
    Widget child,
    Size size, {
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        navigatorKey: StackedService.navigatorKey,
        onGenerateRoute: router.onGenerateRoute,
        builder: (BuildContext context, Widget? view) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: view ?? const SizedBox.shrink(),
        ),
        home: child,
      ),
    );
    await tester.pump();
  }

  for (final MapEntry<String, Size> viewport in _viewports.entries) {
    group('on a ${viewport.key}', () {
      testWidgets('the tab shell lays out', (WidgetTester tester) async {
        await pumpAt(tester, const RootView(), viewport.value);
        expect(find.byType(RootView), findsOneWidget);
      });

      testWidgets('home lays out', (WidgetTester tester) async {
        await pumpAt(tester, const HomeView(), viewport.value);
        expect(find.byType(HomeView), findsOneWidget);
      });

      testWidgets('friends lays out', (WidgetTester tester) async {
        await pumpAt(tester, const FriendsView(), viewport.value);
        expect(find.byType(FriendsView), findsOneWidget);
      });

      testWidgets('ranks lays out', (WidgetTester tester) async {
        await pumpAt(tester, const RanksView(), viewport.value);
        expect(find.byType(RanksView), findsOneWidget);
      });

      testWidgets('shop lays out', (WidgetTester tester) async {
        await pumpAt(tester, const ShopView(), viewport.value);
        expect(find.byType(ShopView), findsOneWidget);
      });

      // Marathon deals the widest rack and the most round markers, so it is the
      // hardest layout the match screen has to survive.
      testWidgets('a marathon match lays out', (WidgetTester tester) async {
        await pumpAt(tester, _matchView(GameMode.marathon), viewport.value);
        await tester.pump(const Duration(milliseconds: 1200));

        expect(find.byType(MatchView), findsOneWidget);
      });

      testWidgets('party setup lays out', (WidgetTester tester) async {
        await pumpAt(tester, const PartySetupView(), viewport.value);
        expect(find.byType(PartySetupView), findsOneWidget);
      });

      // A six player handoff carries a running total per person, which is the
      // widest strip in the mode.
      testWidgets('a six player handoff lays out', (WidgetTester tester) async {
        await pumpAt(tester, _partyMatch(), viewport.value);
        expect(find.byType(PartyMatchView), findsOneWidget);
      });

      testWidgets('a six player turn lays out', (WidgetTester tester) async {
        await pumpAt(tester, _partyMatch(), viewport.value);
        await tester.tap(find.text("I'm ready"));
        await tester.pump();

        expect(find.text('YOUR TURN'), findsOneWidget);
      });

      testWidgets('the party standings lay out', (WidgetTester tester) async {
        await pumpAt(tester, _partyResults(), viewport.value);
        expect(find.byType(PartyResultsView), findsOneWidget);
      });
    });
  }

  // Building without throwing is not the same as laying out correctly: a widget
  // that wrongly expands to fill the window raises no exception, it just eats
  // the screen. These three measure what actually got painted.
  for (final MapEntry<String, Size> viewport in _viewports.entries) {
    testWidgets('the tab bar stays a bar on a ${viewport.key}', (
      WidgetTester tester,
    ) async {
      await pumpAt(tester, const RootView(), viewport.value);

      final Size bar = tester.getSize(find.byType(AppBottomNav));
      expect(bar.height, lessThan(AppBottomNav.height * 1.6));
      expect(bar.height, lessThan(viewport.value.height / 4));
    });
  }

  testWidgets('the shell shows its content, not just its chrome', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, const RootView(), const Size(393, 852));

    // Home is the default tab, so its primary action has to be on screen and
    // clear of the bar rather than hidden behind it.
    final Finder play = find.text('Start New Game');
    expect(play, findsOneWidget);
    expect(
      tester.getRect(play).bottom,
      lessThan(tester.getRect(find.byType(AppBottomNav)).top),
    );
  });

  testWidgets('the tab bar survives the largest text scale', (WidgetTester tester) async {
    await pumpAt(tester, const RootView(), const Size(320, 568), textScale: 2);

    expect(find.byType(RootView), findsOneWidget);
    expect(tester.getSize(find.byType(AppBottomNav)).height, lessThan(120));
  });

  testWidgets('home survives a large text scale', (WidgetTester tester) async {
    await pumpAt(tester, const HomeView(), const Size(320, 568), textScale: 1.6);

    expect(find.byType(HomeView), findsOneWidget);
  });
}

Widget _partyMatch() =>
    const PartyMatchView(arguments: router.PartyMatchViewArguments(players: _fullTable));

Widget _partyResults() => PartyResultsView(
  arguments: router.PartyResultsViewArguments(
    match: PartyMatch(
      id: 'party',
      mode: GameMode.party,
      players: _fullTable,
      rounds: const <PartyRound>[],
    ),
  ),
);

Widget _matchView(GameMode mode) => MatchView(
  arguments: router.MatchViewArguments(mode: mode, opponent: _opponent),
);
