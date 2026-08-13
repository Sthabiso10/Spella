import 'package:flutter/material.dart';
import 'package:spella/core/models/social.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/leaderboard_row.dart';
import 'package:spella/ui/widgets/section_header.dart';

/// Podium preview of the leaderboard, with a link through to the full board.
///
/// Shares [LeaderboardRow] with the Ranks tab rather than defining its own
/// compact layout, so a player's position looks the same wherever they meet it.
class LeaderboardPreview extends StatelessWidget {
  const LeaderboardPreview({required this.entries, required this.onSeeAll, super.key});

  final List<LeaderboardEntry> entries;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    // With nobody to rank, a header over a blank space reads as a bug. The
    // whole section stands down until there is a board to preview.
    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      children: <Widget>[
        SectionHeader(
          title: 'Top spellers',
          trailingLabel: 'Full board',
          onTrailingPressed: onSeeAll,
        ),
        verticalSpace(AppSpacing.sm),
        // No inset of their own: the rows already sit inside the page gutter,
        // so the rank numerals line up with every other heading on Home.
        for (final LeaderboardEntry entry in entries)
          LeaderboardRow(
            entry: entry,
            dense: true,
            horizontalPadding: 0,
            onTap: onSeeAll,
          ),
      ],
    );
  }
}
