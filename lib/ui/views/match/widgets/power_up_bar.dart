import 'package:flutter/material.dart';
import 'package:spella/core/models/power_up.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/pressable.dart';

/// Row of in-match abilities, each showing its coin cost.
///
/// Kept at the quietest weight on the screen. These are an option, not a
/// prompt - a player who never notices them should still be able to win, so
/// they must not compete with the board for attention.
class PowerUpBar extends StatelessWidget {
  const PowerUpBar({
    required this.onUse,
    required this.isAvailable,
    required this.isUsed,
    super.key,
  });

  final ValueChanged<PowerUp> onUse;

  /// Whether the player can use [PowerUp] right now.
  final bool Function(PowerUp) isAvailable;

  /// Whether [PowerUp] has already been spent this round.
  final bool Function(PowerUp) isUsed;

  static const Map<String, IconData> _icons = <String, IconData>{
    'hint': Icons.lightbulb_outline_rounded,
    'freeze': Icons.ac_unit_rounded,
    'swap': Icons.swap_horiz_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (final PowerUp powerUp in PowerUp.values)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: _PowerUpChip(
              powerUp: powerUp,
              icon: _icons[powerUp.id] ?? Icons.bolt_rounded,
              isEnabled: isAvailable(powerUp),
              isUsed: isUsed(powerUp),
              onTap: () => onUse(powerUp),
            ),
          ),
      ],
    );
  }
}

class _PowerUpChip extends StatelessWidget {
  const _PowerUpChip({
    required this.powerUp,
    required this.icon,
    required this.isEnabled,
    required this.isUsed,
    required this.onTap,
  });

  final PowerUp powerUp;
  final IconData icon;
  final bool isEnabled;
  final bool isUsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Tooltip(
      message: powerUp.description,
      child: Pressable(
        onPressed: isEnabled ? onTap : null,
        scale: 0.93,
        child: AnimatedOpacity(
          opacity: isEnabled ? 1 : 0.4,
          duration: AppMotion.quick,
          child: AnimatedContainer(
            duration: AppMotion.quick,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isUsed ? Colors.transparent : palette.surface,
              borderRadius: AppRadius.pill,
              border: Border.all(color: palette.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  isUsed ? Icons.check_rounded : icon,
                  size: 14,
                  color: isUsed ? palette.success : palette.textSecondary,
                ),
                horizontalSpace(AppSpacing.xs + 2),
                // Once spent the chip stops quoting a price it can no longer
                // charge and simply names what was used.
                Text(
                  isUsed ? powerUp.label : '${powerUp.cost}',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 11.5,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
