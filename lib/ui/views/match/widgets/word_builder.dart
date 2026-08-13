import 'package:flutter/material.dart';
import 'package:spella/core/models/letter_tile.dart';
import 'package:spella/core/models/slot_bonus.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/widgets/letter_tile_view.dart';

/// The word the player is building: filled slots first, then the empty ones.
///
/// Sizes its tiles to whatever width is available, so a six tile Blitz rack and
/// a nine tile Marathon rack both fit on one line without scrolling and without
/// either mode getting a cramped board.
class WordBuilder extends StatelessWidget {
  const WordBuilder({
    required this.slotCount,
    required this.placedTiles,
    required this.bonuses,
    required this.onSlotTapped,
    super.key,
  });

  final int slotCount;
  final List<LetterTile> placedTiles;
  final List<SlotBonus> bonuses;
  final ValueChanged<int> onSlotTapped;

  static const double _gap = AppSpacing.sm;
  static const double _minTile = 34;
  static const double _maxTile = 54;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double tileSize = tileSizeFor(constraints.maxWidth, slotCount);

        return Wrap(
          alignment: WrapAlignment.center,
          spacing: _gap,
          runSpacing: _gap,
          children: <Widget>[
            for (int slot = 0; slot < slotCount; slot++)
              slot < placedTiles.length
                  ? LetterTileView(
                      key: ValueKey<String>('slot-${placedTiles[slot].id}'),
                      tile: placedTiles[slot],
                      variant: TileVariant.placed,
                      bonus: bonuses[slot],
                      size: tileSize,
                      onTap: () => onSlotTapped(slot),
                    )
                  : WordSlotView(
                      key: ValueKey<int>(slot),
                      bonus: bonuses[slot],
                      size: tileSize,
                      isNext: slot == placedTiles.length,
                    ),
          ],
        );
      },
    );
  }

  /// Largest tile size that fits [count] tiles plus gaps into [availableWidth].
  static double tileSizeFor(double availableWidth, int count) {
    if (count <= 0) return _maxTile;

    final double usable = availableWidth - _gap * (count - 1);
    return (usable / count).clamp(_minTile, _maxTile);
  }
}
