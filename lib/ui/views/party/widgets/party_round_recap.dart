import 'package:flutter/material.dart';
import 'package:spella/core/models/word_play.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/views/party/party_match_viewmodel.dart';
import 'package:spella/ui/widgets/app_avatar.dart';
import 'package:spella/ui/widgets/app_buttons.dart';
import 'package:spella/ui/widgets/app_card.dart';

/// Everyone's word for the round, side by side.
///
/// The moment the whole mode exists for: five people who have each been staring
/// at the same seven letters finally get to see what everyone else found. So
/// the words are the content here, set at full size and ordered by score, with
/// the round's winner marked and the best possible word held back to the
/// bottom where it reads as trivia rather than as a scolding.
class PartyRoundRecap extends StatelessWidget {
  const PartyRoundRecap({
    required this.roundNumber,
    required this.lines,
    required this.bestPossibleWord,
    required this.isFinalRound,
    required this.onContinue,
    super.key,
  });

  final int roundNumber;
  final List<PartyRoundLine> lines;
  final String bestPossibleWord;
  final bool isFinalRound;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final List<PartyRoundLine> winners = lines
        .where((PartyRoundLine line) => line.isWinner)
        .toList(growable: false);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AppCard(
          floats: true,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'ROUND $roundNumber',
                style: AppTextStyles.overline.copyWith(color: palette.textMuted),
              ),
              verticalSpace(AppSpacing.sm),
              Text(
                _verdict(winners),
                textAlign: TextAlign.center,
                style: AppTextStyles.headingMedium.copyWith(color: palette.textPrimary),
              ),
              verticalSpace(AppSpacing.xl),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (int i = 0; i < lines.length; i++) ...<Widget>[
                        _RecapLine(line: lines[i]),
                        if (i != lines.length - 1) const AppDivider(indent: 44),
                      ],
                    ],
                  ),
                ),
              ),
              if (bestPossibleWord.isNotEmpty) ...<Widget>[
                verticalSpace(AppSpacing.xl),
                _BestWordStrip(word: bestPossibleWord),
              ],
              verticalSpace(AppSpacing.xl),
              AppButton(
                label: isFinalRound ? 'See Standings' : 'Next Round',
                size: AppButtonSize.large,
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _verdict(List<PartyRoundLine> winners) {
    if (winners.isEmpty) return 'Nobody scored';
    if (winners.length == 1) return '${winners.first.player.name} takes it';
    if (winners.length == lines.length) return 'All square';
    return '${winners.length} way tie';
  }
}

/// One player's word and score.
class _RecapLine extends StatelessWidget {
  const _RecapLine({required this.line});

  final PartyRoundLine line;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final WordPlay? play = line.play;
    final bool didPass = play == null || play.isPass;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          AppAvatar(
            player: line.player.asPlayer,
            size: 32,
            ring: line.isWinner ? AvatarRing.accent : AvatarRing.none,
          ),
          horizontalSpace(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  line.player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.overline.copyWith(color: palette.textMuted),
                ),
                verticalSpace(3),
                Text(
                  didPass ? 'Passed' : play.display,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.wordmark.copyWith(
                    fontSize: 16,
                    letterSpacing: didPass ? 0 : 2.5,
                    color: didPass
                        ? palette.textMuted
                        : line.isWinner
                        ? palette.textPrimary
                        : palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          horizontalSpace(AppSpacing.md),
          Text(
            '${play?.score ?? 0}',
            style: AppTextStyles.score.copyWith(
              fontSize: 24,
              color: line.isWinner ? palette.accent : palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// What the rack was actually worth, for the inevitable argument about it.
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
