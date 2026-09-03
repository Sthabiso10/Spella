import 'package:flutter/material.dart';
import 'package:spella/core/models/letter_tile.dart';
import 'package:spella/core/models/slot_bonus.dart';
import 'package:spella/ui/widgets/letter_tile_view.dart';
import 'package:spella/ui/widgets/tile_strip.dart';

/// The word the player is building: filled slots first, then the empty ones.
///
/// Sizes its tiles to whatever width is available, so a six tile Blitz rack and
/// a nine tile Marathon rack both fit on one line without scrolling and without
/// either mode getting a cramped board.
///
/// The slots are drawn once and never move. The letters ride on top of them and
/// are keyed by tile, so pulling a letter out of the middle of a word makes
/// everything after it walk left into the gap - which is what tells the player
/// the word closed up, rather than leaving them to spot that it did.
class WordBuilder extends StatelessWidget {
  const WordBuilder({
    required this.slotCount,
    required this.placedTiles,
    required this.bonuses,
    required this.onSlotTapped,
    this.isRevealed = true,
    super.key,
  });

  final int slotCount;
  final List<LetterTile> placedTiles;
  final List<SlotBonus> bonuses;
  final ValueChanged<int> onSlotTapped;

  /// `false` while the board is still covered, so nothing is built underneath
  /// an overlay and every tile's entrance plays where it can be seen.
  final bool isRevealed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final TileStripLayout layout = TileStripLayout.resolve(
          availableWidth: constraints.maxWidth,
          count: slotCount,
        );

        return SizedBox(
          width: double.infinity,
          height: layout.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              for (int slot = 0; slot < slotCount; slot++)
                TileSlot(
                  key: ValueKey<String>('slot-$slot'),
                  layout: layout,
                  index: slot,
                  child: WordSlotView(
                    bonus: bonuses[slot],
                    size: layout.tileSize,
                    isNext: isRevealed && slot == placedTiles.length,
                  ),
                ),
              if (isRevealed)
                for (int slot = 0; slot < placedTiles.length; slot++)
                  TileSlot(
                    key: ValueKey<String>('placed-${placedTiles[slot].id}'),
                    layout: layout,
                    index: slot,
                    child: TileEntrance(
                      child: LetterTileView(
                        tile: placedTiles[slot],
                        variant: TileVariant.placed,
                        bonus: bonuses[slot],
                        size: layout.tileSize,
                        onTap: () => onSlotTapped(slot),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  /// Largest tile size that fits [count] tiles plus gaps into [availableWidth].
  static double tileSizeFor(double availableWidth, int count) =>
      TileStripLayout.resolve(availableWidth: availableWidth, count: count).tileSize;
}
