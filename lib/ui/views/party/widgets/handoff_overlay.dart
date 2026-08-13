import 'package:flutter/material.dart';
import 'package:spella/core/models/party.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/app_avatar.dart';
import 'package:spella/ui/widgets/app_buttons.dart';
import 'package:spella/ui/views/match/widgets/match_overlays.dart';

/// The pass-the-device screen.
///
/// This is the load-bearing screen of the whole mode. Everyone plays the same
/// rack, so if the tiles were visible while the phone changed hands the next
/// player would spend the handover solving the round. Nothing playable is
/// rendered until whoever is named here says they have it.
///
/// It also does the social work a local game needs: it says the name out loud,
/// in the largest type on the screen, so the table knows whose turn it is
/// without anyone having to ask.
class HandoffOverlay extends StatelessWidget {
  const HandoffOverlay({
    required this.player,
    required this.roundNumber,
    required this.totalRounds,
    required this.turnNumber,
    required this.playerCount,
    required this.standings,
    required this.onReady,
    super.key,
  });

  final PartyPlayer player;
  final int roundNumber;
  final int totalRounds;

  /// Position in the turn order, 1-based.
  final int turnNumber;

  final int playerCount;

  /// Running totals, so the table can see what they are chasing.
  final List<PartyStanding> standings;

  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool hasScores = standings.any((PartyStanding standing) => standing.points > 0);

    return MatchScrim(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'ROUND $roundNumber OF $totalRounds · TURN $turnNumber OF $playerCount',
              textAlign: TextAlign.center,
              style: AppTextStyles.overline.copyWith(color: palette.textMuted),
            ),
            verticalSpace(AppSpacing.section),
            AppAvatar(player: player.asPlayer, size: 72, ring: AvatarRing.accent),
            verticalSpace(AppSpacing.xl),
            Text(
              'Pass to',
              style: AppTextStyles.body.copyWith(color: palette.textSecondary),
            ),
            verticalSpace(AppSpacing.xs),
            FittedBox(
              child: Text(
                player.name,
                maxLines: 1,
                style: AppTextStyles.displayMedium.copyWith(color: palette.textPrimary),
              ),
            ),
            if (hasScores) ...<Widget>[
              verticalSpace(AppSpacing.section),
              _RunningTotals(standings: standings),
            ],
            verticalSpace(AppSpacing.section),
            AppButton(
              label: "I'm ready",
              size: AppButtonSize.large,
              expand: false,
              trailingIcon: Icons.arrow_forward_rounded,
              onPressed: onReady,
            ),
            verticalSpace(AppSpacing.md),
            Text(
              'The clock starts when you tap',
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w500,
                color: palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The table so far, as a single quiet line of name-and-score pairs.
///
/// Deliberately not the full standings screen: this is a glance during a
/// handover, not a results page.
class _RunningTotals extends StatelessWidget {
  const _RunningTotals({required this.standings});

  final List<PartyStanding> standings;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.md,
      children: <Widget>[
        for (final PartyStanding standing in standings)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '${standing.points}',
                style: AppTextStyles.scoreSmall.copyWith(
                  color: standing.isWinner ? palette.accent : palette.textSecondary,
                ),
              ),
              verticalSpace(2),
              SizedBox(
                width: 64,
                child: Text(
                  standing.player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.overline.copyWith(color: palette.textMuted),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
