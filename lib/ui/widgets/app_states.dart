import 'package:flutter/material.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/app_buttons.dart';

/// Shown when a list has nothing in it.
///
/// An empty state is a real state, not a gap: it says what would be here, and
/// where possible offers the one action that fills it. The illustration is a
/// single outlined glyph - anything more decorative starts to look like a
/// consolation prize.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.section,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: AppRadius.card,
              border: Border.all(color: palette.border),
            ),
            child: Icon(icon, size: 22, color: palette.textMuted),
          ),
          verticalSpace(AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headingSmall.copyWith(color: palette.textPrimary),
          ),
          if (message != null) ...<Widget>[
            verticalSpace(AppSpacing.xs + 2),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: palette.textSecondary),
            ),
          ],
          if (actionLabel != null && onAction != null) ...<Widget>[
            verticalSpace(AppSpacing.xl),
            AppButton(
              label: actionLabel!,
              expand: false,
              size: AppButtonSize.small,
              style: AppButtonStyle.secondary,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

/// A placeholder block that breathes while content loads.
///
/// Preferred over a spinner anywhere the shape of the result is already known:
/// the page keeps its layout, so nothing jumps when the data lands.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    required this.height,
    this.width,
    this.borderRadius = AppRadius.control,
    super.key,
  });

  final double height;
  final double? width;
  final BorderRadius borderRadius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return FadeTransition(
      // A slow opacity breath rather than a travelling shimmer: on a dark page
      // a shimmer highlight is brighter than most of the real content.
      opacity: Tween<double>(
        begin: 0.45,
        end: 1,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: widget.borderRadius,
        ),
      ),
    );
  }
}

/// The app's spinner, sized for inline use.
class AppLoading extends StatelessWidget {
  const AppLoading({this.size = 16, this.color, super.key});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        strokeWidth: size < 20 ? 2 : 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? context.palette.textMuted),
      ),
    );
  }
}
