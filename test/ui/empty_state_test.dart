import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spella/app/app.locator.dart';
import 'package:spella/app/app.router.dart' as router;
import 'package:spella/core/models/player.dart';
import 'package:spella/core/services/dictionary_service.dart';
import 'package:spella/core/services/opponent_service.dart';
import 'package:spella/core/services/player_service.dart';
import 'package:spella/core/services/social_service.dart';
import 'package:spella/ui/common/app_theme.dart';
import 'package:spella/ui/views/friends/friends_view.dart';
import 'package:spella/ui/views/home/home_view.dart';
import 'package:spella/ui/views/ranks/ranks_view.dart';
import 'package:spella/ui/widgets/leaderboard_row.dart';
import 'package:stacked_services/stacked_services.dart';

/// What a real first run looks like.
///
/// The app ships with no social data behind it, so these are not edge cases -
/// they are the default state of every screen until a backend exists. Seeded
/// sample data used to hide all of it, which is exactly why it is worth
/// pinning down now.
Widget _hostApp(Widget child) => MaterialApp(
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

  group('a fresh account', () {
    test('starts at zero, with nothing earned', () {
      final Player player = locator<PlayerService>().currentPlayer;

      expect(player.level, 1);
      expect(player.xp, 0);
      expect(player.coins, 0);
      expect(player.gems, 0);
      expect(player.wins, 0);
      expect(player.losses, 0);
      expect(player.streak, 0);
      expect(player.gamesPlayed, 0);
      expect(player.winRate, 0);
    });

    test('has no social graph behind it', () {
      final SocialService social = locator<SocialService>();

      expect(social.friends, isEmpty);
      expect(social.onlineFriends, isEmpty);
      expect(social.suggestedMatches, isEmpty);
      expect(social.pendingInvites, isEmpty);
      expect(social.activityFeed, isEmpty);
      expect(social.searchFriends(''), isEmpty);
    });
  });

  group('the bot opponent', () {
    test('is marked as a bot rather than posing as a person', () {
      final Player bot = botOpponentFor(
        const Player(id: 'me', username: 'Player', avatar: '🦸'),
      );

      expect(bot.isBot, isTrue);
      expect(bot.username, 'Spella Bot');
    });

    test('tracks the player level, so it scales as they improve', () {
      Player at(int level) => botOpponentFor(
        Player(id: 'me', username: 'Player', avatar: '🦸', level: level),
      );

      expect(at(1).level, 1);
      expect(at(30).level, 30);
      // Capped, so a very high level player does not face an unbeatable wall.
      expect(at(200).level, 60);
    });
  });

  group('empty screens', () {
    testWidgets('home offers the game rather than an absent social loop', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hostApp(const HomeView()));
      await tester.pump();

      expect(find.text('Start New Game'), findsOneWidget);
      expect(find.text('Nothing yet'), findsOneWidget);

      // No board to preview, so the whole section stands down instead of
      // leaving a heading over blank space.
      expect(find.text('Top spellers'), findsNothing);
      expect(find.byType(LeaderboardRow), findsNothing);

      // And nothing is waiting on the player, so that strip is absent too.
      expect(find.text('Waiting on you'), findsNothing);
    });

    testWidgets('friends explains what adding people would do', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hostApp(const FriendsView()));
      await tester.pump();

      expect(find.text('No friends yet'), findsOneWidget);
      expect(find.text('Game Invites'), findsNothing);
      expect(find.text('Suggested matches'), findsNothing);
    });

    testWidgets('ranks does not crown the player for being alone', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hostApp(const RanksView()));
      await tester.pump();

      expect(find.text('Nobody to rank yet'), findsOneWidget);

      // No podium, and no pinned standing bar declaring them first of one.
      expect(find.text('Your standing'), findsNothing);
    });
  });
}
