import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spella/app/app.locator.dart';
import 'package:spella/app/app.router.dart' as router;
import 'package:spella/core/models/game_mode.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/core/models/social.dart';
import 'package:spella/core/services/player_service.dart';
import 'package:spella/core/services/social_service.dart';
import 'package:spella/ui/common/app_theme.dart';
import 'package:spella/ui/views/friends/friends_view.dart';
import 'package:spella/ui/views/home/home_view.dart';
import 'package:spella/ui/widgets/app_search_field.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

/// The screens as they read once there is something on them.
///
/// The app ships against [EmptySocialService], so every populated layout - the
/// order the friends screen puts its sections in, the record strip, the feed -
/// is unreachable from the running app and would otherwise go untested until a
/// backend lands. These stub the graph and pin the arrangement now.
void main() {
  setUpAll(setupLocator);

  tearDown(() {
    _register<SocialService>(EmptySocialService());
    _register<PlayerService>(LocalPlayerService());
  });

  group('home with a history behind it', () {
    setUp(() {
      _register<SocialService>(_StubSocialService(friends: _friends));
      _register<PlayerService>(
        LocalPlayerService(
          initialPlayer: const Player(
            id: 'me',
            username: 'Player',
            avatar: '🦸',
            level: 4,
            xp: 60,
            wins: 7,
            losses: 3,
          ),
        ),
      );
    });

    testWidgets('reports the record, the feed and the board', (
      WidgetTester tester,
    ) async {
      await _pumpTall(tester, const HomeView());

      expect(find.text('Level 4'), findsOneWidget);
      expect(find.text('60 / 250 XP'), findsOneWidget);

      // Ten games played, seven of them won.
      expect(find.text('Your record'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);

      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Top spellers'), findsOneWidget);

      // With a social graph in place the nudge towards building one is gone.
      expect(find.text('Find people to play'), findsNothing);
    });

    // The record strip is three figures and two hairlines on one line, and it
    // only exists for a player who has finished a match - so the responsive
    // suite, which pumps a fresh account, never lays it out at all.
    testWidgets('lays the record out on the narrowest phone at the largest text', (
      WidgetTester tester,
    ) async {
      await _pumpTall(
        tester,
        const HomeView(),
        size: const Size(320, 568),
        textScale: 1.6,
      );

      // Scrolling is what forces the strip to lay out and paint - and a render
      // overflow throws during paint, which is the whole point of the check.
      // The page scroller specifically: the waiting-friends strip is a
      // horizontal scrollable of its own, and scrolling that goes nowhere.
      await tester.scrollUntilVisible(
        find.text('Your record'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Your record'), findsOneWidget);
    });

    testWidgets('leads with whoever is waiting, not with a generic match', (
      WidgetTester tester,
    ) async {
      await _pumpTall(tester, const HomeView());

      expect(find.text('Your move'), findsOneWidget);

      // The pill for the friend whose turn it is, which only the hero draws -
      // the name alone appears again further down the feed and the board.
      expect(
        _topOf(tester, find.text('Your turn')),
        lessThan(_topOf(tester, find.text('Quick match'))),
      );
    });
  });

  group('friends with a full list', () {
    setUp(() {
      _register<SocialService>(
        _StubSocialService(
          friends: _friends,
          invites: <GameInvite>[
            GameInvite(
              id: 'i1',
              from: _friends.first,
              mode: GameMode.blitz,
              sentAt: DateTime.now(),
            ),
          ],
          suggestions: <Player>[
            const Player(id: 's1', username: 'Nell', avatar: '🦉', isOnline: true),
          ],
        ),
      );
    });

    testWidgets('orders sections by who can actually play right now', (
      WidgetTester tester,
    ) async {
      await _pumpTall(tester, const FriendsView());

      // Expiring first, then people who are awake, then strangers who are
      // awake, and only then the friends who are not around.
      expect(
        _topOf(tester, find.text('Challenges')),
        lessThan(_topOf(tester, find.text('Online now'))),
      );
      expect(
        _topOf(tester, find.text('Online now')),
        lessThan(_topOf(tester, find.text('People to play'))),
      );
      expect(
        _topOf(tester, find.text('People to play')),
        lessThan(_topOf(tester, find.text('Offline'))),
      );
    });

    testWidgets('counts the list it is actually showing', (WidgetTester tester) async {
      await _pumpTall(tester, const FriendsView());

      expect(find.text('7 friends · 3 online'), findsOneWidget);
      expect(find.text('No friends yet'), findsNothing);
    });

    testWidgets('offers search once the list is long enough to need it', (
      WidgetTester tester,
    ) async {
      await _pumpTall(tester, const FriendsView());
      expect(find.byType(AppSearchField), findsOneWidget);

      // A search narrows to one flat list - no online/offline split to read
      // past, and the suggestion shelf stands down.
      await tester.enterText(find.byType(TextField), 'ada');
      await tester.pump();

      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('Online now'), findsNothing);
      expect(find.text('Offline'), findsNothing);
      expect(find.text('People to play'), findsNothing);
    });

    // A populated friends list is unreachable from the running app, so the
    // responsive suite only ever lays out its empty state. Invite cards and
    // friend rows both put a button beside wrapping text, which is the shape
    // that runs out of room first.
    testWidgets('lays out on the narrowest phone at the largest text', (
      WidgetTester tester,
    ) async {
      await _pumpTall(
        tester,
        const FriendsView(),
        size: const Size(320, 568),
        textScale: 1.6,
      );

      await tester.scrollUntilVisible(
        find.text('Offline'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(FriendsView), findsOneWidget);
    });

    testWidgets('says so when a search matches nobody', (WidgetTester tester) async {
      await _pumpTall(tester, const FriendsView());

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();

      expect(find.text('No one called "zzz"'), findsOneWidget);
    });
  });

  testWidgets('a short friends list is shown without a search field', (
    WidgetTester tester,
  ) async {
    _register<SocialService>(
      _StubSocialService(friends: _friends.take(3).toList(growable: false)),
    );

    await _pumpTall(tester, const FriendsView());

    expect(find.text('Online now'), findsOneWidget);
    expect(find.byType(AppSearchField), findsNothing);
  });
}

/// Seven friends, three of them online.
const List<Player> _friends = <Player>[
  Player(id: 'f1', username: 'Ada', avatar: '🦊', level: 6, wins: 9, isOnline: true),
  Player(id: 'f2', username: 'Bo', avatar: '🐙', level: 4, wins: 5, isOnline: true),
  Player(id: 'f3', username: 'Cy', avatar: '🐉', level: 3, wins: 2, isOnline: true),
  Player(id: 'f4', username: 'Dot', avatar: '🐳', level: 8, wins: 14),
  Player(id: 'f5', username: 'Eli', avatar: '🦁', level: 2, wins: 1),
  Player(id: 'f6', username: 'Fay', avatar: '🐼', level: 5, wins: 7),
  Player(id: 'f7', username: 'Gus', avatar: '🦝', level: 1, wins: 0),
];

/// Replaces a locator registration, so a screen can be pumped against a graph
/// the shipping service cannot produce.
void _register<T extends Object>(T service) {
  if (locator.isRegistered<T>()) locator.unregister<T>();
  locator.registerSingleton<T>(service);
}

/// Pumps [child], by default into a viewport tall enough to build the whole
/// page at once.
///
/// A sliver list does not build what it has not scrolled to, and most of these
/// tests are about the order sections come in - which needs all of them laid
/// out together to compare. Pass a [size] to check a real device instead.
Future<void> _pumpTall(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(420, 2400),
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

double _topOf(WidgetTester tester, Finder finder) => tester.getTopLeft(finder).dy;

/// A social graph with whatever the test needs in it.
class _StubSocialService with ListenableServiceMixin implements SocialService {
  _StubSocialService({
    required this.friends,
    List<GameInvite> invites = const <GameInvite>[],
    List<Player> suggestions = const <Player>[],
  }) : pendingInvites = invites,
       suggestedMatches = suggestions;

  @override
  final List<Player> friends;

  @override
  final List<GameInvite> pendingInvites;

  @override
  final List<Player> suggestedMatches;

  @override
  List<Player> get onlineFriends =>
      friends.where((Player friend) => friend.isOnline).toList(growable: false);

  @override
  List<FriendActivity> get activityFeed => <FriendActivity>[
    FriendActivity(
      id: 'a1',
      player: friends.first,
      kind: ActivityKind.wordPlayed,
      headline: 'just spelled QUARTZ',
      detail: 'for 50 points',
      occurredAt: DateTime.now(),
    ),
  ];

  @override
  List<LeaderboardEntry> leaderboard(LeaderboardScope scope) => <LeaderboardEntry>[
    for (int i = 0; i < friends.length; i++)
      LeaderboardEntry(rank: i + 1, player: friends[i], points: 500 - i * 40),
  ];

  @override
  int rankPointsFor(Player player) => EmptySocialService.pointsFor(player);

  @override
  List<Player> searchFriends(String query) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) return friends;
    return friends
        .where((Player friend) => friend.username.toLowerCase().contains(needle))
        .toList(growable: false);
  }

  @override
  GameInvite? acceptInvite(String inviteId) => null;

  @override
  void declineInvite(String inviteId) {}

  @override
  void toggleLike(String activityId) {}
}
