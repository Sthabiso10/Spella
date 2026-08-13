import 'package:flutter/material.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';

/// How much emphasis an avatar's ring carries.
enum AvatarRing {
  none,

  /// Quiet outline. The default for a player in a list.
  subtle,

  /// Accented. Marks whoever is live, leading, or up next.
  accent,
}

/// A player's face.
///
/// Emoji stand in for uploaded photos until image handling is wired up. The
/// disc behind them is near-neutral but carries a trace of a hue derived from
/// the player id, so people stay recognisable between screens without any
/// stored colour - and without five saturated discs punching holes in a
/// monochrome page.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.player,
    this.size = 44,
    this.ring = AvatarRing.subtle,
    this.showPresence = false,
    this.showLevel = false,
    super.key,
  });

  final Player player;
  final double size;
  final AvatarRing ring;

  /// Draws the online dot.
  final bool showPresence;

  /// Draws the level chip on the bottom edge.
  final bool showLevel;

  /// A dark disc with roughly 20% saturation - enough that two players sitting
  /// next to each other are clearly not the same person, far too little to read
  /// as a colour in its own right.
  Color _discFor(AppPalette palette) {
    final double hue = (player.id.hashCode.abs() % 360).toDouble();
    return HSLColor.fromAHSL(1, hue, 0.2, palette.isDark ? 0.15 : 0.9).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool hasRing = ring != AvatarRing.none;
    final double ringWidth = hasRing ? 1.5 : 0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          AnimatedContainer(
            duration: AppMotion.normal,
            curve: AppMotion.enter,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _discFor(palette),
              shape: BoxShape.circle,
              border: hasRing
                  ? Border.all(
                      color: ring == AvatarRing.accent ? palette.accent : palette.border,
                      width: ringWidth,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              player.avatar,
              style: TextStyle(fontSize: size * 0.46, height: 1),
            ),
          ),
          if (showPresence && player.isOnline)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: palette.success,
                  shape: BoxShape.circle,
                  // Punched out of the page rather than outlined, so the dot
                  // reads as a light source instead of a sticker.
                  border: Border.all(
                    color: palette.canvas,
                    width: (size * 0.055).clamp(1.5, 3),
                  ),
                ),
              ),
            ),
          if (showLevel)
            Positioned(
              bottom: -size * 0.12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size * 0.13,
                    vertical: size * 0.02,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceHover,
                    borderRadius: AppRadius.pill,
                    border: Border.all(color: palette.canvas, width: 1.5),
                  ),
                  child: Text(
                    '${player.level}',
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: size * 0.2,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
