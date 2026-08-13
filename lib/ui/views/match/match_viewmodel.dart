import 'dart:async';

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
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

/// Where a round is in its lifecycle.
enum MatchPhase {
  /// Rack is being revealed; input is locked.
  dealing,

  /// The clock is running and the player can build a word.
  playing,

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
class MatchViewModel extends BaseViewModel {
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

  Timer? _clock;
  MatchPhase _phase = MatchPhase.dealing;
  PlayValidation _validation = const PlayValidation.invalid(
    word: '',
    reason: PlayRejection.empty,
  );
  int _secondsRemaining = 0;
  bool _showRejection = false;
  WordDefinition? _roundDefinition;
  bool _isLoadingDefinition = false;
  final Set<PowerUp> _powerUpsUsedThisRound = <PowerUp>{};

  GameMatch get match => _match;

  MatchPhase get phase => _phase;

  PlayValidation get validation => _validation;

  Player get me => _playerService.currentPlayer;

  int get secondsRemaining => _secondsRemaining;

  /// Clock as a 0..1 value for the timer ring.
  double get clockProgress =>
      mode.secondsPerRound == 0 ? 0 : _secondsRemaining / mode.secondsPerRound;

  /// `true` when the clock is low enough to warrant the warning colour.
  bool get isTimeCritical => _secondsRemaining <= 10;

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

  /// A power-up is available while playing, once per round, if affordable.
  bool canUsePowerUp(PowerUp powerUp) =>
      isInteractive && !isPowerUpUsed(powerUp) && me.coins >= powerUp.cost;

  /// Sets the match up and deals the first round.
  void initialise() {
    _match = _engine.createMatch(mode: mode, host: me, guest: opponent);
    _beginRound();
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

    _stopClock();
    _haptics.success();

    _match = _engine.submitHostPlay(
      _match,
      WordPlay(
        playerId: me.id,
        word: _validation.word,
        breakdown: _validation.breakdown,
        secondsTaken: mode.secondsPerRound - _secondsRemaining,
      ),
    );

    await _playOpponentTurn();
  }

  /// Spends coins on [powerUp] and applies its effect.
  Future<void> usePowerUp(PowerUp powerUp) async {
    if (!canUsePowerUp(powerUp)) return;
    if (!_playerService.spendCoins(powerUp.cost)) return;

    _powerUpsUsedThisRound.add(powerUp);
    _haptics.notify();

    switch (powerUp) {
      case PowerUp.hint:
        final String? hint = _engine.hintFor(round);
        if (hint != null) _board.spell(hint);
      case PowerUp.freeze:
        _secondsRemaining += PowerUp.freezeSeconds;
      case PowerUp.swap:
        _swapUnusedTiles();
    }

    _revalidate();
  }

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

    _stopClock();
    final DialogResponse<dynamic>? response = await _dialog.showConfirmationDialog(
      title: 'Leave the match?',
      description: 'Your progress in this game will be lost.',
      confirmationTitle: 'Leave',
      cancelTitle: 'Keep playing',
    );

    if (response?.confirmed ?? false) {
      _navigation.back();
      return;
    }
    if (_phase == MatchPhase.playing) _startClock();
  }

  @override
  void dispose() {
    _stopClock();
    super.dispose();
  }

  void _beginRound() {
    _board = _engine.boardFor(_match);
    _secondsRemaining = mode.secondsPerRound;
    _roundDefinition = null;
    _isLoadingDefinition = false;
    _powerUpsUsedThisRound.clear();
    _setPhase(MatchPhase.dealing);
    _revalidate();

    // Give the rack a beat to land before the clock starts.
    Future<void>.delayed(_dealDuration, () {
      if (disposed || _phase != MatchPhase.dealing) return;
      _setPhase(MatchPhase.playing);
      _startClock();
    });
  }

  void _startClock() {
    _stopClock();
    _clock = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (disposed) {
        timer.cancel();
        return;
      }

      _secondsRemaining--;
      if (_secondsRemaining <= 0) {
        _secondsRemaining = 0;
        _stopClock();
        unawaited(_timeUp());
        return;
      }

      // The speed bonus shrinks with the clock, so the preview has to follow.
      _revalidate();
    });
  }

  void _stopClock() {
    _clock?.cancel();
    _clock = null;
  }

  /// Plays whatever is on the board when time runs out, or passes.
  Future<void> _timeUp() async {
    _haptics.error();

    final WordPlay play = _validation.isValid
        ? WordPlay(
            playerId: me.id,
            word: _validation.word,
            breakdown: _validation.breakdown,
            secondsTaken: mode.secondsPerRound,
          )
        : WordPlay.passed(playerId: me.id, secondsTaken: mode.secondsPerRound);

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
  void _swapUnusedTiles() {
    final List<LetterTile> kept = _board.placed;
    final int toRedraw = _board.slotCount - kept.length;
    if (toRedraw <= 0) return;

    final List<LetterTile> refreshed = _rackGenerator.redraw(kept, count: toRedraw);
    final RoundBoard replacement = RoundBoard(rack: refreshed, bonuses: _board.bonuses);
    for (final LetterTile tile in kept) {
      replacement.place(tile);
    }
    _board = replacement;
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
      secondsRemaining: _secondsRemaining,
    );
    rebuildUi();
  }

  void _setPhase(MatchPhase phase) {
    _phase = phase;
    rebuildUi();
  }
}
