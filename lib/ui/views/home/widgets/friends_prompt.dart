import 'package:flutter/material.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/app_buttons.dart';
import 'package:spella/ui/widgets/app_card.dart';

/// The one thing Home says about the social side while there is nothing in it.
///
/// It stands in for what used to be two dead sections - an activity feed
/// reading "Nothing yet" and a leaderboard heading over blank space. Both of
/// those described an absence and offered no way out of it, which on a first
/// run is most of the page. This says the same thing once, and has a button.
class FriendsPrompt extends StatelessWidget {
  const FriendsPrompt({required this.onFindFriends, super.key});

  final VoidCallback onFindFriends;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: palette.recess,
                  borderRadius: AppRadius.control,
                  border: Border.all(color: palette.border),
                ),
                child: Icon(
                  Icons.people_outline_rounded,
                  size: 18,
                  color: palette.textSecondary,
                ),
              ),
              horizontalSpace(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Better with people',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                    verticalSpace(AppSpacing.xs),
                    Text(
                      'Their best words show up here, and you get a board to '
                      'climb. Until then the bot is a fair fight.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          verticalSpace(AppSpacing.lg),
          AppButton(
            label: 'Find people to play',
            trailingIcon: Icons.arrow_forward_rounded,
            size: AppButtonSize.small,
            style: AppButtonStyle.secondary,
            onPressed: onFindFriends,
          ),
        ],
      ),
    );
  }
}
