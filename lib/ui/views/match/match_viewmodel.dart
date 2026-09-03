import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:spella/app/app.locator.dart';
import 'package:spella/app/app.router.dart';
import 'package:spella/core/models/game_match.dart';
import 'package:spella/core/models/game_mode.dart';
import 'package:spella/core/models/game_round.dart';
import 'package:spella/core/models/letter_tile.dart';
import 'package:spella/core/models/match_result.dart';
import 'package:spella/core/models/play_validation.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/core/models/power_up.dart';
import 'package:spella/core/models/round_board.dart';
import 'package:spella/core/models/slot_bonus.dart';
import 'package:spella/core/models/word_definition.dart';
import 'package:spella/core/models/word_play.dart';
import 'package:spella/core/services/definition_service.dart';
import 'package:spella/core/services/game_engine_service.dart';
import 'package:spella/core/services/haptic_service.dart';
import 'package:spella/core/services/opponent_service.dart';
import 'package:spella/core/services/player_service.dart';
import 'package:spella/core/services/rack_generator_service.dart';
import 'package:spella/core/services/round_clock.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

/// Where a round is in its lifecycle.
enum MatchPhase {
  /// Rack is being revealed; input is locked.
  dealing,

  /// The clock is running and the player can build a word.
  playing,

  /// The game was interrupted - the app went to the background, or a call
  /// came in - and is holding until the player comes back to it.
  paused,

  /// The player has committed; the opponent is answering.
  opponentThinking,

  /// Both plays are in and the recap is showing.
  roundRecap,

  /// Match over, navigating to the results screen.
  finishing,
}

/// Runs a single match from the first deal to the results screen.
///
/// Owns the clock and the player's intent; every rule about what a word is
/// worth, what the opponent plays and what the match pays out lives in the
/// services this talks to.
class MatchViewModel extends BaseViewModel with WidgetsBindingObserver {
  MatchViewModel({required this.mode, required this.opponent});

  final GameMode mode;
  final Player opponent;

  final GameEngineService _engine = locator<GameEngineService>();
  final OpponentService _opponentService = locator<OpponentService>();
  final PlayerService _playerService = locator<PlayerService>();
  final RackGeneratorService _rackGenerator = locator<RackGeneratorService>();
  final DefinitionService _definitions = locator<DefinitionService>();
  final NavigationService _navigation = locator<NavigationService>();
  final DialogService _dialog = locator<DialogService>();
  final HapticService _haptics = locator<HapticService>();

  /// How long the "Round N" card stays up before the clock starts.
  static const Duration _dealDuration = Duration(milliseconds: 1100);

  /// Beat between the player committing and the opponent's word appearing.
  static const Duration _opponentSuspense = Duration(milliseconds: 1200);

  late GameMatch _match;
  late RoundBoard _board;

  late final RoundClock _clock = RoundClock(
    // The speed bonus shrinks with the clock, so the preview has to follow.
    onTick: _revalidate,
    onExpired: () => unawaited(_timeUp()),
  );

  MatchPhase _phase = MatchPhase.dealing;

  /// Phase to return to once the player comes back from a pause.
  MatchPhase _pausedFrom = MatchPhase.playing;

  /// `true` while a dialog is up. The clock is held but the board stays put,
  /// so the game is not also flashing a pause screen behind the dialog.
  bool _isSuspended = false;

  /// The deal finished while the game was interrupted, so the round is ready
  /// to start the moment the player is.
  bool _dealReady = false;

  PlayValidation _validation = const PlayValidation.invalid(
    word: '',
    reason: PlayRejection.empty,
  );
  bool _showRejection = false;
  WordDefinition? _roundDefinition;
  bool _isLoadingDefinition = false;
  final Set<PowerUp> _powerUpsUsedThisRound = <PowerUp>{};

  GameMatch get match => _match;

  MatchPhase get phase => _phase;

  PlayValidation get validation => _validation;

  Player get me => _playerService.currentPlayer;

  int get secondsRemaining => _clock.remaining;

  /// Clock as a 0..1 value for the timer ring.
  double get clockProgress => _clock.progress;

  /// `true` when the clock is low enough to warrant the warning colour.
  bool get isTimeCritical => _clock.remaining <= 10 && _phase == MatchPhase.playing;

  /// `true` while the game is holding for an interruption.
  bool get isPaused => _phase == MatchPhase.paused;

  /// `false` while the board is still covered, so the rack is neither readable
  /// nor animating underneath an overlay.
  bool get isBoardRevealed =>
      _phase != MatchPhase.dealing && _phase != MatchPhase.paused;

  GameRound get round => _match.rounds[_match.currentRoundIndex];

  int get roundNumber => round.number;

  int get totalRounds => mode.totalRounds;

  List<LetterTile> get rack => _board.rack;

  List<LetterTile> get placedTiles => _board.placed;

  List<SlotBonus> get bonuses => _board.bonuses;

  int get slotCount => _board.slotCount;

  int get myScore => _match.hostScore;

  int get opponentScore => _match.guestScore;

  /// Set briefly when an invalid word is submitted, so the view can shake.
  bool get showRejection => _showRejection;

  /// Input is only live while the clock runs.
  bool get isInteractive => _phase == MatchPhase.playing;

  bool get canSubmit => isInteractive && _validation.isValid;

  bool get canClear => isInteractive && !_board.isEmpty;

  /// The opponent's answer for the round being recapped.
  WordPlay? get opponentPlay => round.guestPlay;

  /// The player's answer for the round being recapped.
  WordPlay? get myPlay => round.hostPlay;

  /// Word the dictionary rates highest for this rack.
  String get bestPossibleWord => round.bestPossibleWord.toUpperCase();

  /// What the player's word means, once the lookup lands. `null` while it is
  /// in flight, when the word has no entry, or when there is no connection.
  WordDefinition? get roundDefinition => _roundDefinition;

  /// `true` while the definition is being fetched.
  bool get isLoadingDefinition => _isLoadingDefinition;

  bool get isFinalRound => roundNumber >= totalRounds;

  /// Per-round outcomes so far, for the round progress dots.
  List<GameRound> get completedRounds => _match.completedRounds;

  bool isPowerUpUsed(PowerUp powerUp) => _powerUpsUsedThisRound.contains(powerUp);

  /// A power-up is available while playing, once per round, if affordable -
  /// and only if it would actually do something. A Swap with every tile
  /// already placed has nothing to redraw, and charging for that is just
  /// taking the player's coins off them.
  bool canUsePowerUp(PowerUp powerUp) =>
      isInteractive &&
      !isPowerUpUsed(powerUp) &&
      me.coins >= powerUp.cost &&
      _wouldHaveEffect(powerUp);

  /// Sets the match up and deals the first round.
  void initialise() {
    WidgetsBinding.instance.addObserver(this);
    _match = _engine.createMatch(mode: mode, host: me, guest: opponent);
    _beginRound();
  }

  /// Holds the game when the app leaves the foreground.
  ///
  /// Without this the round clock keeps draining through a phone call, and the
  /// player comes back to a round they lost while not looking at it.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    _pauseForInterruption();
  }

  /// Picks the round back up after a pause.
  void resumeFromPause() {
    if (_phase != MatchPhase.paused) return;

    if (_pausedFrom == MatchPhase.dealing && !_dealReady) {
      _setPhase(MatchPhase.dealing);
      return;
    }
    _startPlaying();
  }

  /// Adds [tile] to the word being built.
  void onRackTileTapped(LetterTile tile) {
    if (!isInteractive || _board.isPlaced(tile)) return;
    if (!_board.place(tile)) return;

    _haptics.tileTap();
    _revalidate();
  }

  /// Returns the tile in [slotIndex] to the rack.
  void onSlotTapped(int slotIndex) {
    if (!isInteractive) return;
    if (!_board.removeAt(slotIndex)) return;

    _haptics.tileTap();
    _revalidate();
  }

  void clearWord() {
    if (!canClear) return;

    _board.clear();
    _haptics.tileTap();
    _revalidate();
  }

  void shuffleRack() {
    if (!isInteractive) return;

    _board.shuffleRack();
    _haptics.tileTap();
    rebuildUi();
  }

  /// Commits the word on the board, or flags it as invalid.
  Future<void> submitWord() async {
    if (!isInteractive) return;

    if (!_validation.isValid) {
      await _flashRejection();
      return;
    }

    _clock.stop();
    _haptics.success();

    _match = _engine.submitHostPlay(
      _match,
      WordPlay(
        playerId: me.id,
        word: _validation.word,
        breakdown: _validation.breakdown,
        secondsTaken: _clock.elapsed,
      ),
    );

    await _playOpponentTurn();
  }

  /// Spends coins on [powerUp] and applies its effect.
  ///
  /// The effect is applied first and only charged for if it landed, so a
  /// power-up can never take coins and do nothing.
  Future<void> usePowerUp(PowerUp powerUp) async {
    if (!canUsePowerUp(powerUp)) return;
    if (!_applyPowerUp(powerUp)) return;
    if (!_playerService.spendCoins(powerUp.cost)) return;

    _powerUpsUsedThisRound.add(powerUp);
    _haptics.notify();
    _revalidate();
  }

  /// Runs [powerUp]'s effect, reporting whether it changed anything.
  bool _applyPowerUp(PowerUp powerUp) {
    switch (powerUp) {
      case PowerUp.hint:
        final String? hint = _engine.hintFor(round);
        return hint != null && _board.spell(hint);
      case PowerUp.freeze:
        // Buys a longer round rather than a fuller one: the budget grows with
        // the balance, so the clock still reads as draining and the play is
        // still recorded as having taken the time it took.
        _clock.extend(PowerUp.freezeSeconds);
        return true;
      case PowerUp.swap:
        return _swapUnusedTiles();
    }
  }

  /// Whether [powerUp] has anything to do on the board as it stands.
  bool _wouldHaveEffect(PowerUp powerUp) => switch (powerUp) {
    PowerUp.hint => round.bestPossibleWord.isNotEmpty,
    PowerUp.freeze => true,
    PowerUp.swap => _board.placed.length < _board.slotCount,
  };

  /// Moves to the next round, or ends the match after the last one.
  Future<void> continueFromRecap() async {
    if (_phase != MatchPhase.roundRecap) return;

    if (_match.isComplete) {
      await _finishMatch();
      return;
    }

    _match = _engine.advanceRound(_match);
    _beginRound();
  }

  /// Asks before abandoning a match in progress.
  Future<void> requestQuit() async {
    if (_phase == MatchPhase.finishing) return;

    // Held rather than paused: the dialog is already the interruption, and a
    // pause screen behind it would just be a second one.
    _suspend();
    final DialogResponse<dynamic>? response = await _dialog.showConfirmationDialog(
      title: 'Leave the match?',
      description: 'Your progress in this game will be lost.',
      confirmationTitle: 'Leave',
      cancelTitle: 'Keep playing',
    );
    if (disposed) return;

    if (response?.confirmed ?? false) {
      _navigation.back();
      return;
    }
    _release();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock.dispose();
    super.dispose();
  }

  /// Stops the clock for something that is covering the board anyway.
  void _suspend() {
    if (_isSuspended) return;
    _isSuspended = true;
    _clock.pause();
  }

  /// Hands the round back after a [_suspend].
  void _release() {
    if (!_isSuspended) return;
    _isSuspended = false;

    if (_phase == MatchPhase.dealing && _dealReady) {
      _startPlaying();
      return;
    }
    if (_phase == MatchPhase.playing) _clock.resume();
  }

  /// Puts the game on a pause screen the player has to dismiss.
  void _pauseForInterruption() {
    if (_phase != MatchPhase.playing && _phase != MatchPhase.dealing) return;

    _pausedFrom = _phase;
    _clock.pause();
    _setPhase(MatchPhase.paused);
  }

  void _beginRound() {
    _board = _engine.boardFor(_match);
    _clock.reset(mode.secondsPerRound);
    _roundDefinition = null;
    _isLoadingDefinition = false;
    _dealReady = false;
    _powerUpsUsedThisRound.clear();
    _setPhase(MatchPhase.dealing);
    _revalidate();

    // Give the rack a beat to land before the clock starts.
    Future<void>.delayed(_dealDuration, () {
      if (disposed) return;

      // Interrupted mid-deal. Remember the rack is ready so the round can
      // start the instant the player comes back, rather than stalling on a
      // timer that has already been and gone.
      if (_phase != MatchPhase.dealing || _isSuspended) {
        _dealReady = true;
        return;
      }
      _startPlaying();
    });
  }

  void _startPlaying() {
    _dealReady = false;
    _setPhase(MatchPhase.playing);
    _clock.start();
  }

  /// Plays whatever is on the board when time runs out, or passes.
  Future<void> _timeUp() async {
    if (disposed) return;
    _haptics.error();

    final WordPlay play = _validation.isValid
        ? WordPlay(
            playerId: me.id,
            word: _validation.word,
            breakdown: _validation.breakdown,
            secondsTaken: _clock.elapsed,
          )
        : WordPlay.passed(playerId: me.id, secondsTaken: _clock.elapsed);

    _match = _engine.submitHostPlay(_match, play);
    await _playOpponentTurn();
  }

  Future<void> _playOpponentTurn() async {
    _setPhase(MatchPhase.opponentThinking);

    final WordPlay play = await _opponentService.playRound(
      round: round,
      mode: mode,
      opponent: opponent,
    );
    await Future<void>.delayed(_opponentSuspense);
    if (disposed) return;

    _match = _engine.submitGuestPlay(_match, play);
    _haptics.notify();
    _setPhase(MatchPhase.roundRecap);

    // Deliberately not awaited: the recap shows immediately and the definition
    // fills in behind it if and when it arrives.
    unawaited(_loadDefinitionForRound());
  }

  /// Fetches the meaning of whichever word was worth showing this round -
  /// the player's if they found one, otherwise the best word on the rack.
  Future<void> _loadDefinitionForRound() async {
    final WordPlay? play = myPlay;
    final String word = play != null && !play.isPass ? play.word : round.bestPossibleWord;
    if (word.isEmpty) return;

    _isLoadingDefinition = true;
    rebuildUi();

    final WordDefinition? definition = await _definitions.lookup(word);
    if (disposed) return;

    _roundDefinition = definition;
    _isLoadingDefinition = false;
    rebuildUi();
  }

  Future<void> _finishMatch() async {
    _setPhase(MatchPhase.finishing);

    final MatchResult result = _engine.buildResult(_match);
    _playerService.applyMatchResult(result);

    await _navigation.replaceWith(
      Routes.results,
      arguments: ResultsViewArguments(result: result),
    );
  }

  /// Redraws the tiles the player has not placed yet.
  ///
  /// Reports `false` when there is nothing left to redraw, so the caller knows
  /// not to charge for it.
  bool _swapUnusedTiles() {
    final List<LetterTile> kept = _board.placed;
    final int toRedraw = _board.slotCount - kept.length;
    if (toRedraw <= 0) return false;

    final List<LetterTile> refreshed = _rackGenerator.redraw(kept, count: toRedraw);
    final RoundBoard replacement = RoundBoard(rack: refreshed, bonuses: _board.bonuses);
    for (final LetterTile tile in kept) {
      replacement.place(tile);
    }
    _board = replacement;
    return true;
  }

  Future<void> _flashRejection() async {
    _haptics.error();
    _showRejection = true;
    rebuildUi();

    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (disposed) return;

    _showRejection = false;
    rebuildUi();
  }

  void _revalidate() {
    _validation = _engine.validate(
      board: _board,
      mode: mode,
      secondsRemaining: _clock.remaining,
    );
    rebuildUi();
  }

  void _setPhase(MatchPhase phase) {
    _phase = phase;
    rebuildUi();
  }
}
