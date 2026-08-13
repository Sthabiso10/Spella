import 'package:flutter/material.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/app_avatar.dart';
import 'package:spella/ui/widgets/app_progress.dart';

/// Dimmed backdrop shared by the match overlays.
///
/// Nearly opaque rather than translucent: these moments are meant to interrupt,
/// and a half-visible board underneath invites the player to keep tapping at
/// something that has already stopped listening.
class MatchScrim extends StatelessWidget {
  const MatchScrim({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppMotion.normal,
      curve: AppMotion.enter,
      builder: (BuildContext context, double value, Widget? animatedChild) => Opacity(
        opacity: value,
        child: ColoredBox(color: context.palette.scrim, child: animatedChild),
      ),
      child: Center(child: child),
    );
  }
}

/// Announces the round while the rack is dealt.
///
/// The one place in the app that uses the largest type available. It lasts just
/// over a second and it is what separates one round from the next, so it is
/// allowed to be the loudest thing on screen.
class DealOverlay extends StatelessWidget {
  const DealOverlay({
    required this.roundNumber,
    required this.totalRounds,
    required this.rackSize,
    super.key,
  });

  final int roundNumber;
  final int totalRounds;
  final int rackSize;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return MatchScrim(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: AppMotion.entrance,
        curve: AppMotion.settle,
        builder: (BuildContext context, double value, Widget? child) =>
            Transform.scale(scale: 0.94 + value * 0.06, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'ROUND $roundNumber',
              style: AppTextStyles.displayMedium.copyWith(
                letterSpacing: 2,
                color: palette.textPrimary,
              ),
            ),
            verticalSpace(AppSpacing.md),
            Text(
              'OF $totalRounds · $rackSize TILES',
              style: AppTextStyles.overline.copyWith(color: palette.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown while the opponent works out their answer.
///
/// The wait is manufactured suspense, so it is presented as suspense: their
/// face, their name, and a line that will not tell you how long it has left.
class OpponentThinkingOverlay extends StatelessWidget {
  const OpponentThinkingOverlay({required this.opponent, super.key});

  final Player opponent;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return MatchScrim(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppAvatar(player: opponent, size: 64, ring: AvatarRing.accent),
          verticalSpace(AppSpacing.lg),
          Text(
            opponent.username,
            style: AppTextStyles.headingSmall.copyWith(color: palette.textPrimary),
          ),
          verticalSpace(AppSpacing.xs),
          Text(
            'IS THINKING',
            style: AppTextStyles.overline.copyWith(color: palette.textMuted),
          ),
          verticalSpace(AppSpacing.xl),
          const AppIndeterminateBar(width: 96),
        ],
      ),
    );
  }
}
