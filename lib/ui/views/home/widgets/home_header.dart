import 'package:flutter/material.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/app_avatar.dart';
import 'package:spella/ui/widgets/app_badge.dart';
import 'package:spella/ui/widgets/app_progress.dart';

/// The top of Home: who is signed in, what they are carrying, and how far they
/// are through their current level.
///
/// The level bar is the piece that used to be missing. A player's level was
/// shown as a chip on their own avatar and nowhere else, which named the number
/// without ever explaining it - you could not tell whether you were one word or
/// ten matches away from the next one. Here the level, the bar and the exact XP
/// sit on the same two lines, so the number finally means something.
class HomeHeader extends StatelessWidget {
  const HomeHeader({required this.player, required this.greeting, super.key});

  final Player player;
  final String greeting;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              // No level chip on the face: the strip below says it properly,
              // and saying it twice in one header is how a header gets noisy.
              AppAvatar(player: player, size: 42),
              horizontalSpace(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      greeting.toUpperCase(),
                      style: AppTextStyles.overline.copyWith(color: palette.textMuted),
                    ),
                    verticalSpace(2),
                    Text(
                      player.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              horizontalSpace(AppSpacing.md),
              // A streak only exists while it is running, so the flame is
              // absent rather than shown at zero - which would read as a
              // permanent part of the chrome instead of something you earned.
              if (player.streak > 0) ...<Widget>[
                AppInlineStat(
                  icon: Icons.local_fire_department_rounded,
                  value: '${player.streak}',
                  tone: palette.accent,
                ),
                horizontalSpace(AppSpacing.lg),
              ],
              AppInlineStat(
                icon: Icons.monetization_on_outlined,
                value: formatPoints(player.coins),
              ),
            ],
          ),
          verticalSpace(AppSpacing.xl),
          // Both ends flexible rather than a fixed pair either side of a
          // Spacer: at the largest text scale on the narrowest phone the two
          // labels want more width than the line has, and a Spacer has no give
          // in it. This way they meet in the middle and the XP figure - the
          // half the bar underneath already draws - is the one that clips.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Text(
                  'Level ${player.level}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(color: palette.textSecondary),
                ),
              ),
              horizontalSpace(AppSpacing.sm),
              Flexible(
                child: Text(
                  '${formatPoints(player.xp)} / ${formatPoints(player.xpForNextLevel)} XP',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.labelSmall.copyWith(color: palette.textMuted),
                ),
              ),
            ],
          ),
          verticalSpace(AppSpacing.sm),
          AppProgressBar(value: player.levelProgress),
        ],
      ),
    );
  }
}
