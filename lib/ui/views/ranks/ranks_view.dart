import 'package:flutter/material.dart';
import 'package:spella/core/models/social.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/views/ranks/ranks_viewmodel.dart';
import 'package:spella/ui/views/ranks/widgets/podium.dart';
import 'package:spella/ui/widgets/app_avatar.dart';
import 'package:spella/ui/widgets/app_bottom_nav.dart';
import 'package:spella/ui/widgets/app_states.dart';
import 'package:spella/ui/widgets/app_segmented_control.dart';
import 'package:spella/ui/widgets/leaderboard_row.dart';
import 'package:spella/ui/widgets/page_width.dart';
import 'package:stacked/stacked.dart';

/// The leaderboard: a podium for the top three, the rest as a ruled list, and
/// the player's own standing pinned above the tab bar so it is never more than
/// a glance away.
class RanksView extends StackedView<RanksViewModel> {
  const RanksView({super.key});

  @override
  Widget builder(BuildContext context, RanksViewModel viewModel, Widget? child) {
    final AppPalette palette = context.palette;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        bottom: false,
        child: PageWidth(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Leaderboard',
                        style: AppTextStyles.headingLarge.copyWith(
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                    horizontalSpace(AppSpacing.lg),
                    SizedBox(
                      width: 168,
                      child: AppSegmentedControl<LeaderboardScope>(
                        values: viewModel.scopes,
                        selected: viewModel.scope,
                        labelFor: (LeaderboardScope scope) => scope.label,
                        onChanged: viewModel.setScope,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    // Clears both the tab bar and the pinned standing bar.
                    AppSpacing.navClearance + 72,
                  ),
                  children: <Widget>[
                    if (!viewModel.hasBoard)
                      AppEmptyState(
                        icon: Icons.leaderboard_outlined,
                        title: viewModel.scope == LeaderboardScope.friends
                            ? 'Nobody to rank yet'
                            : 'The global board is empty',
                        message: viewModel.scope == LeaderboardScope.friends
                            ? 'Add friends and your standings will appear here '
                                  'as you play each other.'
                            : 'Global rankings arrive once the app is online.',
                      )
                    else ...<Widget>[
                      Podium(entries: viewModel.podium),
                      verticalSpace(AppSpacing.section),
                      for (final LeaderboardEntry entry in viewModel.rest)
                        LeaderboardRow(entry: entry, horizontalPadding: 0),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: viewModel.hasBoard ? _MyStandingBar(entry: viewModel.myEntry) : null,
    );
  }

  @override
  RanksViewModel viewModelBuilder(BuildContext context) => RanksViewModel();
}

/// The player's own row, always visible above the navigation bar.
///
/// The one surface in the app that floats over scrolling content, so it is also
/// the one that earns a shadow. It repeats the board's own layout - rank, face,
/// points - so the eye can compare it against any row it is covering.
class _MyStandingBar extends StatelessWidget {
  const _MyStandingBar({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      color: Colors.transparent,
      // The shell's tab bar overlays this screen, so the offset is measured
      // from the bar's own height plus whatever inset the device adds under it,
      // rather than from a number that happens to look right on one phone.
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppBottomNav.height + MediaQuery.viewPaddingOf(context).bottom + AppSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: AppRadius.card,
          border: Border.all(color: palette.borderStrong),
          boxShadow: palette.liftShadow,
        ),
        child: Row(
          children: <Widget>[
            Text(
              '${entry.rank}',
              style: AppTextStyles.rank.copyWith(color: palette.accent),
            ),
            horizontalSpace(AppSpacing.md),
            AppAvatar(player: entry.player, size: 30, ring: AvatarRing.none),
            horizontalSpace(AppSpacing.md),
            Expanded(
              child: Text(
                'Your standing',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(color: palette.textPrimary),
              ),
            ),
            Text(
              formatPoints(entry.points),
              style: AppTextStyles.scoreSmall.copyWith(color: palette.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
