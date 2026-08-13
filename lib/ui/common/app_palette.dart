import 'package:flutter/material.dart';
import 'package:spella/ui/common/app_colors.dart';

/// Semantic colours for the app, delivered as a [ThemeExtension] so widgets ask
/// for meaning ("the surface a card sits on") rather than a literal hex value,
/// and light and dark stay in sync automatically.
///
/// The system is roughly 90% monochrome. [accent] is the only hue in normal
/// browsing, and it is spent only where something is live, selected, or being
/// competed over. [success] and [danger] exist purely to answer a question the
/// player just asked - was that word good?
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.isDark,
    required this.canvas,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceHover,
    required this.recess,
    required this.border,
    required this.borderStrong,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textInverse,
    required this.accent,
    required this.accentSoft,
    required this.accentBorder,
    required this.success,
    required this.successSoft,
    required this.danger,
    required this.tileFace,
    required this.tileInk,
    required this.shadow,
    required this.scrim,
  });

  /// Whether this is the dark palette.
  ///
  /// Widgets branch on this where a value cannot simply be lerped between the
  /// two schemes - a placed tile inverts against the page, so which end of the
  /// ramp counts as "inverted" flips with the scheme.
  final bool isDark;

  /// The page.
  final Color canvas;

  /// A panel resting on the page.
  final Color surface;

  /// A panel resting on another panel, or one that needs to read as lifted.
  final Color surfaceElevated;

  /// Pressed, hovered and selected fills.
  final Color surfaceHover;

  /// Sunken fill, one step *behind* [canvas].
  ///
  /// Used for holes rather than panels - an empty word slot, an unfilled
  /// progress track - so they read as cut into the page instead of laid on it.
  final Color recess;

  /// Hairline outline around raised surfaces.
  ///
  /// Drop shadows barely read against near-black, so this border is what
  /// actually separates a panel from the page behind it.
  final Color border;

  /// A deliberately visible outline, for focus and selection.
  final Color borderStrong;

  /// Separator inside a panel or between list rows.
  final Color divider;

  /// Headings and anything the eye should land on first.
  final Color textPrimary;

  /// Supporting copy. Clearly secondary, still comfortably readable.
  final Color textSecondary;

  /// Metadata and disabled labels. Quiet, but never below legibility.
  final Color textMuted;

  /// Ink on [textPrimary] fills - the primary button, a placed tile.
  final Color textInverse;

  /// The single accent. Live states, selection, progress, competition.
  final Color accent;

  /// Tinted accent fill for chips and highlighted rows.
  final Color accentSoft;

  /// Outline for accented surfaces.
  final Color accentBorder;

  final Color success;
  final Color successSoft;
  final Color danger;

  /// Face of a committed letter tile. Inverted against the page, which is what
  /// makes a placed letter look picked up rather than merely recoloured.
  final Color tileFace;

  /// Letter colour on [tileFace].
  final Color tileInk;

  final Color shadow;

  /// Backdrop behind modal content.
  final Color scrim;

  /// Contact shadow for a panel that genuinely floats - a sheet, the nav bar.
  ///
  /// Deliberately tight and dark rather than wide and soft: a big blur on a
  /// near-black page only muddies the surface it is meant to lift.
  List<BoxShadow> get liftShadow => <BoxShadow>[
    BoxShadow(color: shadow, blurRadius: 24, offset: const Offset(0, 8)),
  ];

  /// Accent halo, scaled by [strength]. Reserved for the two or three moments
  /// a match actually turns on - never for decoration.
  List<BoxShadow> accentGlow({double strength = 1}) => <BoxShadow>[
    BoxShadow(
      color: accent.withValues(alpha: 0.18 * strength),
      blurRadius: 28 * strength,
      spreadRadius: -4,
    ),
  ];

  static const AppPalette dark = AppPalette(
    isDark: true,
    canvas: AppColors.ink,
    surface: AppColors.carbon,
    surfaceElevated: AppColors.graphite,
    surfaceHover: AppColors.slate,
    recess: AppColors.void_,
    border: AppColors.seam,
    borderStrong: AppColors.seamBright,
    divider: AppColors.rule,
    textPrimary: AppColors.paper,
    textSecondary: AppColors.pewter,
    textMuted: AppColors.ash,
    textInverse: AppColors.ink,
    accent: AppColors.amber,
    accentSoft: AppColors.amberWash,
    accentBorder: AppColors.amberSeam,
    success: AppColors.green,
    successSoft: AppColors.greenWash,
    danger: AppColors.red,
    tileFace: AppColors.paper,
    tileInk: AppColors.ink,
    shadow: Color(0xB3000000),
    scrim: Color(0xF00A0A0C),
  );

  static const AppPalette light = AppPalette(
    isDark: false,
    canvas: AppColors.lightInk,
    surface: AppColors.lightCarbon,
    surfaceElevated: AppColors.lightGraphite,
    surfaceHover: AppColors.lightSlate,
    recess: AppColors.lightVoid,
    border: AppColors.lightSeam,
    borderStrong: AppColors.lightSeamBright,
    divider: AppColors.lightRule,
    textPrimary: AppColors.lightPaper,
    textSecondary: AppColors.lightPewter,
    textMuted: AppColors.lightAsh,
    textInverse: AppColors.white,
    accent: AppColors.amberDeep,
    accentSoft: Color(0xFFFFF4E0),
    accentBorder: Color(0xFFF0D5A8),
    success: Color(0xFF10A05C),
    successSoft: Color(0xFFE3F7EC),
    danger: Color(0xFFD93A42),
    tileFace: AppColors.lightPaper,
    tileInk: AppColors.white,
    shadow: Color(0x14101014),
    scrim: Color(0xF0F7F7F9),
  );

  @override
  AppPalette copyWith({
    bool? isDark,
    Color? canvas,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceHover,
    Color? recess,
    Color? border,
    Color? borderStrong,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textInverse,
    Color? accent,
    Color? accentSoft,
    Color? accentBorder,
    Color? success,
    Color? successSoft,
    Color? danger,
    Color? tileFace,
    Color? tileInk,
    Color? shadow,
    Color? scrim,
  }) {
    return AppPalette(
      isDark: isDark ?? this.isDark,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      recess: recess ?? this.recess,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textInverse: textInverse ?? this.textInverse,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      accentBorder: accentBorder ?? this.accentBorder,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      danger: danger ?? this.danger,
      tileFace: tileFace ?? this.tileFace,
      tileInk: tileInk ?? this.tileInk,
      shadow: shadow ?? this.shadow,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      isDark: t < 0.5 ? isDark : other.isDark,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      recess: Color.lerp(recess, other.recess, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentBorder: Color.lerp(accentBorder, other.accentBorder, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      tileFace: Color.lerp(tileFace, other.tileFace, t)!,
      tileInk: Color.lerp(tileInk, other.tileInk, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

/// Shorthand for reaching the palette and the type scale from a [BuildContext].
extension AppPaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;

  TextTheme get texts => Theme.of(this).textTheme;
}
