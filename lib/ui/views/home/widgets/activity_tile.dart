import 'package:flutter/material.dart';
import 'package:spella/core/models/social.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/app_avatar.dart';
import 'package:spella/ui/widgets/pressable.dart';

/// One entry in the friend activity feed.
///
/// A feed is a stream, not a set of objects, so these are rows on the page
/// rather than cards. Six stacked cards read as six things to deal with; six
/// rows read as something to skim, which is what a feed is for.
class ActivityTile extends StatelessWidget {
  const ActivityTile({required this.activity, required this.onLike, super.key});

  final FriendActivity activity;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppAvatar(
            player: activity.player,
            size: 34,
            ring: AvatarRing.none,
            showPresence: true,
          ),
          horizontalSpace(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: activity.player.username,
                        style: AppTextStyles.bodyStrong.copyWith(
                          fontSize: 14,
                          color: palette.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: ' ${activity.headline}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 14,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                verticalSpace(3),
                Row(
                  children: <Widget>[
                    Icon(_iconFor(activity.kind), size: 12, color: palette.textMuted),
                    horizontalSpace(AppSpacing.xs + 1),
                    Flexible(
                      child: Text(
                        '${activity.detail} · ${formatRelativeTime(activity.occurredAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: palette.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          horizontalSpace(AppSpacing.sm),
          _LikeButton(isLiked: activity.isLiked, onPressed: onLike),
        ],
      ),
    );
  }

  IconData _iconFor(ActivityKind kind) => switch (kind) {
    ActivityKind.wordPlayed => Icons.text_fields_rounded,
    ActivityKind.badgeUnlocked => Icons.military_tech_outlined,
    ActivityKind.matchWon => Icons.emoji_events_outlined,
    ActivityKind.levelUp => Icons.trending_up_rounded,
  };
}

/// The like control, which pops as it fills.
///
/// The scale is the whole reward here - a heart that simply changes colour
/// gives no sense that the tap registered.
class _LikeButton extends StatelessWidget {
  const _LikeButton({required this.isLiked, required this.onPressed});

  final bool isLiked;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Pressable(
      onPressed: onPressed,
      scale: 0.8,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: AnimatedSwitcher(
          duration: AppMotion.quick,
          transitionBuilder: (Widget child, Animation<double> animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey<bool>(isLiked),
            size: 17,
            color: isLiked ? palette.danger : palette.textMuted,
          ),
        ),
      ),
    );
  }
}
