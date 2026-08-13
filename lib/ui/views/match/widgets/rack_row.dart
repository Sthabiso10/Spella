import 'package:flutter/material.dart';
import 'package:spella/core/models/letter_tile.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/views/match/widgets/word_builder.dart';
import 'package:spella/ui/widgets/letter_tile_view.dart';

/// The player's tiles.
///
/// Tapping an available tile plays it into the next slot. A tile that is
/// already in the word stays in place as a ghost rather than disappearing, so
/// the rack never reflows mid-word and the letter you were about to reach for
/// is still where you last saw it.
class RackRow extends StatelessWidget {
  const RackRow({
    required this.rack,
    required this.placedTiles,
    required this.onTileTapped,
    super.key,
  });

  final List<LetterTile> rack;
  final List<LetterTile> placedTiles;
  final ValueChanged<LetterTile> onTileTapped;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double tileSize = WordBuilder.tileSizeFor(
          constraints.maxWidth,
          rack.length,
        );

        return Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final LetterTile tile in rack)
              LetterTileView(
                key: ValueKey<String>('rack-${tile.id}'),
                tile: tile,
                size: tileSize,
                variant: placedTiles.contains(tile)
                    ? TileVariant.spent
                    : TileVariant.rack,
                onTap: () => onTileTapped(tile),
              ),
          ],
        );
      },
    );
  }
}
