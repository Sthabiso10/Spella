import 'package:flutter/material.dart';
import 'package:spella/app/app.router.dart';
import 'package:spella/core/models/party.dart';
import 'package:spella/core/models/word_play.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/views/party/party_results_viewmodel.dart';
import 'package:spella/ui/widgets/app_avatar.dart';
import 'package:spella/ui/widgets/app_buttons.dart';
import 'package:spella/ui/widgets/app_card.dart';
import 'package:spella/ui/widgets/count_up_text.dart';
import 'package:spella/ui/widgets/page_width.dart';
import 'package:spella/ui/widgets/section_header.dart';
import 'package:stacked/stacked.dart';

/// The final table.
///
/// Read across a room rather than held at arm's length, so the winner's name is
/// the largest thing on it and every score is set in the same tabular column.
/// No rewards are shown because none are paid: a party game settles an argument
/// between people in a room, not anybody's XP.
class PartyResultsView extends StackedView<PartyResultsViewModel> {
  const PartyResultsView({required this.arguments, super.key});

  final PartyResultsViewArguments arguments;

  @override
  Widget builder(BuildContext context, PartyResultsViewModel viewModel, Widget? child) {
    final AppPalette palette = context.palette;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: PageWidth(
          child: Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xxl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  children: <Widget>[
                    _Verdict(viewModel: viewModel),
                    verticalSpace(AppSpacing.section),
                    const SectionHeader(title: 'Final standings'),
                    verticalSpace(AppSpacing.sm),
                    for (final PartyStanding standing in viewModel.standings)
                      _StandingRow(standing: standing),
                    if (viewModel.bestWordHolder != null) ...<Widget>[
                      verticalSpace(AppSpacing.section),
                      _BestWordOfTheGame(standing: viewModel.bestWordHolder!),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: AppButton(
                        label: 'Home',
                        size: AppButtonSize.large,
                        style: AppButtonStyle.ghost,
                        onPressed: viewModel.goHome,
                      ),
                    ),
                    horizontalSpace(AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        label: 'Play again',
                        icon: Icons.refresh_rounded,
                        size: AppButtonSize.large,
                        onPressed: viewModel.rematch,
                      ),
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
  PartyResultsViewModel viewModelBuilder(BuildContext context) =>
      PartyResultsViewModel(match: arguments.match);
}

/// Who won, in the largest type the app owns.
class _Verdict extends StatelessWidget {
  const _Verdict({required this.viewModel});

  final PartyResultsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    // Usually one face. A drawn game can put the whole table up here, so the
    // row wraps and the faces shrink rather than running off the screen.
    final List<PartyStanding> winners = viewModel.winners;
    final double avatarSize = winners.length > 3 ? 40 : 56;

    return Column(
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final PartyStanding standing in winners)
              AppAvatar(
                player: standing.player.asPlayer,
                size: avatarSize,
                ring: AvatarRing.accent,
              ),
          ],
        ),
        verticalSpace(AppSpacing.xl),
        FittedBox(
          child: Text(
            viewModel.headline,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayLarge.copyWith(color: palette.accent),
          ),
        ),
        verticalSpace(AppSpacing.sm),
        Text(
          viewModel.subheadline,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: palette.textSecondary),
        ),
      ],
    );
  }
}

/// One row of the final table.
class _StandingRow extends StatelessWidget {
  const _StandingRow({required this.standing});

  final PartyStanding standing;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: standing.isWinner ? palette.surfaceElevated : Colors.transparent,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: standing.isWinner ? palette.accentBorder : Colors.transparent,
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 22,
            child: Text(
              '${standing.rank}',
              style: AppTextStyles.rank.copyWith(
                color: standing.isWinner ? palette.accent : palette.textMuted,
              ),
            ),
          ),
          horizontalSpace(AppSpacing.md),
          AppAvatar(player: standing.player.asPlayer, size: 36, ring: AvatarRing.none),
          horizontalSpace(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  standing.player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong.copyWith(
                    fontSize: 14,
                    color: palette.textPrimary,
                  ),
                ),
                verticalSpace(2),
                Text(
                  standing.roundsWon == 1
                      ? '1 round won'
                      : '${standing.roundsWon} rounds won',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          horizontalSpace(AppSpacing.md),
          // Counts up on arrival, so the table resolves in front of everyone
          // rather than simply being there when the screen appears.
          CountUpText(
            value: standing.points,
            style: AppTextStyles.score.copyWith(
              fontSize: 24,
              color: standing.isWinner ? palette.textPrimary : palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// The single best word of the whole game.
class _BestWordOfTheGame extends StatelessWidget {
  const _BestWordOfTheGame({required this.standing});

  final PartyStanding standing;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final WordPlay play = standing.bestPlay!;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'WORD OF THE GAME · ${standing.player.name.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.overline.copyWith(color: palette.textMuted),
                ),
                verticalSpace(AppSpacing.sm),
                Text(
                  play.display,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.wordmark.copyWith(
                    fontSize: 20,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          horizontalSpace(AppSpacing.md),
          Text(
            '${play.score}',
            style: AppTextStyles.score.copyWith(color: palette.accent),
          ),
        ],
      ),
    );
  }
}
