import 'package:flutter/material.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/app_buttons.dart';

/// What the Friends tab shows before there is anybody in it.
///
/// This replaced a generic empty state whose message was "add people to
/// challenge them" - advice the screen gave no way to follow, since adding
/// somebody needs an account system the app does not have yet. An empty state
/// that names an action the player cannot take is worse than no empty state at
/// all: it reads as a control they failed to find.
///
/// So it says the true thing instead, and offers the two ways to get a game out
/// of this screen right now. Pass & Play leads because it is the one that
/// actually involves other people.
class FriendsStarter extends StatelessWidget {
  const FriendsStarter({required this.onPassAndPlay, required this.onPlayBot, super.key});

  final VoidCallback onPassAndPlay;
  final VoidCallback onPlayBot;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: AppRadius.card,
              border: Border.all(color: palette.border),
            ),
            child: Icon(
              Icons.person_add_alt_outlined,
              size: 22,
              color: palette.textMuted,
            ),
          ),
          verticalSpace(AppSpacing.lg),
          Text(
            'No friends yet',
            style: AppTextStyles.headingMedium.copyWith(color: palette.textPrimary),
          ),
          verticalSpace(AppSpacing.sm),
          Text(
            'Adding people needs accounts, which are still being built. Your '
            'friends, their challenges and the board you share will all live '
            'on this screen once they are.',
            style: AppTextStyles.body.copyWith(color: palette.textSecondary),
          ),
          verticalSpace(AppSpacing.xl),
          Text(
            'IN THE MEANTIME',
            style: AppTextStyles.overline.copyWith(color: palette.textMuted),
          ),
          verticalSpace(AppSpacing.md),
          AppButton(
            label: 'Pass & Play',
            icon: Icons.groups_outlined,
            onPressed: onPassAndPlay,
          ),
          verticalSpace(AppSpacing.sm),
          Text(
            'Everyone in the room takes a turn on this phone. No account needed.',
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w500,
              color: palette.textMuted,
            ),
          ),
          verticalSpace(AppSpacing.lg),
          AppButton(
            label: 'Play the bot',
            icon: Icons.smart_toy_outlined,
            style: AppButtonStyle.secondary,
            onPressed: onPlayBot,
          ),
        ],
      ),
    );
  }
}
