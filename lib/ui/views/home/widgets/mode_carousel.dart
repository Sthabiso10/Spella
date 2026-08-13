import 'package:flutter/material.dart';
import 'package:spella/core/models/game_mode.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/app_card.dart';

/// Horizontal row of game modes.
///
/// A mode genuinely is a distinct object you pick up, so these are the one
/// place on Home that stays a card. Each states its rack size and clock, so the
/// difference between the modes is legible before you commit to one.
class ModeCarousel extends StatelessWidget {
  const ModeCarousel({required this.modes, required this.onModeSelected, super.key});

  final List<GameMode> modes;
  final ValueChanged<GameMode> onModeSelected;

  static const Map<String, IconData> _icons = <String, IconData>{
    'classic': Icons.workspace_premium_outlined,
    'blitz': Icons.bolt_rounded,
    'marathon': Icons.landscape_outlined,
    'daily': Icons.today_outlined,
    'party': Icons.groups_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: scaledSize(context, 132),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: modes.length,
        separatorBuilder: (BuildContext context, int index) =>
            horizontalSpace(AppSpacing.md),
        itemBuilder: (BuildContext context, int index) => _ModeCard(
          mode: modes[index],
          icon: _icons[modes[index].id] ?? Icons.grid_view_rounded,
          onTap: () => onModeSelected(modes[index]),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.icon, required this.onTap});

  final GameMode mode;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return SizedBox(
      width: 158,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Icon(icon, size: 20, color: palette.textSecondary),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  mode.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingSmall.copyWith(color: palette.textPrimary),
                ),
                verticalSpace(AppSpacing.xs),
                // The specifics are what actually distinguish the modes, so
                // they get a line of their own rather than being buried in the
                // tagline sentence. For Pass & Play the distinguishing fact is
                // not the rack size - it is that other people are involved.
                Text(
                  mode == GameMode.party
                      ? '2-6 PLAYERS · 1 DEVICE'
                      : '${mode.rackSize} TILES · ${mode.secondsPerRound}S',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.overline.copyWith(color: palette.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
