import 'package:flutter/material.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/app_avatar.dart';
import 'package:spella/ui/widgets/app_buttons.dart';

/// A friend, their record, and the way to start a game with them.
///
/// A player is an identity, not a database row, so the layout leads with the
/// face and the name and keeps the numbers to a single quiet line underneath.
/// Offline friends are dimmed rather than removed - they are still people you
/// know, just not people you can get a game out of this minute.
///
/// Starting a match is the button's job and only the button's job. The whole
/// row used to be the target, which meant a thumb landing anywhere near a name
/// while scrolling committed the player to a game against them - an action with
/// no undo, fired by a gesture they never made.
class FriendRow extends StatelessWidget {
  const FriendRow({required this.friend, required this.onChallenge, super.key});

  final Player friend;
  final VoidCallback onChallenge;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool isOnline = friend.isOnline;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Opacity(
            opacity: isOnline ? 1 : 0.5,
            child: AppAvatar(
              player: friend,
              size: 40,
              showPresence: true,
              ring: AvatarRing.none,
            ),
          ),
          horizontalSpace(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  friend.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong.copyWith(
                    fontSize: 14,
                    color: isOnline ? palette.textPrimary : palette.textSecondary,
                  ),
                ),
                verticalSpace(2),
                Text(
                  'Lvl ${friend.level} · ${friend.wins}W ${friend.losses}L'
                  '${isOnline ? '' : ' · Offline'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          horizontalSpace(AppSpacing.md),
          // Only a friend who is actually there gets the solid button. The
          // action still works when they are offline, it just stops shouting.
          AppButton(
            label: 'Challenge',
            expand: false,
            size: AppButtonSize.small,
            style: isOnline ? AppButtonStyle.secondary : AppButtonStyle.ghost,
            onPressed: onChallenge,
          ),
        ],
      ),
    );
  }
}
