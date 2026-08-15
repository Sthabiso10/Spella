import 'package:flutter/material.dart';
import 'package:spella/core/models/game_mode.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/app_avatar.dart';
import 'package:spella/ui/widgets/app_buttons.dart';
import 'package:spella/ui/widgets/pressable.dart';

/// The top of the page body: what is being asked of the player, who is waiting
/// on them, and the single fastest way into a game.
///
/// Deliberately not a card. This is the page's opening statement, and boxing it
/// would make it one object among several instead of the thing the screen is
/// about. Hierarchy comes from type size and from the amount of air around the
/// button - the only high-contrast element above the fold.
///
/// Order matters here: the people waiting come *above* the play button. If
/// somebody is mid-game with you, finishing that is more urgent than starting
/// another, and the layout should not make you scroll past the generic action
/// to find the specific one.
class PlayHero extends StatelessWidget {
  const PlayHero({
    required this.title,
    required this.subtitle,
    required this.quickMatchMode,
    required this.waitingFriends,
    required this.onPlay,
    required this.onFriendTap,
    super.key,
  });

  final String title;
  final String subtitle;

  /// The mode [onPlay] deals, named under the button so the player knows what
  /// they are agreeing to before they press it.
  final GameMode quickMatchMode;

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
        if (waitingFriends.isNotEmpty) ...<Widget>[
          verticalSpace(AppSpacing.lg),
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
        verticalSpace(AppSpacing.xl),
        AppButton(
          label: 'Quick match',
          icon: Icons.play_arrow_rounded,
          size: AppButtonSize.large,
          onPressed: onPlay,
        ),
        verticalSpace(AppSpacing.md),
        // Centred under a full-width button, which is the one place a caption
        // can sit without looking like the start of the next section.
        SizedBox(
          width: double.infinity,
          child: Text(
            '${quickMatchMode.label} · ${quickMatchMode.tagline} · vs the bot',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w500,
              color: palette.textMuted,
            ),
          ),
        ),
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
