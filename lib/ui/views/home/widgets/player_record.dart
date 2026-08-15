import 'package:flutter/material.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/app_badge.dart';

/// What the player has to show for the matches they have played.
///
/// Three figures rather than a wall of them, and no box: [AppMetric] already
/// makes the number bigger than its label, which is the whole of the hierarchy
/// this needs.
///
/// Laid out as a [Wrap] rather than a row of thirds. Three fixed columns fit
/// comfortably at every normal size and then fail at exactly the size where
/// failing matters most - a small phone at a large accessibility text scale,
/// where a third of the page is narrower than the numeral it has to hold.
/// Wrapping lets the figures grow to whatever the reader has asked for and drop
/// onto a second line when they must, instead of being clipped for it.
///
/// Home only shows this once there is a record to show. Played 0, Won 0, 0%
/// tells a new player nothing about themselves and rather a lot about how empty
/// the app is.
class PlayerRecord extends StatelessWidget {
  const PlayerRecord({required this.player, super.key});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xxl,
      runSpacing: AppSpacing.lg,
      children: <Widget>[
        AppMetric(value: '${player.gamesPlayed}', label: 'Played'),
        AppMetric(value: '${player.wins}', label: 'Won'),
        AppMetric(value: '${player.winRate}%', label: 'Win rate'),
      ],
    );
  }
}
