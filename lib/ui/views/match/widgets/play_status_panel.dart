import 'package:flutter/material.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/count_up_text.dart';

/// The live verdict on the word being built.
///
/// This is the focal point of the game screen. A playable word puts its value
/// up in the largest figure in the app, in the one green the product owns;
/// anything else states the problem in a quiet line and gets out of the way.
/// The difference between those two states is the game's core feedback loop, so
/// it is carried by size, weight and colour all at once.
///
/// Shared by the duel and the party board. They are different games with
/// different turn structures, but this particular reading of "what is my word
/// worth right now" is the same instrument in both, and it should never drift
/// between them.
class PlayStatusPanel extends StatelessWidget {
  const PlayStatusPanel({
    required this.isValid,
    required this.score,
    required this.message,
    super.key,
  });

  /// Whether the word on the board can be played.
  final bool isValid;

  /// What it is currently worth.
  final int score;

  /// Why it cannot be played, when it cannot.
  final String message;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return AnimatedSwitcher(
      duration: AppMotion.quick,
      switchInCurve: AppMotion.enter,
      transitionBuilder: (Widget child, Animation<double> animation) =>
          FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
              child: child,
            ),
          ),
      child: isValid
          ? Column(
              key: const ValueKey<String>('valid'),
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Pops on every change, so adding a letter that jumps the
                // score is something the player feels rather than has to
                // notice.
                PulseOnChange(
                  value: score,
                  child: Text(
                    '+$score',
                    style: AppTextStyles.scoreLarge.copyWith(color: palette.success),
                  ),
                ),
                verticalSpace(AppSpacing.sm),
                Text(
                  'POINTS IF YOU PLAY NOW',
                  style: AppTextStyles.overline.copyWith(color: palette.textMuted),
                ),
              ],
            )
          : Text(
              message,
              key: ValueKey<String>(message),
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: palette.textMuted),
            ),
    );
  }
}

/// What a finished play was worth, itemised.
///
/// Used wherever a score needs explaining after the fact rather than
/// previewed live - the party turn result, and the recaps.
class ScoreArrival extends StatelessWidget {
  const ScoreArrival({
    required this.score,
    this.color,
    this.fontSize = 56,
    super.key,
  });

  final int score;
  final Color? color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return CountUpText(
      value: score,
      // Rolls from nothing, because this figure's arrival is the event.
      from: 0,
      style: AppTextStyles.scoreLarge.copyWith(
        fontSize: fontSize,
        color: color ?? palette.textPrimary,
      ),
    );
  }
}
