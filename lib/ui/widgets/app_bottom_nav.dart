import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/page_width.dart';

/// One destination in [AppBottomNav].
class NavDestination {
  const NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;

  /// The filled version of [icon]. Weight, not colour, is what carries the
  /// selected state - it survives being glanced at in peripheral vision.
  final IconData activeIcon;

  final String label;
}

/// The app's tab bar.
///
/// Content scrolls underneath it, so it needs a lit top edge and a fill to stay
/// separate from the list running beneath. Everything else is stripped back:
/// navigation is how you get to the product, and should never be the loudest
/// thing in it.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
    super.key,
  });

  final List<NavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// Height of the bar above the device's own bottom inset.
  ///
  /// Published so a screen that pins something over the shell - the leaderboard
  /// pins the player's own standing - can sit clear of it without guessing.
  static const double height = 58;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.border)),
        boxShadow: palette.liftShadow,
      ),
      child: SafeArea(
        top: false,
        // Chrome, so it opts out of most text scaling - at 200% the labels
        // would be larger than the icons they belong to. It still sizes to its
        // own content rather than to a fixed height, so what scaling is allowed
        // grows the bar instead of overflowing it.
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.2,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            // The bar's surface still spans the window, but its items are held
            // to the same measure as the content above them - four icons strung
            // across a tablet would put Home and Shop a hand's width apart.
            child: PageWidth(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (int i = 0; i < destinations.length; i++)
                    Expanded(
                      child: _NavItem(
                        destination: destinations[i],
                        isSelected: i == currentIndex,
                        onTap: () {
                          if (i != currentIndex) HapticFeedback.selectionClick();
                          onSelected(i);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final Color ink = isSelected ? palette.textPrimary : palette.textMuted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // A short accent rule above the active item, riding the bar's own top
          // edge. It is the only accent in the chrome, and it makes the current
          // tab unmistakable without lighting the whole item up.
          AnimatedContainer(
            duration: AppMotion.normal,
            curve: AppMotion.standard,
            height: 2,
            width: isSelected ? 18 : 0,
            decoration: BoxDecoration(
              color: palette.accent,
              borderRadius: AppRadius.pill,
            ),
          ),
          verticalSpace(AppSpacing.sm),
          AnimatedSwitcher(
            duration: AppMotion.quick,
            child: Icon(
              isSelected ? destination.activeIcon : destination.icon,
              key: ValueKey<bool>(isSelected),
              size: 21,
              color: ink,
            ),
          ),
          verticalSpace(AppSpacing.xs + 1),
          AnimatedDefaultTextStyle(
            duration: AppMotion.quick,
            style: AppTextStyles.overline.copyWith(
              fontSize: 9.5,
              letterSpacing: 0.6,
              color: ink,
            ),
            child: Text(destination.label),
          ),
        ],
      ),
    );
  }
}
