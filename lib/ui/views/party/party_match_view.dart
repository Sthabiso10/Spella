import 'package:flutter/material.dart';
import 'package:spella/app/app.router.dart';
import 'package:spella/core/models/party.dart';
import 'package:spella/core/models/word_play.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/views/match/widgets/match_header.dart';
import 'package:spella/ui/views/match/widgets/match_overlays.dart';
import 'package:spella/ui/views/match/widgets/rack_row.dart';
import 'package:spella/ui/views/match/widgets/word_builder.dart';
import 'package:spella/ui/views/party/party_match_viewmodel.dart';
import 'package:spella/ui/views/party/widgets/handoff_overlay.dart';
import 'package:spella/ui/views/match/widgets/play_status_panel.dart';
import 'package:spella/ui/views/party/widgets/party_round_recap.dart';
import 'package:spella/ui/views/party/widgets/turn_result_overlay.dart';
import 'package:spella/ui/widgets/app_avatar.dart';
import 'package:spella/ui/widgets/app_buttons.dart';
import 'package:spella/ui/widgets/count_up_text.dart';
import 'package:spella/ui/widgets/page_width.dart';
import 'package:spella/ui/widgets/shake.dart';
import 'package:stacked/stacked.dart';

/// The pass-and-play game screen.
///
/// Shares the duel's header, board, rack and tiles outright - a word game
/// should not feel like a different product because there are four people
/// round the table. What changes is who the screen belongs to: a name badge
/// replaces the scoreline, since only one person can act at a time and the
/// standings would only tell them what they already learned at the handoff.
class PartyMatchView extends StackedView<PartyMatchViewModel> {
  const PartyMatchView({required this.arguments, super.key});

  final PartyMatchViewArguments arguments;

  @override
  Widget builder(BuildContext context, PartyMatchViewModel viewModel, Widget? child) {
    final AppPalette palette = context.palette;

    return PopScope(
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
                      onPause: viewModel.canPause ? viewModel.pauseTurn : null,
                    ),
                    _TurnBadge(viewModel: viewModel),
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
  PartyMatchViewModel viewModelBuilder(BuildContext context) =>
      PartyMatchViewModel(roster: arguments.players);

  @override
  void onViewModelReady(PartyMatchViewModel viewModel) => viewModel.initialise();

  /// Whichever overlay the current phase calls for.
  ///
  /// A party turn spends most of its life under one of these - the board is
  /// only uncovered between the count-in and the player committing - so they
  /// are the mode's main surface rather than an interruption to it.
  Widget? _overlayFor(PartyMatchViewModel viewModel) {
    switch (viewModel.phase) {
      case PartyPhase.handoff:
        return HandoffOverlay(
          key: ValueKey<String>('handoff-${viewModel.currentPlayer.id}'
              '-${viewModel.roundNumber}'),
          player: viewModel.currentPlayer,
          nextPlayer: viewModel.nextPlayer,
          roundNumber: viewModel.roundNumber,
          totalRounds: viewModel.totalRounds,
          turnNumber: viewModel.turnNumber,
          playerCount: viewModel.playerCount,
          standings: viewModel.standings,
          onReady: viewModel.beginTurn,
          onSkip: viewModel.skipTurn,
        );
      case PartyPhase.countdown:
        return CountdownOverlay(
          key: const ValueKey<String>('countdown'),
          secondsRemaining: viewModel.countdownRemaining,
          playerName: viewModel.currentPlayer.name,
        );
      case PartyPhase.paused:
        return PausedOverlay(
          key: const ValueKey<String>('paused'),
          secondsRemaining: viewModel.secondsRemaining,
          onResume: viewModel.resumeTurn,
          onQuit: viewModel.requestQuit,
        );
      case PartyPhase.turnResult:
        final WordPlay? play = viewModel.lastPlay;
        final PartyPlayer? player = viewModel.lastPlayer;
        if (play == null || player == null) return null;

        return TurnResultOverlay(
          key: ValueKey<String>('turn-${player.id}-${viewModel.roundNumber}'),
          player: player,
          play: play,
          total: viewModel.lastPlayerTotal,
          nextPlayer: viewModel.nextPlayer,
          isRoundComplete: viewModel.isRoundComplete,
          onContinue: viewModel.continueFromTurn,
        );
      case PartyPhase.roundRecap:
        return MatchScrim(
          key: ValueKey<String>('recap-${viewModel.roundNumber}'),
          child: PartyRoundRecap(
            roundNumber: viewModel.roundNumber,
            lines: viewModel.roundLines,
            bestPossibleWord: viewModel.bestPossibleWord,
            isFinalRound: viewModel.isFinalRound,
            onContinue: viewModel.continueFromRecap,
          ),
        );
      case PartyPhase.playing:
      case PartyPhase.finishing:
        return null;
    }
  }
}

/// Whose turn this is, and what they have banked so far.
///
/// A duel puts both scores here. With six players that would be a table, and a
/// table is the wrong thing to put above a board somebody is timing themselves
/// against - so it names one person and their own total, and nothing else.
class _TurnBadge extends StatelessWidget {
  const _TurnBadge({required this.viewModel});

  final PartyMatchViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.divider)),
      ),
      child: Row(
        children: <Widget>[
          AppAvatar(
            player: viewModel.currentPlayer.asPlayer,
            size: 32,
            ring: AvatarRing.none,
          ),
          horizontalSpace(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'YOUR TURN',
                  style: AppTextStyles.overline.copyWith(color: palette.textMuted),
                ),
                verticalSpace(2),
                Text(
                  viewModel.currentPlayer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingSmall.copyWith(color: palette.textPrimary),
                ),
              ],
            ),
          ),
          horizontalSpace(AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              CountUpText(
                value: viewModel.currentPlayerTotal,
                style: AppTextStyles.score.copyWith(color: palette.textPrimary),
              ),
              verticalSpace(2),
              Text(
                'TOTAL',
                style: AppTextStyles.overline.copyWith(color: palette.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The live verdict on the word being built.
class _PlayStatus extends StatelessWidget {
  const _PlayStatus({required this.viewModel});

  final PartyMatchViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Center(
        child: PlayStatusPanel(
          isValid: viewModel.validation.isValid,
          score: viewModel.validation.score,
          message: viewModel.validation.message,
        ),
      ),
    );
  }
}

/// The word slots, the rack, and the commit controls.
class _PlayArea extends StatelessWidget {
  const _PlayArea({required this.viewModel});

  final PartyMatchViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        children: <Widget>[
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
          verticalSpace(AppSpacing.md),
          // Handing the device on early is a real move in a party game, so it
          // gets a real control - quiet, but always reachable.
          AppButton(
            label: 'Pass turn',
            style: AppButtonStyle.ghost,
            size: AppButtonSize.small,
            expand: false,
            onPressed: viewModel.isInteractive ? viewModel.passTurn : null,
          ),
        ],
      ),
    );
  }
}
