import 'package:flutter/material.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/app_avatar.dart';
import 'package:spella/ui/widgets/app_buttons.dart';
import 'package:spella/ui/widgets/app_card.dart';

/// A matchmaking suggestion, sized for a horizontal shelf.
///
/// Boxed where the friend list is not, which is the point: these are picks
/// being offered rather than a list being browsed, and the card is what says so
/// without needing a label to explain it.
class SuggestedMatchCard extends StatelessWidget {
  const SuggestedMatchCard({required this.player, required this.onChallenge, super.key});

  final Player player;
  final VoidCallback onChallenge;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return SizedBox(
      width: 138,
      child: AppCard(
        onTap: onChallenge,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            AppAvatar(player: player, size: 44, showPresence: true),
            verticalSpace(AppSpacing.md),
            Text(
              player.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(color: palette.textPrimary),
            ),
            verticalSpace(2),
            Text(
              'LVL ${player.level} · ${player.winRate}%',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.overline.copyWith(color: palette.textMuted),
            ),
            verticalSpace(AppSpacing.md),
            AppButton(
              label: 'Play',
              size: AppButtonSize.small,
              style: AppButtonStyle.secondary,
              onPressed: onChallenge,
            ),
          ],
        ),
      ),
    );
  }
}
