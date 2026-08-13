import 'package:flutter/material.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';

/// What a badge is saying.
enum BadgeTone {
  /// Metadata: a game mode, a tag, a count. The default, and by far the most
  /// common - most badges are labels, not alarms.
  neutral,

  /// Live, selected, or waiting on the player.
  accent,

  /// A good outcome.
  success,
}

/// A small pill carrying status, a rank, a tag or a mode.
///
/// Pills are used only where the content is genuinely a token. Numbers and
/// stats are not tokens - they belong in [AppMetric], where type does the work
/// instead of a border.
class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    this.tone = BadgeTone.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final BadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final (Color ink, Color fill, Color edge) = switch (tone) {
      BadgeTone.neutral => (
        palette.textSecondary,
        palette.surfaceElevated,
        palette.border,
      ),
      BadgeTone.accent => (palette.accent, palette.accentSoft, palette.accentBorder),
      BadgeTone.success => (
        palette.success,
        palette.successSoft,
        palette.success.withValues(alpha: 0.28),
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: icon == null ? AppSpacing.sm : AppSpacing.sm - 1,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadius.pill,
        border: Border.all(color: edge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 11, color: ink),
            horizontalSpace(3),
          ],
          Text(label, style: AppTextStyles.labelSmall.copyWith(fontSize: 11, color: ink)),
        ],
      ),
    );
  }
}

/// A figure and what it means, stacked.
///
/// The whole point of this component is that `12` is bigger than `Streak`.
/// Reading order is value first, label second, which is the opposite of a
/// sentence and the reason a stat block scans in a glance.
class AppMetric extends StatelessWidget {
  const AppMetric({
    required this.value,
    required this.label,
    this.tone,
    this.icon,
    this.alignment = CrossAxisAlignment.start,
    this.isLarge = false,
    super.key,
  });

  final String value;
  final String label;

  /// Colours the figure. Left null the figure is primary ink, which is right
  /// for almost every stat - only the one that is actually notable takes a hue.
  final Color? tone;

  final IconData? icon;
  final CrossAxisAlignment alignment;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: isLarge ? 18 : 14, color: tone ?? palette.textMuted),
              horizontalSpace(AppSpacing.xs + 1),
            ],
            Text(
              value,
              style: (isLarge ? AppTextStyles.score : AppTextStyles.scoreSmall).copyWith(
                color: tone ?? palette.textPrimary,
              ),
            ),
          ],
        ),
        verticalSpace(isLarge ? AppSpacing.xs : 2),
        Text(
          label.toUpperCase(),
          style: AppTextStyles.overline.copyWith(color: palette.textMuted),
        ),
      ],
    );
  }
}

/// An icon and a value on one line, for header bars where vertical room is
/// short - coins, gems, a streak.
class AppInlineStat extends StatelessWidget {
  const AppInlineStat({required this.icon, required this.value, this.tone, super.key});

  final IconData icon;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final Color ink = tone ?? palette.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15, color: ink),
        horizontalSpace(AppSpacing.xs + 1),
        Text(
          value,
          style: AppTextStyles.label.copyWith(
            color: palette.textPrimary,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
