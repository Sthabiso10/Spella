import 'package:flutter/material.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/app_states.dart';
import 'package:spella/ui/widgets/pressable.dart';

/// Visual weight of an [AppButton].
enum AppButtonStyle {
  /// Solid off-white on near-black ink. The single most important action on a
  /// screen, and the only thing on a normal page with that much contrast.
  primary,

  /// Raised surface with a hairline. Supporting actions.
  secondary,

  /// No fill until pressed. Tertiary actions that should not compete.
  ghost,

  /// Amber. Reserved for the competitive beat - accepting a challenge - so
  /// the one colour in the system keeps meaning something.
  accent,
}

/// Size of an [AppButton].
enum AppButtonSize { small, medium, large }

/// The app's button.
///
/// Owns its press response, busy state and disabled state so screens stay
/// declarative and every button in the product behaves identically.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.expand = true,
    this.isBusy = false,
    super.key,
  });

  final String label;

  /// `null` disables the button.
  final VoidCallback? onPressed;

  final AppButtonStyle style;
  final AppButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;

  /// Stretch to the available width.
  final bool expand;

  /// Shows a spinner and blocks input.
  final bool isBusy;

  bool get _isEnabled => onPressed != null && !isBusy;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final _ButtonSkin skin = _skinFor(palette);
    final _ButtonMetrics metrics = _metricsFor();

    return Pressable(
      onPressed: _isEnabled ? onPressed : null,
      scale: expand ? 0.985 : 0.96,
      child: AnimatedOpacity(
        // Disabled is communicated by weight, not by a different colour: the
        // button keeps its identity and simply stops asking to be pressed.
        opacity: _isEnabled ? 1 : 0.38,
        duration: AppMotion.quick,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          curve: AppMotion.enter,
          width: expand ? double.infinity : null,
          height: metrics.height,
          padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
          decoration: BoxDecoration(
            color: skin.fill,
            borderRadius: AppRadius.control,
            border: skin.border,
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (isBusy)
                AppLoading(size: metrics.iconSize, color: skin.ink)
              else if (icon != null)
                Icon(icon, size: metrics.iconSize, color: skin.ink),
              if (isBusy || icon != null) horizontalSpace(AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: metrics.textStyle.copyWith(color: skin.ink),
                ),
              ),
              if (trailingIcon != null) ...<Widget>[
                horizontalSpace(AppSpacing.sm),
                Icon(trailingIcon, size: metrics.iconSize, color: skin.ink),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _ButtonSkin _skinFor(AppPalette palette) {
    return switch (style) {
      AppButtonStyle.primary => _ButtonSkin(
        fill: palette.textPrimary,
        ink: palette.textInverse,
      ),
      AppButtonStyle.secondary => _ButtonSkin(
        fill: palette.surfaceElevated,
        ink: palette.textPrimary,
        border: Border.all(color: palette.border),
      ),
      AppButtonStyle.ghost => _ButtonSkin(
        fill: Colors.transparent,
        ink: palette.textSecondary,
        border: Border.all(color: palette.border),
      ),
      AppButtonStyle.accent => _ButtonSkin(
        fill: palette.accent,
        ink: palette.textInverse,
      ),
    };
  }

  _ButtonMetrics _metricsFor() {
    return switch (size) {
      AppButtonSize.small => _ButtonMetrics(
        height: 34,
        horizontalPadding: AppSpacing.md,
        iconSize: 15,
        textStyle: AppTextStyles.labelSmall,
      ),
      AppButtonSize.medium => _ButtonMetrics(
        height: 44,
        horizontalPadding: AppSpacing.lg,
        iconSize: 18,
        textStyle: AppTextStyles.button,
      ),
      AppButtonSize.large => _ButtonMetrics(
        height: 54,
        horizontalPadding: AppSpacing.xl,
        iconSize: 20,
        textStyle: AppTextStyles.button.copyWith(fontSize: 16),
      ),
    };
  }
}

class _ButtonSkin {
  const _ButtonSkin({required this.fill, required this.ink, this.border});

  final Color fill;
  final Color ink;
  final BoxBorder? border;
}

class _ButtonMetrics {
  const _ButtonMetrics({
    required this.height,
    required this.horizontalPadding,
    required this.iconSize,
    required this.textStyle,
  });

  final double height;
  final double horizontalPadding;
  final double iconSize;
  final TextStyle textStyle;
}

/// A square icon button for compact actions - clear, shuffle, dismiss.
///
/// Square rather than round: it sits in rows next to [AppButton]s, and matching
/// their corner radius is what makes a control row read as one object.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.onPressed,
    this.size = 44,
    this.foreground,
    this.background,
    this.isTransparent = false,
    this.tooltip,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? foreground;
  final Color? background;

  /// Drops the fill and the outline, for icons sitting on a busy or dark area
  /// where a boxed control would add noise.
  final bool isTransparent;

  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool isEnabled = onPressed != null;

    final Widget button = Pressable(
      onPressed: onPressed,
      scale: 0.92,
      child: AnimatedOpacity(
        opacity: isEnabled ? 1 : 0.32,
        duration: AppMotion.quick,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isTransparent
                ? Colors.transparent
                : background ?? palette.surfaceElevated,
            borderRadius: AppRadius.control,
            border: isTransparent || background != null
                ? null
                : Border.all(color: palette.border),
          ),
          child: Icon(
            icon,
            size: size * 0.42,
            color: foreground ?? palette.textSecondary,
          ),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
