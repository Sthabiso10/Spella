import 'package:flutter/material.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/app_buttons.dart';
import 'package:spella/ui/widgets/app_progress.dart';
import 'package:spella/ui/widgets/count_up_text.dart';

/// Top of the match screen: leave, the clock, and which round this is.
///
/// The clock is the largest thing in the header because it is the only thing
/// in it that changes. It is set in tabular figures so the digits do not shift
/// the layout every second, and the round counter is deliberately small - you
/// check it once and then forget about it.
class MatchHeader extends StatelessWidget {
  const MatchHeader({
    required this.secondsRemaining,
    required this.progress,
    required this.isCritical,
    required this.roundNumber,
    required this.totalRounds,
    required this.onLeave,
    this.onPause,
    super.key,
  });

  final int secondsRemaining;

  /// Fraction of the round clock left, 0..1.
  final double progress;

  /// Switches the clock to its warning treatment.
  final bool isCritical;

  final int roundNumber;
  final int totalRounds;
  final VoidCallback onLeave;

  /// Shows a pause control when non-null. Offered in a party game, where the
  /// device is going round a table and somebody always needs a minute; not in
  /// a duel, where stopping the clock to think would be the whole exploit.
  final VoidCallback? onPause;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final Color clockInk = isCritical ? palette.danger : palette.textPrimary;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              AppIconButton(
                icon: Icons.arrow_back_rounded,
                size: 40,
                isTransparent: true,
                tooltip: 'Leave match',
                onPressed: onLeave,
              ),
              Expanded(
                child: Center(
                  // In the last ten seconds the clock ticks visibly as well as
                  // numerically. It is the only thing in the app that moves
                  // without being touched, which is exactly the point.
                  child: PulseOnChange(
                    value: isCritical ? secondsRemaining : 0,
                    scale: 1.08,
                    child: AnimatedDefaultTextStyle(
                      duration: AppMotion.normal,
                      style: AppTextStyles.timer.copyWith(color: clockInk),
                      child: Text(formatClock(secondsRemaining)),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '$roundNumber/$totalRounds',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.rank.copyWith(
                    fontSize: 13,
                    color: palette.textMuted,
                  ),
                ),
              ),
              if (onPause != null) ...<Widget>[
                horizontalSpace(AppSpacing.sm),
                AppIconButton(
                  icon: Icons.pause_rounded,
                  size: 40,
                  isTransparent: true,
                  tooltip: 'Pause',
                  onPressed: onPause,
                ),
              ],
            ],
          ),
        ),
        // The clock again, as a full-bleed hairline. It reads from across the
        // room, so the player can feel the round draining without ever taking
        // their eyes off the tiles.
        AppProgressBar(
          value: progress,
          height: 2,
          color: isCritical ? palette.danger : palette.accent,
          trackColor: palette.divider,
        ),
      ],
    );
  }
}
