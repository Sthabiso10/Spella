import 'package:flutter/material.dart';
import 'package:spella/core/models/game_mode.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/app_card.dart';

/// The game modes, laid out two to a row.
///
/// This replaced a horizontal carousel. A carousel is the right shape for a
/// list that has no end - a shelf of suggestions, a feed - and the wrong one
/// for a closed set of four, where it hides half the options behind a gesture
/// nobody is told about and makes choosing a mode a scroll rather than a
/// glance. Four modes fit on the page, so they are on the page.
///
/// A mode genuinely is a distinct object you pick up, so these stay cards while
/// most of Home is spacing and type.
class ModeGrid extends StatelessWidget {
  const ModeGrid({required this.modes, required this.onModeSelected, super.key});

  final List<GameMode> modes;
  final ValueChanged<GameMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int row = 0; row < modes.length; row += 2) ...<Widget>[
          if (row != 0) verticalSpace(AppSpacing.md),
          // The two cards in a row are almost never the same natural height -
          // one tagline wraps, the next does not - and a row of mismatched
          // cards is the first thing that reads as unfinished. Measuring the
          // pair and stretching both is cheap at two rows, and it lets the
          // cards grow with the text scale instead of being pinned to a fixed
          // height that clips.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _ModeCard(mode: modes[row], onTap: onModeSelected),
                ),
                horizontalSpace(AppSpacing.md),
                Expanded(
                  // An odd mode out keeps its column rather than spanning the
                  // row, so the grid stays a grid.
                  child: row + 1 < modes.length
                      ? _ModeCard(mode: modes[row + 1], onTap: onModeSelected)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.onTap});

  final GameMode mode;
  final ValueChanged<GameMode> onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return AppCard(
      onTap: () => onTap(mode),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(_iconFor(mode), size: 20, color: palette.textSecondary),
          verticalSpace(AppSpacing.lg),
          Text(
            mode.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headingSmall.copyWith(color: palette.textPrimary),
          ),
          verticalSpace(AppSpacing.xs),
          // The tagline off the model rather than a second copy of the specs
          // written here, so a mode's rules and its description can never drift
          // apart.
          Text(
            mode.tagline,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12.5,
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Keyed on the persisted id rather than the enum value, so a mode added to the
/// model without an icon here falls back instead of failing to compile.
const Map<String, IconData> _icons = <String, IconData>{
  'classic': Icons.workspace_premium_outlined,
  'blitz': Icons.bolt_rounded,
  'marathon': Icons.landscape_outlined,
  'daily': Icons.today_outlined,
  'party': Icons.groups_outlined,
};

IconData _iconFor(GameMode mode) => _icons[mode.id] ?? Icons.grid_view_rounded;
