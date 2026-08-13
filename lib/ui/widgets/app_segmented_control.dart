import 'package:flutter/material.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';

/// A two-or-more way switch with a thumb that slides between options.
///
/// The thumb is animated rather than swapped because the movement is the
/// feedback: you see which way the selection went, so the control explains
/// itself the first time it is used.
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    required this.values,
    required this.selected,
    required this.labelFor,
    required this.onChanged,
    super.key,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final int index = values.indexOf(selected).clamp(0, values.length - 1);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double padding = 3;
        final double segmentWidth = (constraints.maxWidth - padding * 2) / values.length;

        return Container(
          height: 38,
          padding: const EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: palette.recess,
            borderRadius: AppRadius.control,
            border: Border.all(color: palette.border),
          ),
          child: Stack(
            children: <Widget>[
              AnimatedPositioned(
                duration: AppMotion.normal,
                curve: AppMotion.standard,
                left: index * segmentWidth,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.surfaceHover,
                    borderRadius: const BorderRadius.all(AppRadius.xs),
                    border: Border.all(color: palette.border),
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  for (final T value in values)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(value),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: AppMotion.quick,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: value == selected
                                  ? palette.textPrimary
                                  : palette.textMuted,
                            ),
                            child: Text(labelFor(value)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
