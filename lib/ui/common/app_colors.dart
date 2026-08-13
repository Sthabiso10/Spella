import 'package:flutter/material.dart';

/// The raw colour vocabulary of the app.
///
/// Nothing in the UI should reach for these directly - they exist so that
/// [AppPalette] can be written in named steps rather than in loose hex values.
/// Widgets ask the palette for *meaning* ("surface", "textMuted"), which means
/// the entire product can be re-skinned from this one file.
///
/// The system is deliberately monochrome. A single warm accent carries every
/// competitive moment; everything else is a step on one cool neutral ramp.
class AppColors {
  const AppColors._();

  // ---------------------------------------------------------------------------
  // Neutral ramp
  // ---------------------------------------------------------------------------
  //
  // Every step is small on purpose. Depth on a dark interface comes from
  // stacking several close values, not from one big jump plus a drop shadow -
  // shadows barely register against near-black and just read as grey smudge.

  /// One step *behind* the page. Used for holes: empty slots, progress tracks.
  static const Color void_ = Color(0xFF050506);

  /// The page itself.
  static const Color ink = Color(0xFF0A0A0C);

  /// A panel resting on the page.
  static const Color carbon = Color(0xFF101014);

  /// A panel resting on another panel.
  static const Color graphite = Color(0xFF16161B);

  /// Hover, pressed and selected fills.
  static const Color slate = Color(0xFF1E1E25);

  /// Hairline outlines. This, not the shadow, is what separates a panel from
  /// the page behind it.
  static const Color seam = Color(0xFF25252D);

  /// A deliberately visible outline, for focus and selection.
  static const Color seamBright = Color(0xFF35353F);

  /// Dividers inside a panel, one step quieter than [seam].
  static const Color rule = Color(0xFF1A1A20);

  /// Disabled ink and decorative marks. Below body-text contrast on purpose.
  static const Color ash = Color(0xFF5F5F6B);

  /// Supporting copy. Comfortably readable, clearly secondary.
  static const Color pewter = Color(0xFF9B9BA6);

  /// Bright secondary ink, for values that need to hold their own.
  static const Color mist = Color(0xFFC7C7D0);

  /// Primary ink, and the fill of the primary action.
  static const Color paper = Color(0xFFF5F5F7);

  static const Color white = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Accent
  // ---------------------------------------------------------------------------
  //
  // One hue for the whole product. Amber already meant something here - coins,
  // streaks, the daily challenge - so consolidating every competitive signal
  // onto it removes colours rather than adding them. It reads as trophy and
  // heat against near-black, where a neon would read as toy.

  static const Color amber = Color(0xFFFFB224);
  static const Color amberDeep = Color(0xFFE08A00);

  /// Tinted fill for accent chips and selected rows.
  static const Color amberWash = Color(0xFF20180A);

  /// Outline for accented surfaces.
  static const Color amberSeam = Color(0xFF473516);

  // ---------------------------------------------------------------------------
  // Status
  // ---------------------------------------------------------------------------

  static const Color green = Color(0xFF35D07F);
  static const Color greenWash = Color(0xFF0C221A);

  static const Color red = Color(0xFFF05A61);
  static const Color redWash = Color(0xFF241113);

  // ---------------------------------------------------------------------------
  // Light scheme neutrals
  // ---------------------------------------------------------------------------
  //
  // The app ships dark. These are kept in step so the light theme stays honest
  // if it is ever offered as a setting - same ramp, inverted.

  static const Color lightVoid = Color(0xFFE8E8EC);
  static const Color lightInk = Color(0xFFF7F7F9);
  static const Color lightCarbon = Color(0xFFFFFFFF);
  static const Color lightGraphite = Color(0xFFF1F1F4);
  static const Color lightSlate = Color(0xFFE9E9EE);
  static const Color lightSeam = Color(0xFFE2E2E8);
  static const Color lightSeamBright = Color(0xFFCECED6);
  static const Color lightRule = Color(0xFFEDEDF1);
  static const Color lightAsh = Color(0xFFA0A0AC);
  static const Color lightPewter = Color(0xFF6C6C78);
  static const Color lightMist = Color(0xFF43434D);
  static const Color lightPaper = Color(0xFF121216);
}
