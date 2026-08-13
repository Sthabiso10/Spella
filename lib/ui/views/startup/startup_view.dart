import 'package:flutter/material.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/views/startup/startup_viewmodel.dart';
import 'package:stacked/stacked.dart';

/// Splash screen. Sets the wordmark while services warm up.
///
/// The old splash spelled the name out in six tiles, which told the player the
/// app was about letters and then made them wait through it. A wordmark that
/// settles in under half a second says the same thing and gets out of the way -
/// and the letters arriving one at a time is the only spelling reference the
/// screen needs.
class StartupView extends StackedView<StartupViewModel> {
  const StartupView({super.key});

  static const String _wordmark = 'SPELLA';

  @override
  Widget builder(BuildContext context, StartupViewModel viewModel, Widget? child) {
    final AppPalette palette = context.palette;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      for (int i = 0; i < _wordmark.length; i++)
                        _WordmarkLetter(letter: _wordmark[i], order: i),
                      // The full stop is the only accent on the screen. One
                      // mark of colour is enough to make a wordmark a logo.
                      _WordmarkLetter(
                        letter: '.',
                        order: _wordmark.length,
                        color: palette.accent,
                      ),
                    ],
                  ),
                  verticalSpace(AppSpacing.md),
                  const _Tagline(),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.section,
              child: Center(child: SizedBox(width: 96, child: _WarmupBar())),
            ),
          ],
        ),
      ),
    );
  }

  @override
  StartupViewModel viewModelBuilder(BuildContext context) => StartupViewModel();

  @override
  void onViewModelReady(StartupViewModel viewModel) => viewModel.runStartupLogic();
}

/// One letter of the wordmark, rising into place after a staggered delay.
class _WordmarkLetter extends StatelessWidget {
  const _WordmarkLetter({required this.letter, required this.order, this.color});

  final String letter;
  final int order;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppMotion.entrance,
      // Each letter starts a beat after the one before it. The interval is
      // short enough that the word still reads as a single arrival.
      curve: Interval((order * 0.07).clamp(0, 0.6), 1, curve: AppMotion.enter),
      builder: (BuildContext context, double value, Widget? child) => Opacity(
        opacity: value.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, (1 - value) * 12), child: child),
      ),
      child: Text(
        letter,
        style: AppTextStyles.displayMedium.copyWith(
          letterSpacing: -1,
          color: color ?? palette.textPrimary,
        ),
      ),
    );
  }
}

class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppMotion.entrance,
      curve: const Interval(0.5, 1, curve: AppMotion.enter),
      builder: (BuildContext context, double value, Widget? child) =>
          Opacity(opacity: value, child: child),
      child: Text(
        'SPELL IT OUT. SETTLE IT HERE.',
        style: AppTextStyles.overline.copyWith(color: palette.textMuted),
      ),
    );
  }
}

/// A hairline that fills while services initialise.
///
/// Not a spinner: a spinner says "something is happening somewhere", a bar says
/// "this is nearly done", which is the honest message for a one second wait.
class _WarmupBar extends StatelessWidget {
  const _WarmupBar();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return ClipRRect(
      borderRadius: AppRadius.pill,
      child: SizedBox(
        height: 2,
        child: LinearProgressIndicator(
          minHeight: 2,
          backgroundColor: palette.surfaceElevated,
          valueColor: AlwaysStoppedAnimation<Color>(palette.textMuted),
        ),
      ),
    );
  }
}
