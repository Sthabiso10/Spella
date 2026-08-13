import 'package:flutter/material.dart';
import 'package:spella/core/models/letter_tile.dart';
import 'package:spella/core/models/slot_bonus.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';

/// How a tile is being presented.
enum TileVariant {
  /// Sitting in the rack, available to play.
  rack,

  /// Placed into the word being built.
  placed,

  /// In the rack but already used, so drawn as a ghost.
  spent,

  /// A completed play shown in a recap.
  recap,
}

/// A single lettered tile.
///
/// Purely presentational - it reports taps and nothing more, so the view model
/// stays the only thing that knows what a tap means.
///
/// The whole board runs on one idea: an uncommitted tile is a dark panel with a
/// light letter, and a committed one inverts to a light panel with dark ink.
/// That inversion is the strongest signal available in a monochrome system, and
/// it costs no colour at all.
class LetterTileView extends StatelessWidget {
  const LetterTileView({
    required this.tile,
    this.variant = TileVariant.rack,
    this.size = 48,
    this.bonus = SlotBonus.none,
    this.onTap,
    super.key,
  });

  final LetterTile tile;
  final TileVariant variant;
  final double size;

  /// Drawn as a badge in the corner when the tile sits on a bonus slot.
  final SlotBonus bonus;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool isCommitted =
        variant == TileVariant.placed || variant == TileVariant.recap;
    final bool isSpent = variant == TileVariant.spent;

    final Color face = switch (variant) {
      TileVariant.placed || TileVariant.recap => palette.tileFace,
      TileVariant.spent => palette.recess,
      TileVariant.rack => palette.surfaceElevated,
    };
    final Color ink = switch (variant) {
      TileVariant.placed || TileVariant.recap => palette.tileInk,
      TileVariant.spent => palette.textMuted.withValues(alpha: 0.35),
      TileVariant.rack => palette.textPrimary,
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.quick,
        curve: AppMotion.enter,
        width: size,
        height: size,
        clipBehavior: Clip.none,
        decoration: BoxDecoration(
          color: face,
          borderRadius: AppRadius.tile,
          border: Border.all(
            color: isCommitted
                ? Colors.transparent
                : isSpent
                ? palette.divider
                : palette.border,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Center(
              child: Text(
                tile.display,
                style: TextStyle(
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: ink,
                  height: 1,
                ),
              ),
            ),
            // The point value is reference information, not part of the letter,
            // so it sits at a fraction of the weight in the corner.
            Positioned(
              right: size * 0.12,
              bottom: size * 0.08,
              child: Text(
                '${tile.value}',
                style: TextStyle(
                  fontSize: size * 0.19,
                  fontWeight: FontWeight.w600,
                  color: ink.withValues(alpha: 0.45),
                  height: 1,
                ),
              ),
            ),
            if (!bonus.isNone)
              Positioned(
                top: -size * 0.13,
                right: -size * 0.13,
                child: BonusBadge(bonus: bonus, size: size * 0.38),
              ),
          ],
        ),
      ),
    );
  }
}

/// An empty position in the word being built.
class WordSlotView extends StatelessWidget {
  const WordSlotView({
    required this.bonus,
    this.size = 48,
    this.isNext = false,
    super.key,
  });

  final SlotBonus bonus;
  final double size;

  /// Highlights the slot the next tap will fill.
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return AnimatedContainer(
      duration: AppMotion.quick,
      curve: AppMotion.enter,
      width: size,
      height: size,
      decoration: BoxDecoration(
        // Slots are cut into the page rather than laid on it, so an unfinished
        // word reads as a row of sockets waiting to be filled.
        color: palette.recess,
        borderRadius: AppRadius.tile,
        border: Border.all(
          color: isNext ? palette.accent : palette.border,
          width: isNext ? 1.5 : 1,
        ),
        // The slot the next tap fills is the only moving target on the board,
        // so it gets the one halo on the screen.
        boxShadow: isNext ? palette.accentGlow(strength: 0.6) : null,
      ),
      child: bonus.isNone
          ? null
          : Center(
              child: Text(
                bonus.label,
                style: TextStyle(
                  fontSize: size * 0.24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: palette.textMuted,
                ),
              ),
            ),
    );
  }
}

/// The small multiplier badge that sits on a bonus slot.
class BonusBadge extends StatelessWidget {
  const BonusBadge({required this.bonus, this.size = 18, super.key});

  final SlotBonus bonus;
  final double size;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: EdgeInsets.symmetric(horizontal: size * 0.2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.accent,
        borderRadius: AppRadius.pill,
        // Outlined in the page colour so the badge punches out of whatever it
        // overlaps rather than merging with the tile corner beneath it.
        border: Border.all(color: palette.canvas, width: size * 0.11),
      ),
      child: Text(
        bonus.label,
        style: AppTextStyles.labelSmall.copyWith(
          fontSize: size * 0.46,
          fontWeight: FontWeight.w800,
          color: palette.textInverse,
          height: 1,
        ),
      ),
    );
  }
}
