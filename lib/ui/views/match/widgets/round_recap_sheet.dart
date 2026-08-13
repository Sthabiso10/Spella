import 'package:flutter/material.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/core/models/score_breakdown.dart';
import 'package:spella/core/models/word_definition.dart';
import 'package:spella/core/models/word_play.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/app_badge.dart';
import 'package:spella/ui/widgets/app_buttons.dart';
import 'package:spella/ui/widgets/app_card.dart';
import 'package:spella/ui/widgets/app_states.dart';

/// End of round summary: both words, how the points were earned, and what the
/// best play would have been.
///
/// The verdict is the headline and the two scores are the largest figures on
/// it, because the only question the player has at this moment is whether they
/// took the round. Everything else - the breakdown, the best word, the meaning
/// - is there to be read second.
class RoundRecapSheet extends StatelessWidget {
  const RoundRecapSheet({
    required this.roundNumber,
    required this.me,
    required this.opponent,
    required this.myPlay,
    required this.opponentPlay,
    required this.bestPossibleWord,
    required this.definition,
    required this.isLoadingDefinition,
    required this.isFinalRound,
    required this.onContinue,
    super.key,
  });

  final int roundNumber;
  final Player me;
  final Player opponent;
  final WordPlay? myPlay;
  final WordPlay? opponentPlay;
  final String bestPossibleWord;

  /// Meaning of the round's standout word. `null` until the lookup lands, or
  /// permanently when there is no entry or no connection.
  final WordDefinition? definition;

  final bool isLoadingDefinition;
  final bool isFinalRound;
  final VoidCallback onContinue;

  int get _myScore => myPlay?.score ?? 0;

  int get _theirScore => opponentPlay?.score ?? 0;

  String get _verdict {
    if (_myScore > _theirScore) return 'Round $roundNumber is yours';
    if (_myScore < _theirScore) return '${opponent.username} takes it';
    return 'Round $roundNumber is a tie';
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool didWin = _myScore > _theirScore;
    final bool didLose = _myScore < _theirScore;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: AppCard(
            floats: true,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  didWin
                      ? 'WON'
                      : didLose
                      ? 'LOST'
                      : 'TIED',
                  style: AppTextStyles.overline.copyWith(
                    color: didWin
                        ? palette.success
                        : didLose
                        ? palette.textMuted
                        : palette.textSecondary,
                  ),
                ),
                verticalSpace(AppSpacing.sm),
                Text(
                  _verdict,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headingMedium.copyWith(color: palette.textPrimary),
                ),
                verticalSpace(AppSpacing.xl),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: _PlayColumn(label: 'You', play: myPlay, isWinner: didWin),
                      ),
                      VerticalDivider(width: 1, color: palette.divider),
                      Expanded(
                        child: _PlayColumn(
                          label: opponent.username,
                          play: opponentPlay,
                          isWinner: didLose,
                        ),
                      ),
                    ],
                  ),
                ),
                if (bestPossibleWord.isNotEmpty) ...<Widget>[
                  verticalSpace(AppSpacing.xl),
                  _BestWordStrip(word: bestPossibleWord),
                ],
                _DefinitionPanel(definition: definition, isLoading: isLoadingDefinition),
                verticalSpace(AppSpacing.xl),
                AppButton(
                  label: isFinalRound ? 'See Results' : 'Next Round',
                  size: AppButtonSize.large,
                  trailingIcon: Icons.arrow_forward_rounded,
                  onPressed: onContinue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What the best available play would have been.
///
/// Framed as information rather than as a reprimand - it sits in the same quiet
/// recessed strip whether the player was two points off it or forty.
class _BestWordStrip extends StatelessWidget {
  const _BestWordStrip({required this.word});

  final String word;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(color: palette.recess, borderRadius: AppRadius.control),
      child: Column(
        children: <Widget>[
          Text(
            'BEST WORD ON THAT RACK',
            style: AppTextStyles.overline.copyWith(color: palette.textMuted),
          ),
          verticalSpace(AppSpacing.sm),
          FittedBox(
            child: Text(
              word,
              style: AppTextStyles.wordmark.copyWith(
                fontSize: 18,
                letterSpacing: 3,
                color: palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What the round's standout word means.
///
/// Collapses to nothing when there is no definition, so an offline player sees
/// a tidy recap rather than an error.
class _DefinitionPanel extends StatelessWidget {
  const _DefinitionPanel({required this.definition, required this.isLoading});

  final WordDefinition? definition;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    if (isLoading) {
      // The definition arrives late and lands in a known shape, so the space it
      // will occupy is held open rather than filled with a spinner. Nothing
      // jumps when the lookup returns.
      return const Padding(
        padding: EdgeInsets.only(top: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AppSkeleton(height: 13, width: 96),
            SizedBox(height: AppSpacing.sm),
            AppSkeleton(height: 11),
            SizedBox(height: AppSpacing.xs + 2),
            AppSkeleton(height: 11, width: 140),
          ],
        ),
      );
    }

    final WordDefinition? entry = definition;
    if (entry == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            children: <Widget>[
              Text(
                entry.display,
                style: AppTextStyles.label.copyWith(color: palette.textPrimary),
              ),
              if (entry.pronunciation != null)
                Text(
                  entry.pronunciation!,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: palette.textMuted,
                  ),
                ),
              if (entry.partOfSpeech != null)
                Text(
                  entry.partOfSpeech!,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: palette.textMuted,
                  ),
                ),
            ],
          ),
          verticalSpace(AppSpacing.xs),
          Text(
            entry.definition,
            style: AppTextStyles.bodySmall.copyWith(color: palette.textSecondary),
          ),
          if (entry.attribution != null) ...<Widget>[
            verticalSpace(AppSpacing.sm),
            // The source is CC BY-SA, which requires crediting it.
            Text(
              entry.attribution!,
              style: AppTextStyles.overline.copyWith(
                fontSize: 9.5,
                letterSpacing: 0.3,
                color: palette.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One player's word and score breakdown.
class _PlayColumn extends StatelessWidget {
  const _PlayColumn({required this.label, required this.play, required this.isWinner});

  final String label;
  final WordPlay? play;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final ScoreBreakdown? breakdown = play?.breakdown;
    final bool didPass = play == null || play!.isPass;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.overline.copyWith(color: palette.textMuted),
          ),
          verticalSpace(AppSpacing.sm),
          FittedBox(
            child: Text(
              didPass ? '—' : play!.display,
              maxLines: 1,
              style: AppTextStyles.wordmark.copyWith(
                fontSize: 15,
                letterSpacing: 2,
                color: didPass ? palette.textMuted : palette.textPrimary,
              ),
            ),
          ),
          verticalSpace(AppSpacing.sm),
          Text(
            '${play?.score ?? 0}',
            style: AppTextStyles.scoreLarge.copyWith(
              fontSize: 40,
              color: isWinner ? palette.accent : palette.textSecondary,
            ),
          ),
          if (breakdown != null && !breakdown.isEmpty) ...<Widget>[
            verticalSpace(AppSpacing.md),
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
      ),
    );
  }
}
