import 'package:flutter/material.dart';
import 'package:spella/core/models/social.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/views/home/home_viewmodel.dart';
import 'package:spella/ui/views/home/widgets/activity_tile.dart';
import 'package:spella/ui/views/home/widgets/friends_prompt.dart';
import 'package:spella/ui/views/home/widgets/home_header.dart';
import 'package:spella/ui/views/home/widgets/leaderboard_preview.dart';
import 'package:spella/ui/views/home/widgets/mode_grid.dart';
import 'package:spella/ui/views/home/widgets/play_hero.dart';
import 'package:spella/ui/views/home/widgets/player_record.dart';
import 'package:spella/ui/widgets/app_card.dart';
import 'package:spella/ui/widgets/page_width.dart';
import 'package:spella/ui/widgets/section_header.dart';
import 'package:stacked/stacked.dart';

/// The dashboard: who you are, how far along you are, the fastest way into a
/// game, and - once there are people to report on - what they have been doing.
///
/// The screen is built almost entirely out of spacing and type. Only the game
/// modes are boxed, because only they are objects you pick up and act on
/// directly. Everything else is grouped by a quiet section label and the air
/// around it.
///
/// Every social section is conditional. The app ships with no backend behind
/// it, so a feed and a leaderboard that are always present are, for every real
/// player today, two headings over two apologies. They appear when they have
/// something to say and [FriendsPrompt] speaks for them until then.
class HomeView extends StackedView<HomeViewModel> {
  const HomeView({super.key});

  @override
  Widget builder(BuildContext context, HomeViewModel viewModel, Widget? child) {
    return Scaffold(
      backgroundColor: context.palette.canvas,
      body: SafeArea(
        bottom: false,
        child: PageWidth(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: HomeHeader(player: viewModel.player, greeting: viewModel.greeting),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.navClearance,
                ),
                sliver: SliverList.list(
                  children: <Widget>[
                    PlayHero(
                      title: viewModel.heroTitle,
                      subtitle: viewModel.heroSubtitle,
                      quickMatchMode: viewModel.quickMatchMode,
                      waitingFriends: viewModel.waitingFriends,
                      onPlay: () => viewModel.startQuickMatch(viewModel.quickMatchMode),
                      onFriendTap: viewModel.challenge,
                    ),
                    verticalSpace(AppSpacing.section),
                    const SectionHeader(title: 'Choose a mode'),
                    verticalSpace(AppSpacing.md),
                    ModeGrid(
                      modes: viewModel.gameModes,
                      onModeSelected: viewModel.startQuickMatch,
                    ),
                    if (viewModel.hasPlayed) ...<Widget>[
                      verticalSpace(AppSpacing.section),
                      const SectionHeader(title: 'Your record'),
                      verticalSpace(AppSpacing.lg),
                      PlayerRecord(player: viewModel.player),
                    ],
                    if (viewModel.activityFeed.isNotEmpty) ...<Widget>[
                      verticalSpace(AppSpacing.section),
                      SectionHeader(
                        title: 'Activity',
                        trailingLabel: 'Friends',
                        onTrailingPressed: viewModel.openFriends,
                      ),
                      verticalSpace(AppSpacing.xs),
                      _ActivityFeed(viewModel: viewModel),
                    ],
                    if (viewModel.topSpellers.isNotEmpty) ...<Widget>[
                      verticalSpace(AppSpacing.section),
                      LeaderboardPreview(
                        entries: viewModel.topSpellers,
                        onSeeAll: viewModel.openLeaderboard,
                      ),
                    ],
                    if (viewModel.showFriendsPrompt) ...<Widget>[
                      verticalSpace(AppSpacing.section),
                      FriendsPrompt(onFindFriends: viewModel.openFriends),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  HomeViewModel viewModelBuilder(BuildContext context) => HomeViewModel();
}

/// The friend feed.
///
/// Rules between rows rather than a box around each one, indented to clear the
/// avatars so the column of faces stays unbroken.
class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final List<FriendActivity> feed = viewModel.activityFeed;

    return Column(
      children: <Widget>[
        for (int i = 0; i < feed.length; i++) ...<Widget>[
          ActivityTile(activity: feed[i], onLike: () => viewModel.toggleLike(feed[i].id)),
          if (i != feed.length - 1) const AppDivider(indent: 46),
        ],
      ],
    );
  }
}
