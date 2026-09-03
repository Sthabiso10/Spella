import 'dart:math';

import 'package:flutter/material.dart';
import 'package:spella/ui/common/ui_helpers.dart';

/// Where every tile in a row of tiles sits.
///
/// The rack and the word both need to lay out a run of equally sized squares
/// that wraps when it has to, and both need to know a tile's position as a
/// number rather than as a slot in a [Wrap] - because a tile that knows where
/// it is can be told to slide there. That is the whole reason this exists: a
/// `Wrap` re-flows instantly, so pulling a letter out of the middle of a word
/// teleports every letter after it.
@immutable
class TileStripLayout {
  const TileStripLayout({
    required this.tileSize,
    required this.gap,
    required this.perRow,
    required this.count,
    required this.width,
  });

  /// Fits [count] tiles into [availableWidth], shrinking them to a floor and
  /// then wrapping onto further rows once even that will not fit.
  factory TileStripLayout.resolve({
    required double availableWidth,
    required int count,
    double gap = AppSpacing.sm,
    double minTile = 34,
    double maxTile = 54,
  }) {
    final double safeWidth = availableWidth.isFinite && availableWidth > 0
        ? availableWidth
        : maxTile;
    if (count <= 0) {
      return TileStripLayout(
        tileSize: maxTile,
        gap: gap,
        perRow: 1,
        count: 0,
        width: safeWidth,
      );
    }

    final double ideal = (safeWidth - gap * (count - 1)) / count;
    final double tileSize = ideal.clamp(minTile, maxTile);

    // How many of those actually fit on one line. Only ever less than [count]
    // when the tiles have already been shrunk as far as they are allowed to go.
    final int fits = ((safeWidth + gap) / (tileSize + gap)).floor();
    final int perRow = fits.clamp(1, count);

    return TileStripLayout(
      tileSize: tileSize,
      gap: gap,
      perRow: perRow,
      count: count,
      width: safeWidth,
    );
  }

  final double tileSize;
  final double gap;

  /// Tiles per line.
  final int perRow;

  /// Total tiles the strip is laying out.
  final int count;

  /// Width the strip was laid out against.
  final double width;

  int get rows => count <= 0 ? 0 : (count / perRow).ceil();

  double get height => rows <= 0 ? 0 : rows * tileSize + (rows - 1) * gap;

  /// Top-left corner of the tile at [index].
  ///
  /// Every row is centred on its own, so a wrapped strip ends with a short
  /// centred line rather than a ragged left-aligned one.
  Offset offsetFor(int index) {
    if (count <= 0) return Offset.zero;

    final int clamped = index.clamp(0, count - 1);
    final int row = clamped ~/ perRow;
    final int column = clamped % perRow;
    final int itemsInRow = min(perRow, count - row * perRow);
    final double rowWidth = itemsInRow * tileSize + (itemsInRow - 1) * gap;

    return Offset(
      (width - rowWidth) / 2 + column * (tileSize + gap),
      row * (tileSize + gap),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TileStripLayout &&
          other.tileSize == tileSize &&
          other.gap == gap &&
          other.perRow == perRow &&
          other.count == count &&
          other.width == width);

  @override
  int get hashCode => Object.hash(tileSize, gap, perRow, count, width);
}

/// Puts [child] at its place in [layout] and slides it whenever that place
/// changes.
///
/// Keyed by the tile rather than by the position, so removing a letter from the
/// middle of a word makes the letters after it walk left into the gap instead
/// of blinking into their new slots.
class TileSlot extends StatelessWidget {
  const TileSlot({
    required this.layout,
    required this.index,
    required this.child,
    this.duration = AppMotion.normal,
    super.key,
  });

  final TileStripLayout layout;
  final int index;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final Offset offset = layout.offsetFor(index);

    return AnimatedPositioned(
      duration: duration,
      curve: AppMotion.standard,
      left: offset.dx,
      top: offset.dy,
      width: layout.tileSize,
      height: layout.tileSize,
      child: child,
    );
  }
}

/// Fades and lifts [child] into place, optionally after a delay.
///
/// Used to deal a rack in rather than have it appear all at once. The stagger
/// is small on purpose - it should read as tiles landing, not as a queue.
class TileEntrance extends StatefulWidget {
  const TileEntrance({
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.normal,
    super.key,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<TileEntrance> createState() => _TileEntranceState();
}

class _TileEntranceState extends State<TileEntrance>
    with SingleTickerProviderStateMixin {
  /// The delay is folded into the controller as a leading interval rather than
  /// run off a `Future.delayed`. A stagger built from timers leaves one
  /// outstanding per tile, which a widget test rightly complains about, and it
  /// drifts from the animation it is supposed to be part of.
  late final Duration _total = widget.delay + widget.duration;

  late final double _start = _total.inMicroseconds == 0
      ? 0
      : widget.delay.inMicroseconds / _total.inMicroseconds;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _total,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Interval(_start, 1, curve: Curves.easeOut),
  );

  late final Animation<double> _scale = Tween<double>(begin: 0.82, end: 1).animate(
    CurvedAnimation(
      parent: _controller,
      // Overshoots very slightly, which is what makes a tile read as landing
      // rather than as fading up. Safe on a scale, not on an opacity.
      curve: Interval(_start, 1, curve: AppMotion.settle),
    ),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
