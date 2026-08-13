import 'package:flutter/material.dart';
import 'package:spella/core/models/game_mode.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/core/models/social.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/views/home/home_viewmodel.dart';
import 'package:spella/ui/views/home/widgets/activity_tile.dart';
import 'package:spella/ui/views/home/widgets/leaderboard_preview.dart';
import 'package:spella/ui/views/home/widgets/mode_carousel.dart';
import 'package:spella/ui/views/home/widgets/play_hero.dart';
import 'package:spella/ui/widgets/app_avatar.dart';
import 'package:spella/ui/widgets/app_badge.dart';
import 'package:spella/ui/widgets/app_card.dart';
import 'package:spella/ui/widgets/app_states.dart';
import 'package:spella/ui/widgets/page_width.dart';
import 'package:spella/ui/widgets/section_header.dart';
import 'package:stacked/stacked.dart';

/// The dashboard: who you are, the fastest way into a game, what your friends
/// have been doing, where you stand, and today's challenge.
///
/// The screen is built almost entirely out of spacing and type. Only two things
/// are boxed - the game modes and the daily challenge - because only those two
/// are objects you act on directly. Everything else is grouped by a quiet
/// section label and the air around it.
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
              SliverToBoxAdapter(child: _Identity(viewModel: viewModel)),
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
                      waitingFriends: viewModel.waitingFriends,
                      onPlay: () => viewModel.startQuickMatch(GameMode.classic),
                      onFriendTap: viewModel.challenge,
                    ),
                    verticalSpace(AppSpacing.section),
                    const SectionHeader(title: 'Game modes'),
                    verticalSpace(AppSpacing.md),
                    ModeCarousel(
                      modes: viewModel.quickPlayModes,
                      onModeSelected: viewModel.startQuickMatch,
                    ),
                    verticalSpace(AppSpacing.section),
                    SectionHeader(
                      title: 'Activity',
                      trailingLabel: 'Friends',
                      onTrailingPressed: viewModel.openFriends,
                    ),
                    verticalSpace(AppSpacing.xs),
                    _ActivityFeed(viewModel: viewModel),
                    verticalSpace(AppSpacing.section),
                    LeaderboardPreview(
                      entries: viewModel.topSpellers,
                      onSeeAll: viewModel.openLeaderboard,
                    ),
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

/// Top row: who is signed in, and what they are carrying.
///
/// The greeting is the small line and the name is the large one, because the
/// player already knows what time it is.
class _Identity extends StatelessWidget {
  const _Identity({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final Player player = viewModel.player;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Row(
        children: <Widget>[
          AppAvatar(player: player, size: 40, showLevel: true),
          horizontalSpace(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  viewModel.greeting.toUpperCase(),
                  style: AppTextStyles.overline.copyWith(color: palette.textMuted),
                ),
                verticalSpace(2),
                Text(
                  player.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingSmall.copyWith(color: palette.textPrimary),
                ),
              ],
            ),
          ),
          horizontalSpace(AppSpacing.md),
          if (player.streak > 0) ...<Widget>[
            AppInlineStat(
              icon: Icons.local_fire_department_rounded,
              value: '${player.streak}',
              tone: palette.accent,
            ),
            horizontalSpace(AppSpacing.lg),
          ],
          AppInlineStat(
            icon: Icons.monetization_on_outlined,
            value: formatPoints(player.coins),
          ),
        ],
      ),
    );
  }
}

/// The friend feed, or an honest blank when nothing has happened.
class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final List<FriendActivity> feed = viewModel.activityFeed;

    if (feed.isEmpty) {
      return const AppEmptyState(
        icon: Icons.bolt_outlined,
        title: 'Nothing yet',
        message: 'When your friends play, their best words show up here.',
      );
    }

    return Column(
      children: <Widget>[
        for (int i = 0; i < feed.length; i++) ...<Widget>[
          ActivityTile(activity: feed[i], onLike: () => viewModel.toggleLike(feed[i].id)),
          // Rules between rows rather than a box around each one, indented to
          // clear the avatars so the column of faces stays unbroken.
          if (i != feed.length - 1) const AppDivider(indent: 46),
        ],
      ],
    );
  }
}
