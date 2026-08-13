import 'package:flutter/material.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/pressable.dart';

/// A distinct object on the page.
///
/// Deliberately not the default container for content. Most grouping in this
/// app is done with spacing, type and a hairline rule; a card is reserved for
/// something you could pick up and move - a game mode, an invite, a booster.
///
/// Depth comes from the surface being one step lighter than the page plus a
/// hairline outline. On near-black a drop shadow reads as dirt, so there isn't
/// one unless the card genuinely floats above other content.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color,
    this.borderRadius = AppRadius.card,
    this.border,
    this.onTap,
    this.isAccented = false,
    this.floats = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Fill. Defaults to the standard panel surface.
  final Color? color;

  final BorderRadius borderRadius;

  /// Overrides the hairline outline.
  final BoxBorder? border;

  final VoidCallback? onTap;

  /// Marks the card as the one thing on the screen waiting on the player.
  /// Warms the outline rather than filling the card, which would drown
  /// everything inside it.
  final bool isAccented;

  /// Adds a contact shadow. Only for surfaces that sit above other content -
  /// sheets and bars - never for a card in a list.
  final bool floats;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    final Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? palette.surface,
        borderRadius: borderRadius,
        border:
            border ??
            Border.all(color: isAccented ? palette.accentBorder : palette.border),
        boxShadow: floats ? palette.liftShadow : null,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return surface;

    return Pressable(onPressed: onTap, scale: 0.985, child: surface);
  }
}

/// A horizontal hairline, used to separate rows without boxing them.
///
/// This is the app's main alternative to a card: rows share one background and
/// are told apart by a rule and by their own internal spacing.
class AppDivider extends StatelessWidget {
  const AppDivider({this.indent = 0, super.key});

  /// Left inset, so a rule can line up with a row's text rather than its
  /// avatar - which is what stops a list looking like a table.
  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: ColoredBox(
        color: context.palette.divider,
        child: const SizedBox(height: 1, width: double.infinity),
      ),
    );
  }
}
