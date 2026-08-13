import 'package:flutter/material.dart';
import 'package:spella/core/models/social.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/app_avatar.dart';
import 'package:spella/ui/widgets/app_badge.dart';
import 'package:spella/ui/widgets/app_buttons.dart';
import 'package:spella/ui/widgets/app_card.dart';

/// A pending challenge, with accept and decline.
///
/// The only card in the app that carries an accent outline by default: an
/// invite is the one thing on the screen that is waiting on the player and will
/// eventually expire. Accept takes the full-contrast button and decline is a
/// quiet icon, because the two are not equally likely and should not look it.
class InviteCard extends StatelessWidget {
  const InviteCard({
    required this.invite,
    required this.onAccept,
    required this.onDecline,
    super.key,
  });

  final GameInvite invite;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return AppCard(
      isAccented: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppAvatar(
                player: invite.from,
                size: 40,
                showPresence: true,
                ring: AvatarRing.accent,
              ),
              horizontalSpace(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      invite.from.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong.copyWith(
                        fontSize: 14,
                        color: palette.textPrimary,
                      ),
                    ),
                    verticalSpace(2),
                    Text(
                      'Challenged you · ${formatRelativeTime(invite.sentAt)}',
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
              horizontalSpace(AppSpacing.sm),
              AppBadge(label: invite.mode.label, tone: BadgeTone.accent),
            ],
          ),
          verticalSpace(AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  label: 'Accept',
                  icon: Icons.sports_esports_outlined,
                  style: AppButtonStyle.accent,
                  onPressed: onAccept,
                ),
              ),
              horizontalSpace(AppSpacing.sm),
              AppIconButton(
                icon: Icons.close_rounded,
                tooltip: 'Decline',
                onPressed: onDecline,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
