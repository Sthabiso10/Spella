import 'package:flutter/material.dart';
import 'package:spella/core/models/party.dart';
import 'package:spella/core/models/score_breakdown.dart';
import 'package:spella/core/models/word_play.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/views/match/widgets/match_overlays.dart';
import 'package:spella/ui/views/match/widgets/play_status_panel.dart';
import 'package:spella/ui/widgets/app_avatar.dart';
import 'package:spella/ui/widgets/app_badge.dart';
import 'package:spella/ui/widgets/app_buttons.dart';
import 'package:spella/ui/widgets/app_card.dart';

/// What the turn just played was worth, shown to the person who played it.
///
/// The mode used to go straight from a submitted word to the next player's
/// handoff, so you never found out what your own word scored - you tapped Play
/// and the screen immediately belonged to somebody else. This is the beat that
/// was missing: your word, what it earned, and where that leaves you, held
/// until you hand the device on yourself.
///
/// It deliberately shows only the player's own line. Everyone else's words are
/// still secret until the round recap, which is the moment the mode is built
/// around.
class TurnResultOverlay extends StatelessWidget {
  const TurnResultOverlay({
    required this.player,
    required this.play,
    required this.total,
    required this.nextPlayer,
    required this.isRoundComplete,
    required this.onContinue,
    super.key,
  });

  final PartyPlayer player;
  final WordPlay play;

  /// The player's running total, including this turn.
  final int total;

  /// Who is up next, or `null` when the round is done.
  final PartyPlayer? nextPlayer;

  final bool isRoundComplete;
  final VoidCallback onContinue;

  String get _continueLabel {
    if (isRoundComplete || nextPlayer == null) return 'See the round';
    return 'Pass to ${nextPlayer!.name}';
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final ScoreBreakdown breakdown = play.breakdown;
    final bool didPass = play.isPass;

    return MatchScrim(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SingleChildScrollView(
            child: OverlayEntrance(
              child: AppCard(
                floats: true,
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AppAvatar(
                      player: player.asPlayer,
                      size: 48,
                      ring: didPass ? AvatarRing.subtle : AvatarRing.accent,
                    ),
                    verticalSpace(AppSpacing.md),
                    Text(
                      player.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.overline.copyWith(color: palette.textMuted),
                    ),
                    verticalSpace(AppSpacing.xl),
                    if (didPass) ...<Widget>[
                      Text(
                        'No word this round',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headingMedium.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                      verticalSpace(AppSpacing.sm),
                      Text(
                        'It happens. The rack moves on.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ] else ...<Widget>[
                      FittedBox(
                        child: Text(
                          play.display,
                          maxLines: 1,
                          style: AppTextStyles.wordmark.copyWith(
                            fontSize: 26,
                            letterSpacing: 4,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      verticalSpace(AppSpacing.lg),
                      ScoreArrival(score: play.score, color: palette.success),
                      verticalSpace(AppSpacing.xs),
                      Text(
                        'POINTS',
                        style: AppTextStyles.overline.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                      if (!breakdown.isEmpty) ...<Widget>[
                        verticalSpace(AppSpacing.lg),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: <Widget>[
                            if (breakdown.wordMultiplier > 1)
                              AppBadge(label: '×${breakdown.wordMultiplier} word'),
                            if (breakdown.lengthBonus > 0)
                              AppBadge(label: '+${breakdown.lengthBonus} length'),
                            if (breakdown.fullRackBonus > 0)
                              AppBadge(label: '+${breakdown.fullRackBonus} rack'),
                            if (breakdown.speedBonus > 0)
                              AppBadge(label: '+${breakdown.speedBonus} speed'),
                          ],
                        ),
                      ],
                    ],
                    verticalSpace(AppSpacing.xl),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: palette.recess,
                        borderRadius: AppRadius.control,
                      ),
                      child: Column(
                        children: <Widget>[
                          Text(
                            'YOUR TOTAL',
                            style: AppTextStyles.overline.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                          verticalSpace(AppSpacing.xs),
                          Text(
                            '$total',
                            style: AppTextStyles.score.copyWith(
                              color: palette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    verticalSpace(AppSpacing.xl),
                    // Nothing moves until the player says so. The device is
                    // about to change hands, and an automatic transition here
                    // would hand it on before they had read their own score.
                    AppButton(
                      label: _continueLabel,
                      size: AppButtonSize.large,
                      trailingIcon: Icons.arrow_forward_rounded,
                      onPressed: onContinue,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
