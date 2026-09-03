import 'package:flutter/material.dart';
import 'package:spella/app/app.router.dart';
import 'package:spella/core/models/match_result.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/core/models/word_play.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/views/results/results_viewmodel.dart';
import 'package:spella/ui/widgets/app_avatar.dart';
import 'package:spella/ui/widgets/app_badge.dart';
import 'package:spella/ui/widgets/app_buttons.dart';
import 'package:spella/ui/widgets/app_card.dart';
import 'package:spella/ui/widgets/count_up_text.dart';
import 'package:spella/ui/widgets/page_width.dart';
import 'package:spella/ui/widgets/section_header.dart';
import 'package:stacked/stacked.dart';

/// Post-match summary: the verdict, the scoreline, what it paid, and the best
/// words of the match.
///
/// Built to be read in the order a player actually wants it: did I win, by how
/// much, what did I get, and only then what happened. The two final scores are
/// the largest figures in the app and they count up on arrival, because that
/// half second is the whole reward for the match.
class ResultsView extends StackedView<ResultsViewModel> {
  const ResultsView({required this.arguments, super.key});

  final ResultsViewArguments arguments;

  @override
  Widget builder(BuildContext context, ResultsViewModel viewModel, Widget? child) {
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
                    _FinalScore(viewModel: viewModel),
                    verticalSpace(AppSpacing.section),
                    _Rewards(result: viewModel.result),
                    verticalSpace(AppSpacing.section),
                    _BestWords(viewModel: viewModel),
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
                        label: 'Rematch',
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
  ResultsViewModel viewModelBuilder(BuildContext context) =>
      ResultsViewModel(result: arguments.result);
}

/// The outcome, stated as plainly as it can be.
class _Verdict extends StatelessWidget {
  const _Verdict({required this.viewModel});

  final ResultsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    // Winning is the only outcome that gets the accent. A loss is set in plain
    // primary ink rather than in red - the player already knows, and colouring
    // it would turn a game between friends into a telling-off.
    final Color ink = viewModel.didWin ? palette.accent : palette.textPrimary;

    return Column(
      children: <Widget>[
        Text(
          viewModel.headline,
          textAlign: TextAlign.center,
          style: AppTextStyles.displayLarge.copyWith(color: ink),
        ),
        verticalSpace(AppSpacing.sm),
        Text(
          viewModel.subheadline,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: palette.textSecondary),
        ),
        if (viewModel.isMvp) ...<Widget>[
          verticalSpace(AppSpacing.lg),
          const AppBadge(label: 'MVP', tone: BadgeTone.accent, icon: Icons.star_rounded),
        ],
      ],
    );
  }
}

/// The scoreline, as two faces and two numbers.
class _FinalScore extends StatelessWidget {
  const _FinalScore({required this.viewModel});

  final ResultsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: _FinalPlayer(
            player: viewModel.me,
            name: 'You',
            score: viewModel.match.hostScore,
            isWinner: viewModel.didWin,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            '–',
            style: AppTextStyles.headingMedium.copyWith(color: palette.textMuted),
          ),
        ),
        Expanded(
          child: _FinalPlayer(
            player: viewModel.opponent,
            name: viewModel.opponent.username,
            score: viewModel.match.guestScore,
            isWinner: viewModel.didLose,
          ),
        ),
      ],
    );
  }
}

class _FinalPlayer extends StatelessWidget {
  const _FinalPlayer({
    required this.player,
    required this.name,
    required this.score,
    required this.isWinner,
  });

  final Player player;
  final String name;
  final int score;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Column(
      children: <Widget>[
        AppAvatar(
          player: player,
          size: 48,
          ring: isWinner ? AvatarRing.accent : AvatarRing.subtle,
        ),
        verticalSpace(AppSpacing.sm),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.overline.copyWith(color: palette.textMuted),
        ),
        verticalSpace(AppSpacing.sm),
        FittedBox(
          child: CountUpText(
            value: score,
            // The half second this takes is the whole reward for the match.
            from: 0,
            style: AppTextStyles.scoreLarge.copyWith(
              color: isWinner ? palette.textPrimary : palette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// What the match paid out.
///
/// A row of figures rather than a row of chips: these are numbers, and numbers
/// read faster as numbers than as badges.
class _Rewards extends StatelessWidget {
  const _Rewards({required this.result});

  final MatchResult result;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: palette.divider),
          bottom: BorderSide(color: palette.divider),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          AppMetric(
            value: '+${result.coinsEarned}',
            label: 'Coins',
            alignment: CrossAxisAlignment.center,
          ),
          AppMetric(
            value: '+${result.gemsEarned}',
            label: 'Gems',
            alignment: CrossAxisAlignment.center,
          ),
          AppMetric(
            value: '+${result.xpEarned}',
            label: result.levelledUp ? 'XP · Level up' : 'XP',
            tone: result.levelledUp ? palette.accent : null,
            alignment: CrossAxisAlignment.center,
          ),
        ],
      ),
    );
  }
}

/// The standout word each player found.
class _BestWords extends StatelessWidget {
  const _BestWords({required this.viewModel});

  final ResultsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final WordPlay? mine = viewModel.myBestPlay;
    final WordPlay? theirs = viewModel.opponentBestPlay;

    if (mine == null && theirs == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(title: 'Best words'),
        verticalSpace(AppSpacing.md),
        if (mine != null) _BestWordRow(owner: 'You', play: mine, isMine: true),
        if (mine != null && theirs != null) const AppDivider(),
        if (theirs != null)
          _BestWordRow(owner: viewModel.opponent.username, play: theirs, isMine: false),
      ],
    );
  }
}

class _BestWordRow extends StatelessWidget {
  const _BestWordRow({required this.owner, required this.play, required this.isMine});

  final String owner;
  final WordPlay play;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  owner.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.overline.copyWith(color: palette.textMuted),
                ),
                verticalSpace(AppSpacing.xs + 2),
                Text(
                  play.display,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.wordmark.copyWith(
                    fontSize: 18,
                    color: isMine ? palette.textPrimary : palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          horizontalSpace(AppSpacing.md),
          Text(
            '${play.score}',
            style: AppTextStyles.score.copyWith(
              color: isMine ? palette.accent : palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
