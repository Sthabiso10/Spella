import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The type scale.
///
/// Hierarchy in this app is carried by type, not by boxes: a score is a huge
/// tight numeral, its label is a small quiet one, and the two need no card
/// around them to read as belonging together. Every style is defined here so
/// that relationship holds on every screen.
///
/// Styles carry no colour. Callers apply one from the palette, which keeps a
/// single style usable on the page, on a panel, and on an inverted fill.
class AppTextStyles {
  const AppTextStyles._();

  static TextStyle get _base => GoogleFonts.plusJakartaSans();

  /// Lining, fixed-width digits.
  ///
  /// Anything that ticks - a clock, a score counting up, a rank - must not
  /// reflow as its digits change, or the whole row twitches once a second.
  static const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

  // ---------------------------------------------------------------------------
  // Display - reserved for the one thing a screen is about
  // ---------------------------------------------------------------------------

  /// Match results, the round card. Big enough that tracking has to come in.
  static TextStyle get displayLarge => _base.copyWith(
    fontSize: 52,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.8,
    height: 1.02,
  );

  static TextStyle get displayMedium => _base.copyWith(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.4,
    height: 1.05,
  );

  // ---------------------------------------------------------------------------
  // Headings
  // ---------------------------------------------------------------------------

  static TextStyle get headingLarge => _base.copyWith(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.9,
    height: 1.15,
  );

  static TextStyle get headingMedium => _base.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle get headingSmall => _base.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.25,
  );

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------

  static TextStyle get body => _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    height: 1.5,
  );

  static TextStyle get bodyStrong => body.copyWith(fontWeight: FontWeight.w600);

  static TextStyle get bodySmall =>
      _base.copyWith(fontSize: 13, fontWeight: FontWeight.w400, height: 1.45);

  /// All-caps section and metadata label.
  ///
  /// Wide tracking is what lets a 10px label sit next to a 40px number without
  /// either one fighting for the same job.
  static TextStyle get overline => _base.copyWith(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.1,
    height: 1.2,
  );

  static TextStyle get label => _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.2,
  );

  static TextStyle get labelSmall =>
      _base.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.2);

  static TextStyle get button => _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.1,
  );

  // ---------------------------------------------------------------------------
  // Numerals
  // ---------------------------------------------------------------------------

  /// The headline number on a screen: a final score, the live points preview.
  static TextStyle get scoreLarge => _base.copyWith(
    fontSize: 56,
    fontWeight: FontWeight.w800,
    letterSpacing: -2.4,
    height: 1,
    fontFeatures: _tabular,
  );

  /// A running score in a scoreline.
  static TextStyle get score => _base.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    height: 1,
    fontFeatures: _tabular,
  );

  /// A supporting figure: a stat, a reward, a points column.
  static TextStyle get scoreSmall => _base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1,
    fontFeatures: _tabular,
  );

  /// The match clock.
  static TextStyle get timer => _base.copyWith(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.2,
    height: 1,
    fontFeatures: _tabular,
  );

  /// A leaderboard position.
  static TextStyle get rank => _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1,
    fontFeatures: _tabular,
  );

  /// A word laid out as letters, in a recap or a result.
  static TextStyle get wordmark => _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 4,
    height: 1.1,
  );

  /// Maps the scale onto Material's slots so anything built from [ThemeData] -
  /// dialogs, snackbars, list tiles - inherits it without extra styling.
  static TextTheme themeFor(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: headingLarge,
      headlineLarge: headingLarge,
      headlineMedium: headingMedium,
      headlineSmall: headingMedium,
      titleLarge: headingMedium,
      titleMedium: headingSmall,
      titleSmall: bodyStrong,
      bodyLarge: body,
      bodyMedium: body,
      bodySmall: bodySmall,
      labelLarge: button,
      labelMedium: label,
      labelSmall: overline,
    ).apply(bodyColor: primary, displayColor: primary);
  }
}
