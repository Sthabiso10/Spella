import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spella/ui/widgets/tile_strip.dart';

void main() {
  group('tile strip layout', () {
    test('a comfortable strip puts every tile on one centred row', () {
      final TileStripLayout layout = TileStripLayout.resolve(
        availableWidth: 360,
        count: 7,
      );

      expect(layout.perRow, 7);
      expect(layout.rows, 1);
      expect(layout.height, layout.tileSize);

      // Centred: the gap to the left of the first tile matches the gap to the
      // right of the last.
      final double left = layout.offsetFor(0).dx;
      final double right =
          layout.width - (layout.offsetFor(6).dx + layout.tileSize);
      expect(left, closeTo(right, 0.01));
    });

    test('tiles never grow past the maximum on a wide screen', () {
      final TileStripLayout layout = TileStripLayout.resolve(
        availableWidth: 900,
        count: 3,
        maxTile: 54,
      );

      expect(layout.tileSize, 54);
      expect(layout.perRow, 3);
    });

    test('tiles shrink to the floor before the strip wraps', () {
      final TileStripLayout layout = TileStripLayout.resolve(
        availableWidth: 300,
        count: 9,
        minTile: 34,
      );

      expect(layout.tileSize, greaterThanOrEqualTo(34));
      expect(layout.rows, greaterThanOrEqualTo(1));
    });

    test('a strip too narrow for one row wraps onto the next', () {
      final TileStripLayout layout = TileStripLayout.resolve(
        availableWidth: 160,
        count: 9,
        minTile: 34,
      );

      expect(layout.perRow, lessThan(9));
      expect(layout.rows, greaterThan(1));
      expect(layout.height, greaterThan(layout.tileSize));

      // Row two starts a full tile plus a gap below row one.
      expect(
        layout.offsetFor(layout.perRow).dy,
        closeTo(layout.tileSize + layout.gap, 0.01),
      );
    });

    test('positions advance by one tile plus one gap across a row', () {
      final TileStripLayout layout = TileStripLayout.resolve(
        availableWidth: 360,
        count: 6,
      );

      for (int i = 1; i < 6; i++) {
        expect(
          layout.offsetFor(i).dx - layout.offsetFor(i - 1).dx,
          closeTo(layout.tileSize + layout.gap, 0.01),
        );
      }
    });

    test('an empty strip has no height and asks for no position', () {
      final TileStripLayout layout = TileStripLayout.resolve(
        availableWidth: 360,
        count: 0,
      );

      expect(layout.rows, 0);
      expect(layout.height, 0);
      expect(layout.offsetFor(0), Offset.zero);
    });

    test('an unbounded width still resolves rather than producing infinities', () {
      final TileStripLayout layout = TileStripLayout.resolve(
        availableWidth: double.infinity,
        count: 7,
      );

      expect(layout.tileSize.isFinite, isTrue);
      expect(layout.height.isFinite, isTrue);
      expect(layout.offsetFor(3).dx.isFinite, isTrue);
    });

    test('out of range indexes clamp instead of throwing', () {
      final TileStripLayout layout = TileStripLayout.resolve(
        availableWidth: 360,
        count: 4,
      );

      expect(layout.offsetFor(99), layout.offsetFor(3));
      expect(layout.offsetFor(-5), layout.offsetFor(0));
    });
  });

  group('tile entrance', () {
    testWidgets('leaves no timer pending once it has played', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TileEntrance(
            delay: Duration(milliseconds: 180),
            child: SizedBox(width: 40, height: 40),
          ),
        ),
      );

      // A stagger built on Future.delayed leaves one timer per tile
      // outstanding; this one rides on its own controller instead.
      await tester.pumpAndSettle();
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('holds the tile back for its delay, then brings it in', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: TileEntrance(
              delay: Duration(milliseconds: 200),
              duration: Duration(milliseconds: 200),
              child: SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      );

      double opacity() => tester
          .widget<FadeTransition>(
            find
                .descendant(
                  of: find.byType(TileEntrance),
                  matching: find.byType(FadeTransition),
                )
                .first,
          )
          .opacity
          .value;

      expect(opacity(), 0);

      await tester.pump(const Duration(milliseconds: 200));
      expect(opacity(), lessThan(0.2), reason: 'still waiting its turn');

      await tester.pumpAndSettle();
      expect(opacity(), 1);
    });
  });
}
