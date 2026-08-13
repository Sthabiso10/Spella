import 'package:flutter/material.dart';
import 'package:spella/core/models/power_up.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/views/shop/shop_viewmodel.dart';
import 'package:spella/ui/widgets/app_badge.dart';
import 'package:spella/ui/widgets/app_card.dart';
import 'package:spella/ui/widgets/page_width.dart';
import 'package:spella/ui/widgets/pressable.dart';
import 'package:spella/ui/widgets/section_header.dart';
import 'package:stacked/stacked.dart';

/// Cosmetics and boosters.
class ShopView extends StackedView<ShopViewModel> {
  const ShopView({super.key});

  @override
  Widget builder(BuildContext context, ShopViewModel viewModel, Widget? child) {
    final AppPalette palette = context.palette;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        bottom: false,
        child: PageWidth(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: PageHeader(
                  title: 'Shop',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AppInlineStat(
                        icon: Icons.monetization_on_outlined,
                        value: formatPoints(viewModel.player.coins),
                        tone: palette.accent,
                      ),
                      horizontalSpace(AppSpacing.lg),
                      AppInlineStat(
                        icon: Icons.diamond_outlined,
                        value: '${viewModel.player.gems}',
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.navClearance,
                ),
                sliver: SliverList.list(
                  children: <Widget>[
                    // The banner takes its own space rather than overlaying the
                    // page, so a purchase confirmation never hides what you just
                    // bought.
                    AnimatedSize(
                      duration: AppMotion.normal,
                      curve: AppMotion.enter,
                      alignment: Alignment.topCenter,
                      child: viewModel.message == null
                          ? const SizedBox(width: double.infinity)
                          : Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                              child: _MessageBanner(
                                message: viewModel.message!,
                                onDismiss: viewModel.dismissMessage,
                              ),
                            ),
                    ),
                    const SectionHeader(title: 'Avatars'),
                    verticalSpace(AppSpacing.md),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ShopViewModel.avatars.length,
                      // A fixed height rather than an aspect ratio: the tiles
                      // hold three lines of text, so their height has to follow
                      // the text size instead of the width of the phone.
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: AppSpacing.sm,
                        crossAxisSpacing: AppSpacing.sm,
                        mainAxisExtent: scaledSize(context, 92),
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        final AvatarOffer offer = ShopViewModel.avatars[index];
                        return _AvatarTile(
                          offer: offer,
                          isEquipped: viewModel.isEquipped(offer),
                          isOwned: viewModel.isOwned(offer),
                          canAfford: viewModel.canAfford(offer),
                          onTap: () => viewModel.selectAvatar(offer),
                        );
                      },
                    ),
                    verticalSpace(AppSpacing.section),
                    const SectionHeader(title: 'Boosters'),
                    verticalSpace(AppSpacing.sm),
                    Text(
                      'Spend coins on these mid-match, from the power-up bar.',
                      style: AppTextStyles.bodySmall.copyWith(color: palette.textMuted),
                    ),
                    verticalSpace(AppSpacing.lg),
                    for (final PowerUp booster in viewModel.boosters)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _BoosterRow(booster: booster),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  ShopViewModel viewModelBuilder(BuildContext context) => ShopViewModel();
}

/// One avatar for sale, owned, or equipped.
///
/// The three states are told apart by the outline and one line of small text,
/// not by three different fills - a grid of eight tiles in three colours would
/// be the busiest thing in the app.
class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.offer,
    required this.isEquipped,
    required this.isOwned,
    required this.canAfford,
    required this.onTap,
  });

  final AvatarOffer offer;
  final bool isEquipped;
  final bool isOwned;
  final bool canAfford;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool isLocked = !isOwned && !canAfford;

    return Pressable(
      onPressed: onTap,
      scale: 0.94,
      child: AnimatedContainer(
        duration: AppMotion.quick,
        curve: AppMotion.enter,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isEquipped ? palette.surfaceElevated : palette.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: isEquipped ? palette.accent : palette.border),
        ),
        child: Opacity(
          opacity: isLocked ? 0.45 : 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(offer.emoji, style: const TextStyle(fontSize: 24, height: 1)),
              verticalSpace(AppSpacing.sm),
              Text(
                offer.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 11,
                  color: palette.textPrimary,
                ),
              ),
              verticalSpace(2),
              if (isEquipped)
                Text(
                  'EQUIPPED',
                  style: AppTextStyles.overline.copyWith(
                    fontSize: 9,
                    color: palette.accent,
                  ),
                )
              else if (isOwned)
                Text(
                  'OWNED',
                  style: AppTextStyles.overline.copyWith(
                    fontSize: 9,
                    color: palette.textMuted,
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.diamond_outlined, size: 10, color: palette.textMuted),
                    horizontalSpace(3),
                    Text(
                      '${offer.gemCost}',
                      style: AppTextStyles.overline.copyWith(
                        fontSize: 9.5,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A booster, its effect, and its price.
class _BoosterRow extends StatelessWidget {
  const _BoosterRow({required this.booster});

  final PowerUp booster;

  static const Map<String, IconData> _icons = <String, IconData>{
    'hint': Icons.lightbulb_outline_rounded,
    'freeze': Icons.ac_unit_rounded,
    'swap': Icons.swap_horiz_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.surfaceElevated,
              borderRadius: const BorderRadius.all(AppRadius.xs),
              border: Border.all(color: palette.border),
            ),
            child: Icon(
              _icons[booster.id] ?? Icons.bolt_rounded,
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
                  booster.label,
                  style: AppTextStyles.label.copyWith(color: palette.textPrimary),
                ),
                verticalSpace(2),
                Text(
                  booster.description,
                  maxLines: 2,
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
          Text(
            formatPoints(booster.cost),
            style: AppTextStyles.scoreSmall.copyWith(fontSize: 15, color: palette.accent),
          ),
        ],
      ),
    );
  }
}

/// Transient confirmation for a purchase.
class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.control,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.check_circle_outline_rounded, size: 16, color: palette.success),
          horizontalSpace(AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: palette.textSecondary),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Icon(Icons.close_rounded, size: 14, color: palette.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
