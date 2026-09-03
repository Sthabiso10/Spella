import 'package:flutter/material.dart';
import 'package:spella/core/models/letter_tile.dart';
import 'package:spella/ui/widgets/letter_tile_view.dart';
import 'package:spella/ui/widgets/tile_strip.dart';

/// The player's tiles.
///
/// Tapping an available tile plays it into the next slot. A tile that is
/// already in the word stays in place as a ghost rather than disappearing, so
/// the rack never reflows mid-word and the letter you were about to reach for
/// is still where you last saw it.
///
/// Tiles are keyed by identity and positioned by rack order, which means a
/// shuffle is the letters swapping places in front of you rather than the row
/// blinking into a new arrangement.
class RackRow extends StatelessWidget {
  const RackRow({
    required this.rack,
    required this.placedTiles,
    required this.onTileTapped,
    this.isRevealed = true,
    super.key,
  });

  final List<LetterTile> rack;
  final List<LetterTile> placedTiles;
  final ValueChanged<LetterTile> onTileTapped;

  /// `false` while the rack is still covered. Nothing is built until it is, so
  /// the deal plays in full view and a hidden rack cannot be read off the tree.
  final bool isRevealed;

  /// Gap between one tile landing and the next.
  static const Duration _stagger = Duration(milliseconds: 45);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final TileStripLayout layout = TileStripLayout.resolve(
          availableWidth: constraints.maxWidth,
          count: rack.length,
        );

        return SizedBox(
          width: double.infinity,
          height: layout.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              if (isRevealed)
                for (int i = 0; i < rack.length; i++)
                  TileSlot(
                    key: ValueKey<String>('rack-${rack[i].id}'),
                    layout: layout,
                    index: i,
                    child: TileEntrance(
                      delay: _stagger * i,
                      child: LetterTileView(
                        tile: rack[i],
                        size: layout.tileSize,
                        variant: placedTiles.contains(rack[i])
                            ? TileVariant.spent
                            : TileVariant.rack,
                        onTap: () => onTileTapped(rack[i]),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}
