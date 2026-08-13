import 'package:flutter/material.dart';
import 'package:spella/core/models/social.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/app_avatar.dart';

/// Top three players, arranged 2 - 1 - 3 with the winner raised.
///
/// No gold, silver and bronze. Three metals would be the loudest thing in the
/// product and would say nothing the heights and the numbers do not already
/// say. First place is marked by height, by a slightly larger face, and by the
/// single accent rule on its riser.
class Podium extends StatelessWidget {
  const Podium({required this.entries, super.key});

  final List<LeaderboardEntry> entries;

  /// Display order, so first place sits in the middle.
  static const List<int> _displayOrder = <int>[1, 0, 2];

  static const Map<int, double> _heights = <int, double>{0: 84, 1: 60, 2: 44};

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        for (final int position in _displayOrder)
          if (position < entries.length)
            Expanded(
              child: _PodiumStep(
                entry: entries[position],
                height: _heights[position] ?? 44,
              ),
            ),
      ],
    );
  }
}

class _PodiumStep extends StatelessWidget {
  const _PodiumStep({required this.entry, required this.height});

  final LeaderboardEntry entry;
  final double height;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool isWinner = entry.rank == 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppAvatar(
            player: entry.player,
            size: isWinner ? 56 : 44,
            ring: isWinner ? AvatarRing.accent : AvatarRing.subtle,
          ),
          verticalSpace(AppSpacing.sm),
          Text(
            entry.isCurrentUser ? 'You' : entry.player.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(color: palette.textPrimary),
          ),
          verticalSpace(2),
          Text(
            formatPoints(entry.points),
            style: AppTextStyles.scoreSmall.copyWith(
              fontSize: isWinner ? 17 : 15,
              color: isWinner ? palette.accent : palette.textSecondary,
            ),
          ),
          verticalSpace(AppSpacing.md),
          // The riser. Its height is what encodes the ranking, so it grows into
          // place on first build rather than simply appearing at full size.
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: height),
            duration: AppMotion.entrance,
            curve: AppMotion.enter,
            builder: (BuildContext context, double value, Widget? child) => Container(
              height: value,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: const BorderRadius.vertical(top: AppRadius.xs),
                border: Border.all(color: palette.border),
              ),
              child: Stack(
                children: <Widget>[
                  // The winner's cap is drawn inside the riser and clipped to
                  // its corners. A thicker top border would have done the same
                  // job, but a border radius needs every side to match.
                  if (isWinner)
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(height: 2, color: palette.accent),
                    ),
                  if (value >= 32)
                    Center(
                      child: Text(
                        '${entry.rank}',
                        style: AppTextStyles.score.copyWith(
                          fontSize: isWinner ? 26 : 20,
                          color: isWinner ? palette.textPrimary : palette.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
