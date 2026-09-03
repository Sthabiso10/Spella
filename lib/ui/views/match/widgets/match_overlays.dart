import 'package:flutter/material.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/app_avatar.dart';
import 'package:spella/ui/widgets/app_buttons.dart';
import 'package:spella/ui/widgets/app_progress.dart';

/// Fades whichever overlay is current in, and the last one out.
///
/// The overlays used to be plain `if` branches in a [Stack], which meant they
/// faded in over a quarter of a second and then vanished between two frames.
/// Every round boundary was a hard cut. Routing them through one switcher gives
/// them an exit as well as an entrance, and guarantees only ever one is up.
class MatchOverlaySlot extends StatelessWidget {
  const MatchOverlaySlot({required this.child, super.key});

  /// The overlay to show, or `null` for none.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        // An overlay on its way out must not keep swallowing taps meant for
        // the board that is coming back.
        ignoring: child == null,
        child: AnimatedSwitcher(
          duration: AppMotion.normal,
          switchInCurve: AppMotion.enter,
          switchOutCurve: AppMotion.standard,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Dimmed backdrop shared by the match overlays.
///
/// Nearly opaque rather than translucent: these moments are meant to interrupt,
/// and a half-visible board underneath invites the player to keep tapping at
/// something that has already stopped listening.
///
/// The fade belongs to [MatchOverlaySlot]; this only paints and centres.
class MatchScrim extends StatelessWidget {
  const MatchScrim({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.palette.scrim,
      child: Center(child: child),
    );
  }
}

/// Settles [child] into place as its overlay arrives.
///
/// A restrained scale rather than a slide, so an overlay that covers the board
/// reads as landing on top of it instead of flying in from somewhere.
class OverlayEntrance extends StatelessWidget {
  const OverlayEntrance({required this.child, this.from = 0.94, super.key});

  final Widget child;
  final double from;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppMotion.entrance,
      curve: AppMotion.settle,
      builder: (BuildContext context, double value, Widget? animatedChild) =>
          Transform.scale(scale: from + value * (1 - from), child: animatedChild),
      child: child,
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
      child: OverlayEntrance(
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
      child: OverlayEntrance(
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
      ),
    );
  }
}

/// Holds the game while the player is somewhere else.
///
/// Reached when the app is backgrounded mid-round, and in a party game from
/// the pause button. It states the clock is stopped, because the whole worry
/// when a game vanishes off screen is that it is still running.
class PausedOverlay extends StatelessWidget {
  const PausedOverlay({
    required this.secondsRemaining,
    required this.onResume,
    this.title = 'Paused',
    this.onQuit,
    super.key,
  });

  final int secondsRemaining;
  final VoidCallback onResume;
  final String title;

  /// Offered as a quiet secondary action, never as the obvious one.
  final VoidCallback? onQuit;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return MatchScrim(
      child: OverlayEntrance(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.pause_rounded, size: 40, color: palette.textMuted),
              verticalSpace(AppSpacing.lg),
              Text(
                title,
                style: AppTextStyles.displayMedium.copyWith(color: palette.textPrimary),
              ),
              verticalSpace(AppSpacing.sm),
              Text(
                '${formatClock(secondsRemaining)} STILL ON THE CLOCK',
                style: AppTextStyles.overline.copyWith(color: palette.textMuted),
              ),
              verticalSpace(AppSpacing.section),
              AppButton(
                label: 'Resume',
                size: AppButtonSize.large,
                expand: false,
                trailingIcon: Icons.play_arrow_rounded,
                onPressed: onResume,
              ),
              if (onQuit != null) ...<Widget>[
                verticalSpace(AppSpacing.md),
                AppButton(
                  label: 'End game',
                  style: AppButtonStyle.ghost,
                  expand: false,
                  onPressed: onQuit,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Counts a player in before their clock starts.
///
/// The number is keyed so each tick is its own widget: it swaps rather than
/// re-renders, which is what makes it read as a count rather than as a label
/// that keeps changing.
class CountdownOverlay extends StatelessWidget {
  const CountdownOverlay({
    required this.secondsRemaining,
    required this.playerName,
    super.key,
  });

  final int secondsRemaining;
  final String playerName;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return MatchScrim(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            playerName.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTextStyles.overline.copyWith(color: palette.textMuted),
          ),
          verticalSpace(AppSpacing.lg),
          AnimatedSwitcher(
            duration: AppMotion.quick,
            transitionBuilder: (Widget child, Animation<double> animation) =>
                FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.4, end: 1).animate(
                      CurvedAnimation(parent: animation, curve: AppMotion.enter),
                    ),
                    child: child,
                  ),
                ),
            child: Text(
              '$secondsRemaining',
              key: ValueKey<int>(secondsRemaining),
              style: AppTextStyles.displayLarge.copyWith(
                fontSize: 88,
                color: palette.textPrimary,
              ),
            ),
          ),
          verticalSpace(AppSpacing.lg),
          Text(
            'GET READY',
            style: AppTextStyles.overline.copyWith(color: palette.accent),
          ),
        ],
      ),
    );
  }
}
