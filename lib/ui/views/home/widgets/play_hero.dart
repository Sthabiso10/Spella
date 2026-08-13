import 'package:flutter/material.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/app_avatar.dart';
import 'package:spella/ui/widgets/app_buttons.dart';
import 'package:spella/ui/widgets/pressable.dart';
import 'package:spella/ui/widgets/section_header.dart';

/// The top of Home: what is being asked of the player, the way into a game,
/// and who is waiting on them.
///
/// Deliberately not a card. This is the page's opening statement, and boxing it
/// would make it one object among several instead of the thing the screen is
/// about. Hierarchy comes from type size and from the amount of air around the
/// button - which is the only high-contrast element above the fold.
class PlayHero extends StatelessWidget {
  const PlayHero({
    required this.title,
    required this.subtitle,
    required this.waitingFriends,
    required this.onPlay,
    required this.onFriendTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Player> waitingFriends;
  final VoidCallback onPlay;
  final ValueChanged<Player> onFriendTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: AppTextStyles.headingLarge.copyWith(color: palette.textPrimary),
        ),
        verticalSpace(AppSpacing.sm),
        Text(subtitle, style: AppTextStyles.body.copyWith(color: palette.textSecondary)),
        verticalSpace(AppSpacing.xl),
        AppButton(
          label: 'Start New Game',
          icon: Icons.play_arrow_rounded,
          size: AppButtonSize.large,
          onPressed: onPlay,
        ),
        if (waitingFriends.isNotEmpty) ...<Widget>[
          verticalSpace(AppSpacing.xl),
          const SectionHeader(title: 'Waiting on you', accentDot: true),
          verticalSpace(AppSpacing.md),
          SizedBox(
            height: scaledSize(context, 44),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: waitingFriends.length,
              separatorBuilder: (BuildContext context, int index) =>
                  horizontalSpace(AppSpacing.sm),
              itemBuilder: (BuildContext context, int index) => _WaitingFriend(
                friend: waitingFriends[index],
                isYourTurn: index == 0,
                onTap: () => onFriendTap(waitingFriends[index]),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// An open game with one friend.
///
/// Each of these is a real pending object, which is what earns it an outline.
/// The state sits under the name in the smallest type on the screen, because
/// you only need it once you have already found the person you were looking for.
class _WaitingFriend extends StatelessWidget {
  const _WaitingFriend({
    required this.friend,
    required this.isYourTurn,
    required this.onTap,
  });

  final Player friend;
  final bool isYourTurn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Pressable(
      onPressed: onTap,
      scale: 0.96,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs + 2,
          AppSpacing.xs + 2,
          AppSpacing.md,
          AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: AppRadius.pill,
          border: Border.all(color: isYourTurn ? palette.accentBorder : palette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppAvatar(
              player: friend,
              size: 28,
              ring: AvatarRing.none,
              showPresence: true,
            ),
            horizontalSpace(AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  friend.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(color: palette.textPrimary),
                ),
                Text(
                  isYourTurn ? 'Your turn' : 'Waiting',
                  style: AppTextStyles.overline.copyWith(
                    fontSize: 9,
                    color: isYourTurn ? palette.accent : palette.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
