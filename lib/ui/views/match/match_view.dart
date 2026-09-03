import 'package:flutter/material.dart';
import 'package:spella/app/app.router.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/views/match/match_viewmodel.dart';
import 'package:spella/ui/views/match/widgets/match_header.dart';
import 'package:spella/ui/views/match/widgets/match_overlays.dart';
import 'package:spella/ui/views/match/widgets/play_status_panel.dart';
import 'package:spella/ui/views/match/widgets/power_up_bar.dart';
import 'package:spella/ui/views/match/widgets/rack_row.dart';
import 'package:spella/ui/views/match/widgets/round_recap_sheet.dart';
import 'package:spella/ui/views/match/widgets/scoreboard_card.dart';
import 'package:spella/ui/views/match/widgets/word_builder.dart';
import 'package:spella/ui/widgets/app_buttons.dart';
import 'package:spella/ui/widgets/page_width.dart';
import 'package:spella/ui/widgets/shake.dart';
import 'package:stacked/stacked.dart';

/// The game screen: build the highest scoring word you can before the clock
/// runs out, round after round.
///
/// This screen is deliberately unlike the rest of the app. There are no cards,
/// no section headers and almost no chrome - just a clock, a scoreline, the
/// board, and one large figure telling you what your word is currently worth.
/// Everything that is not the game has been taken away so the game can be the
/// only thing in the room.
class MatchView extends StackedView<MatchViewModel> {
  const MatchView({required this.arguments, super.key});

  final MatchViewArguments arguments;

  @override
  Widget builder(BuildContext context, MatchViewModel viewModel, Widget? child) {
    final AppPalette palette = context.palette;

    return PopScope(
      // Leaving mid-match needs confirming, so the back gesture is routed
      // through the same path as the header button.
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) viewModel.requestQuit();
      },
      child: Scaffold(
        backgroundColor: palette.canvas,
        body: Stack(
          children: <Widget>[
            SafeArea(
              child: PageWidth(
                child: Column(
                  children: <Widget>[
                    MatchHeader(
                      secondsRemaining: viewModel.secondsRemaining,
                      progress: viewModel.clockProgress,
                      isCritical: viewModel.isTimeCritical,
                      roundNumber: viewModel.roundNumber,
                      totalRounds: viewModel.totalRounds,
                      onLeave: viewModel.requestQuit,
                    ),
                    ScoreboardCard(
                      me: viewModel.me,
                      opponent: viewModel.opponent,
                      myScore: viewModel.myScore,
                      opponentScore: viewModel.opponentScore,
                      completedRounds: viewModel.completedRounds,
                      totalRounds: viewModel.totalRounds,
                    ),
                    Expanded(child: _PlayStatus(viewModel: viewModel)),
                    _PlayArea(viewModel: viewModel),
                  ],
                ),
              ),
            ),
            MatchOverlaySlot(child: _overlayFor(viewModel)),
          ],
        ),
      ),
    );
  }

  @override
  MatchViewModel viewModelBuilder(BuildContext context) =>
      MatchViewModel(mode: arguments.mode, opponent: arguments.opponent);

  @override
  void onViewModelReady(MatchViewModel viewModel) => viewModel.initialise();

  /// Whichever overlay the current phase calls for, or `null` for a clear
  /// board. Every one is keyed so the switcher cross-fades between them
  /// rather than swapping their contents underneath a single fade.
  Widget? _overlayFor(MatchViewModel viewModel) {
    switch (viewModel.phase) {
      case MatchPhase.dealing:
        return DealOverlay(
          key: ValueKey<String>('deal-${viewModel.roundNumber}'),
          roundNumber: viewModel.roundNumber,
          totalRounds: viewModel.totalRounds,
          rackSize: viewModel.slotCount,
        );
      case MatchPhase.paused:
        return PausedOverlay(
          key: const ValueKey<String>('paused'),
          secondsRemaining: viewModel.secondsRemaining,
          onResume: viewModel.resumeFromPause,
          onQuit: viewModel.requestQuit,
        );
      case MatchPhase.opponentThinking:
        return OpponentThinkingOverlay(
          key: const ValueKey<String>('thinking'),
          opponent: viewModel.opponent,
        );
      case MatchPhase.roundRecap:
        return MatchScrim(
          key: ValueKey<String>('recap-${viewModel.roundNumber}'),
          child: RoundRecapSheet(
            roundNumber: viewModel.roundNumber,
            me: viewModel.me,
            opponent: viewModel.opponent,
            myPlay: viewModel.myPlay,
            opponentPlay: viewModel.opponentPlay,
            bestPossibleWord: viewModel.bestPossibleWord,
            definition: viewModel.roundDefinition,
            isLoadingDefinition: viewModel.isLoadingDefinition,
            isFinalRound: viewModel.isFinalRound,
            onContinue: viewModel.continueFromRecap,
          ),
        );
      case MatchPhase.playing:
      case MatchPhase.finishing:
        return null;
    }
  }
}

/// The live verdict on the word being built, and the power-up bar.
///
/// This is the focal point of the screen. A playable word puts its value up in
/// the largest figure in the app, in the one green the product owns; anything
/// else states the problem in a quiet line and gets out of the way. The
/// difference between those two states is the game's core feedback loop, so it
/// is carried by size, weight and colour all at once.
class _PlayStatus extends StatelessWidget {
  const _PlayStatus({required this.viewModel});

  final MatchViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Center(
              child: PlayStatusPanel(
                isValid: viewModel.validation.isValid,
                score: viewModel.validation.score,
                message: viewModel.validation.message,
              ),
            ),
          ),
          PowerUpBar(
            onUse: viewModel.usePowerUp,
            isAvailable: viewModel.canUsePowerUp,
            isUsed: viewModel.isPowerUpUsed,
          ),
          verticalSpace(AppSpacing.xl),
        ],
      ),
    );
  }
}

/// The word slots, the rack, and the commit controls.
class _PlayArea extends StatelessWidget {
  const _PlayArea({required this.viewModel});

  final MatchViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        children: <Widget>[
          // A rejected word shakes rather than raising a dialog. It says "not
          // that one" and hands the turn straight back, which on a clock is the
          // only correction that does not cost the player the round.
          Shake(
            trigger: viewModel.showRejection,
            child: WordBuilder(
              isRevealed: viewModel.isBoardRevealed,
              slotCount: viewModel.slotCount,
              placedTiles: viewModel.placedTiles,
              bonuses: viewModel.bonuses,
              onSlotTapped: viewModel.onSlotTapped,
            ),
          ),
          verticalSpace(AppSpacing.xl),
          RackRow(
            isRevealed: viewModel.isBoardRevealed,
            rack: viewModel.rack,
            placedTiles: viewModel.placedTiles,
            onTileTapped: viewModel.onRackTileTapped,
          ),
          verticalSpace(AppSpacing.xl),
          Row(
            children: <Widget>[
              AppIconButton(
                icon: Icons.close_rounded,
                size: 48,
                tooltip: 'Clear word',
                onPressed: viewModel.canClear ? viewModel.clearWord : null,
              ),
              horizontalSpace(AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: 'Play Word',
                  size: AppButtonSize.large,
                  trailingIcon: Icons.arrow_forward_rounded,
                  onPressed: viewModel.isInteractive ? viewModel.submitWord : null,
                ),
              ),
              horizontalSpace(AppSpacing.md),
              AppIconButton(
                icon: Icons.shuffle_rounded,
                size: 48,
                tooltip: 'Shuffle rack',
                onPressed: viewModel.isInteractive ? viewModel.shuffleRack : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
