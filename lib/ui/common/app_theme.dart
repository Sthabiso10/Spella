import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';

/// Builds the light and dark [ThemeData] from a single [AppPalette].
///
/// Everything Material can be told once is told here - surfaces, dialogs,
/// sheets, snackbars, inputs, selection. Screens are then free to be about
/// layout, and the app's visual identity can be changed from the palette and
/// the type scale alone.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(AppPalette.light, Brightness.light);

  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);

  /// Status and navigation bar styling that matches [palette].
  ///
  /// The bars are transparent so content can run underneath them; only the icon
  /// brightness has to flip with the scheme.
  static SystemUiOverlayStyle systemOverlay(AppPalette palette) {
    final Brightness icons = palette.isDark ? Brightness.light : Brightness.dark;

    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: icons,
      statusBarBrightness: palette.isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: icons,
      systemNavigationBarDividerColor: Colors.transparent,
    );
  }

  static ThemeData _build(AppPalette palette, Brightness brightness) {
    final TextTheme textTheme = AppTextStyles.themeFor(
      palette.textPrimary,
      palette.textSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.canvas,
      canvasColor: palette.canvas,
      // The default ink sparkle throws a bright wash across a dark surface on
      // every tap. Components here own their own press feedback - a small
      // scale, a surface change - which is quieter and reads as more precise.
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(seedColor: palette.accent, brightness: brightness)
          .copyWith(
            primary: palette.textPrimary,
            onPrimary: palette.textInverse,
            primaryContainer: palette.surfaceElevated,
            onPrimaryContainer: palette.textPrimary,
            secondary: palette.accent,
            onSecondary: palette.textInverse,
            secondaryContainer: palette.accentSoft,
            onSecondaryContainer: palette.accent,
            tertiary: palette.accent,
            onTertiary: palette.textInverse,
            surface: palette.surface,
            onSurface: palette.textPrimary,
            surfaceContainerHighest: palette.surfaceElevated,
            onSurfaceVariant: palette.textSecondary,
            outline: palette.border,
            outlineVariant: palette.divider,
            error: palette.danger,
            onError: palette.textInverse,
            shadow: palette.shadow,
            scrim: palette.scrim,
          ),
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[palette],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: palette.textPrimary,
        titleTextStyle: textTheme.titleMedium,
        systemOverlayStyle: systemOverlay(palette),
      ),
      dividerTheme: DividerThemeData(color: palette.divider, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: palette.textSecondary, size: 20),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.accent,
        linearTrackColor: palette.recess,
        circularTrackColor: palette.recess,
        linearMinHeight: 2,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: palette.accent,
        selectionColor: palette.accent.withValues(alpha: 0.24),
        selectionHandleColor: palette.accent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
        border: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: palette.borderStrong, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: palette.danger),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: const BorderRadius.all(AppRadius.xs),
          border: Border.all(color: palette.border),
        ),
        textStyle: textTheme.labelMedium?.copyWith(color: palette.textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.surfaceElevated,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: palette.textPrimary),
        actionTextColor: palette.accent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: palette.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: palette.borderStrong,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(AppRadius.lg),
          side: BorderSide(color: palette.border),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.textPrimary,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          minimumSize: const Size(0, 40),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
        ),
      ),
      // Page transitions are deliberately not set here: every route in the app
      // is built by hand in app.router.dart, so that file stays the single
      // place navigation motion is described.
    );
  }
}
