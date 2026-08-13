import 'package:flutter/material.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/pressable.dart';

/// The label that opens a section.
///
/// Small and quiet on purpose. A section header's job is to let the eye skip
/// the section, not to compete with the content inside it - so it carries no
/// icon and no colour unless something is genuinely pending.
///
/// Set in sentence case rather than caps: at this size caps would be marginally
/// tidier and would cost every screen reader the ability to pronounce the word.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.count,
    this.trailingLabel,
    this.onTrailingPressed,
    this.accentDot = false,
    super.key,
  });

  final String title;

  /// Shown after the title in muted ink, e.g. `Friends 12`.
  final String? count;

  final String? trailingLabel;
  final VoidCallback? onTrailingPressed;

  /// A small live dot before the title, for sections that are happening now.
  final bool accentDot;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Row(
      children: <Widget>[
        if (accentDot) ...<Widget>[
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: palette.success, shape: BoxShape.circle),
          ),
          horizontalSpace(AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label.copyWith(color: palette.textSecondary),
          ),
        ),
        if (count != null) ...<Widget>[
          horizontalSpace(AppSpacing.sm),
          Text(count!, style: AppTextStyles.label.copyWith(color: palette.textMuted)),
        ],
        const Spacer(),
        // Only a real action earns a control. Rendering one without a callback
        // just puts a permanently dead label on the screen.
        if (trailingLabel != null && onTrailingPressed != null)
          Pressable(
            onPressed: onTrailingPressed,
            scale: 0.94,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    trailingLabel!,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  horizontalSpace(2),
                  Icon(Icons.chevron_right_rounded, size: 14, color: palette.textMuted),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A screen's title block: the name of the page and one line about it.
///
/// Every tab opens the same way, which is most of what makes four separate
/// screens feel like one product.
class PageHeader extends StatelessWidget {
  const PageHeader({required this.title, this.subtitle, this.trailing, super.key});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTextStyles.headingLarge.copyWith(color: palette.textPrimary),
                ),
                if (subtitle != null) ...<Widget>[
                  verticalSpace(AppSpacing.xs + 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySmall.copyWith(color: palette.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[horizontalSpace(AppSpacing.md), trailing!],
        ],
      ),
    );
  }
}
