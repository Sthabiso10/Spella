import 'package:flutter/material.dart';
import 'package:spella/core/models/game_round.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/app_avatar.dart';
import 'package:spella/ui/widgets/app_progress.dart';
import 'package:spella/ui/widgets/count_up_text.dart';

/// The running scoreline: both players, their totals, and a mark per round
/// showing who took it.
///
/// No longer a card. During a match the board is the object and everything else
/// is instrumentation, so the scoreline is set straight onto the page with a
/// rule under it. That removes a border, a fill and a shadow from the screen
/// the player is meant to be concentrating on.
class ScoreboardCard extends StatelessWidget {
  const ScoreboardCard({
    required this.me,
    required this.opponent,
    required this.myScore,
    required this.opponentScore,
    required this.completedRounds,
    required this.totalRounds,
    super.key,
  });

  final Player me;
  final Player opponent;
  final int myScore;
  final int opponentScore;
  final List<GameRound> completedRounds;
  final int totalRounds;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: _PlayerScore(
              player: me,
              name: 'You',
              score: myScore,
              isLeading: myScore >= opponentScore,
              alignment: CrossAxisAlignment.start,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SegmentedProgress(
              total: totalRounds,
              colorFor: (int index) => _roundColor(index, palette),
            ),
          ),
          Expanded(
            child: _PlayerScore(
              player: opponent,
              name: opponent.username,
              score: opponentScore,
              isLeading: opponentScore >= myScore,
              alignment: CrossAxisAlignment.end,
            ),
          ),
        ],
      ),
    );
  }

  Color _roundColor(int index, AppPalette palette) {
    if (index >= completedRounds.length) return palette.divider;

    final GameRound round = completedRounds[index];
    if (round.isDraw) return palette.textMuted;
    return round.hostWon ? palette.accent : palette.textSecondary;
  }
}

class _PlayerScore extends StatelessWidget {
  const _PlayerScore({
    required this.player,
    required this.name,
    required this.score,
    required this.isLeading,
    required this.alignment,
  });

  final Player player;
  final String name;
  final int score;
  final bool isLeading;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool isStart = alignment == CrossAxisAlignment.start;

    final Widget avatar = AppAvatar(player: player, size: 24, ring: AvatarRing.none);
    final Widget label = Flexible(
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: isStart ? TextAlign.start : TextAlign.end,
        style: AppTextStyles.overline.copyWith(color: palette.textMuted),
      ),
    );

    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: isStart ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: isStart
              ? <Widget>[avatar, horizontalSpace(AppSpacing.sm), label]
              : <Widget>[label, horizontalSpace(AppSpacing.sm), avatar],
        ),
        verticalSpace(AppSpacing.xs + 2),
        // Whoever is ahead is in full primary ink and whoever is behind is in
        // secondary. That single step is enough to read the match state at a
        // glance, and it costs no colour at all.
        CountUpText(
          value: score,
          style: AppTextStyles.score.copyWith(
            color: isLeading ? palette.textPrimary : palette.textSecondary,
          ),
        ),
      ],
    );
  }
}
