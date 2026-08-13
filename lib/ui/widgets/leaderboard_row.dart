import 'package:flutter/material.dart';
import 'package:spella/core/models/social.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/app_avatar.dart';
import 'package:spella/ui/widgets/pressable.dart';

/// A ranked player, used on both the home preview and the full board.
///
/// Not a card and not a table row. The rank is set in the same tabular figures
/// as the score so the two columns stay in vertical register down the whole
/// list, and everything between them is just a person.
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    required this.entry,
    this.dense = false,
    this.onTap,
    this.horizontalPadding = AppSpacing.md,
    super.key,
  });

  final LeaderboardEntry entry;

  /// Compact layout for the home screen preview.
  final bool dense;

  final VoidCallback? onTap;

  /// Inset inside the row's own highlight box.
  ///
  /// Callers pull their list back by this amount so the rank numeral still
  /// lines up with the page gutter, while the highlight on the player's own row
  /// keeps a little air around it.
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool isMe = entry.isCurrentUser;

    // Podium places are brighter rather than gold, silver and bronze. Three
    // metals on a monochrome board would be the loudest thing in the app, and
    // they say nothing the position and the score do not already say.
    final Color rankInk = switch (entry.rank) {
      1 => palette.accent,
      2 || 3 => palette.textSecondary,
      _ => palette.textMuted,
    };

    final Widget row = AnimatedContainer(
      duration: AppMotion.quick,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: dense ? AppSpacing.sm + 2 : AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isMe ? palette.surfaceElevated : Colors.transparent,
        borderRadius: AppRadius.card,
        border: Border.all(color: isMe ? palette.border : Colors.transparent),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: dense ? 20 : 26,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.left,
              style: AppTextStyles.rank.copyWith(
                fontSize: dense ? 13 : 15,
                color: rankInk,
              ),
            ),
          ),
          horizontalSpace(AppSpacing.md),
          AppAvatar(
            player: entry.player,
            size: dense ? 30 : 38,
            ring: entry.rank == 1 ? AvatarRing.accent : AvatarRing.subtle,
          ),
          horizontalSpace(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isMe ? 'You' : entry.player.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(color: palette.textPrimary),
                ),
                if (!dense) ...<Widget>[
                  verticalSpace(2),
                  Text(
                    'Lvl ${entry.player.level} · ${entry.player.winRate}% wins',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          horizontalSpace(AppSpacing.sm),
          Text(
            formatPoints(entry.points),
            style: AppTextStyles.scoreSmall.copyWith(
              fontSize: dense ? 15 : 17,
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );

    return onTap == null ? row : Pressable(onPressed: onTap, child: row);
  }
}
