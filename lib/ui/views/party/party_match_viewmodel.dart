import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:spella/app/app.locator.dart';
import 'package:spella/app/app.router.dart';
import 'package:spella/core/models/game_mode.dart';
import 'package:spella/core/models/letter_tile.dart';
import 'package:spella/core/models/party.dart';
import 'package:spella/core/models/play_validation.dart';
import 'package:spella/core/models/round_board.dart';
import 'package:spella/core/models/slot_bonus.dart';
import 'package:spella/core/models/word_play.dart';
import 'package:spella/core/services/game_engine_service.dart';
import 'package:spella/core/services/haptic_service.dart';
import 'package:spella/core/services/round_clock.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:uuid/uuid.dart';

/// Where a party game is in its turn cycle.
enum PartyPhase {
  /// The device is being handed over. Nothing playable is on screen.
  handoff,

  /// The new player has the device and is being counted in.
  countdown,

  /// The clock is running for whoever is holding it.
  playing,

  /// Somebody asked for a minute, or the app went to the background.
  paused,

  /// The turn is over and its author is being shown what it was worth,
  /// before the device moves on.
  turnResult,

  /// Everyone has played the round; the words are on the table.
  roundRecap,

  /// Game over, navigating to the standings.
  finishing,
}

/// One player's line in the round recap.
class PartyRoundLine {
  const PartyRoundLine({
    required this.player,
    required this.play,
    required this.isWinner,
  });

  final PartyPlayer player;
  final WordPlay? play;
  final bool isWinner;
}

/// Runs a local pass-and-play game from the first handoff to the standings.
///
/// Structurally a sibling of `MatchViewModel` rather than a subclass: a duel
/// alternates between a person and a bot, while this rotates a single device
/// through a queue of people. What they share is the engine underneath - the
/// same rack generator, the same dictionary, the same scoring - so a word is
/// worth exactly what it would be worth in a ranked game.
///
/// The turn cycle is deliberately longer than a duel's. A duel hands straight
/// from one round to the next because the same person is holding the phone
/// throughout; here the device changes hands every turn, so each turn is
/// counted in, and ends on the player's own result rather than dumping them
/// into the next person's handoff before they have seen what they scored.
class PartyMatchViewModel extends BaseViewModel with WidgetsBindingObserver {
  PartyMatchViewModel({required this.roster});

  /// Turn order, as set on the setup screen.
  final List<PartyPlayer> roster;

  final GameEngineService _engine = locator<GameEngineService>();
  final NavigationService _navigation = locator<NavigationService>();
  final DialogService _dialog = locator<DialogService>();
  final HapticService _haptics = locator<HapticService>();

  /// Seconds counted off before a turn starts.
  static const int countdownSeconds = 3;

  late PartyMatch _match;
  late RoundBoard _board;

  late final RoundClock _clock = RoundClock(
    // The speed bonus shrinks with the clock, so the preview has to follow.
    onTick: _revalidate,
    onExpired: _timeUp,
  );

  Timer? _countdown;
  int _countdownRemaining = 0;

  PartyPhase _phase = PartyPhase.handoff;
  PlayValidation _validation = const PlayValidation.invalid(
    word: '',
    reason: PlayRejection.empty,
  );
  bool _showRejection = false;

  /// The turn just finished, held so its author can be shown the result
  /// before the device moves on.
  WordPlay? _lastPlay;
  PartyPlayer? _lastPlayer;

  /// `true` while a dialog is up and the clock should not be running.
  bool _isSuspended = false;

  GameMode get mode => GameMode.party;

  PartyMatch get match => _match;

  PartyPhase get phase => _phase;

  PlayValidation get validation => _validation;

  /// Whoever is holding the device.
  PartyPlayer get currentPlayer => _match.currentPlayer;

  /// Whoever plays after them, or `null` at the end of a round.
  PartyPlayer? get nextPlayer => _match.nextPlayer;

  int get turnNumber => _match.turnIndex + 1;

  int get playerCount => _match.players.length;

  int get roundNumber => _match.roundNumber;

  int get totalRounds => mode.totalRounds;

  int get secondsRemaining => _clock.remaining;

  double get clockProgress => _clock.progress;

  bool get isTimeCritical =>
      _clock.remaining <= 10 && _phase == PartyPhase.playing;

  /// Seconds left on the "get ready" count-in.
  int get countdownRemaining => _countdownRemaining;

  bool get isPaused => _phase == PartyPhase.paused;

  List<LetterTile> get rack => _board.rack;

  List<LetterTile> get placedTiles => _board.placed;

  List<SlotBonus> get bonuses => _board.bonuses;

  int get slotCount => _board.slotCount;

  /// Set briefly when an invalid word is submitted, so the view can shake.
  bool get showRejection => _showRejection;

  bool get isInteractive => _phase == PartyPhase.playing;

  bool get canClear => isInteractive && !_board.isEmpty;

  /// Pausing is offered here and not in a duel on purpose. A duel is one
  /// person racing a clock, and a pause button would just be a way to stop
  /// the clock and think; a party game is a device going round a table, where
  /// somebody needing a minute is normal and everybody can see it happen.
  bool get canPause => _phase == PartyPhase.playing;

  /// The board is only built once whoever is holding the device has said they
  /// are ready, so nobody reads the rack over the previous player's shoulder.
  bool get isBoardRevealed =>
      _phase == PartyPhase.playing ||
      _phase == PartyPhase.turnResult ||
      _phase == PartyPhase.roundRecap;

  String get bestPossibleWord => _match.currentRound.deal.bestPossibleWord.toUpperCase();

  bool get isFinalRound => _match.isFinalRound;

  /// The table so far, highest total first.
  List<PartyStanding> get standings => _match.standings;

  /// What the player holding the device has banked so far.
  int get currentPlayerTotal => _match.totalFor(currentPlayer.id);

  /// The turn that just finished.
  WordPlay? get lastPlay => _lastPlay;

  /// Who played it.
  PartyPlayer? get lastPlayer => _lastPlayer;

  /// Their running total, including the turn just played.
  int get lastPlayerTotal =>
      _lastPlayer == null ? 0 : _match.totalFor(_lastPlayer!.id);

  /// `true` when the turn just played was the last one of the round.
  bool get isRoundComplete => _match.isRoundComplete;

  /// The round just played, highest score first.
  ///
  /// Sorted rather than kept in turn order so the recap reads as a result: the
  /// word that took the round is the first thing on it.
  List<PartyRoundLine> get roundLines {
    final PartyRound round = _match.currentRound;
    final Set<String> winners = round.winnerIds;
    final List<PartyPlayer> ordered = List<PartyPlayer>.of(_match.players)
      ..sort(
        (PartyPlayer a, PartyPlayer b) =>
            round.scoreFor(b.id).compareTo(round.scoreFor(a.id)),
      );

    return <PartyRoundLine>[
      for (final PartyPlayer player in ordered)
        PartyRoundLine(
          player: player,
          play: round.playFor(player.id),
          isWinner: winners.contains(player.id),
        ),
    ];
  }

  /// Sets the game up and queues the first handoff.
  void initialise() {
    WidgetsBinding.instance.addObserver(this);
    _match = PartyMatch(
      id: const Uuid().v4(),
      mode: mode,
      players: roster,
      rounds: <PartyRound>[PartyRound(deal: _engine.dealRound(mode: mode, index: 0))],
    );
    _prepareTurn();
  }

  /// Holds the game when the app leaves the foreground, so a turn cannot run
  /// down while the phone is in somebody's pocket.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    if (_phase == PartyPhase.playing || _phase == PartyPhase.countdown) {
      pauseTurn();
    }
  }

  /// Called from the handoff screen once the next player has the device.
  void beginTurn() {
    if (_phase != PartyPhase.handoff) return;
    _startCountdown();
  }

  /// Hands the turn on without playing it, for somebody who is not at the
  /// table. Their round is recorded as a pass, exactly as if they had run out
  /// of time, so the standings stay honest.
  void skipTurn() {
    if (_phase != PartyPhase.handoff) return;

    _haptics.notify();
    _bankPlay(WordPlay.passed(playerId: currentPlayer.id, secondsTaken: 0));
    _advanceAfterTurn();
  }

  /// Stops the clock mid-turn and puts a pause screen over the board.
  void pauseTurn() {
    if (_phase != PartyPhase.playing && _phase != PartyPhase.countdown) return;

    _stopCountdown();
    _clock.pause();
    _setPhase(PartyPhase.paused);
  }

  /// Picks the turn back up, counting the player in again so they are not
  /// dropped straight back onto a running clock.
  void resumeTurn() {
    if (_phase != PartyPhase.paused) return;
    _startCountdown();
  }

  void onRackTileTapped(LetterTile tile) {
    if (!isInteractive || _board.isPlaced(tile)) return;
    if (!_board.place(tile)) return;

    _haptics.tileTap();
    _revalidate();
  }

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

    _haptics.success();
    _endTurn(
      WordPlay(
        playerId: currentPlayer.id,
        word: _validation.word,
        breakdown: _validation.breakdown,
        secondsTaken: _clock.elapsed,
      ),
    );
  }

  /// Gives up the rest of the turn without playing a word.
  ///
  /// A duel has no pass button because the clock always runs out on its own.
  /// Here it does: five people watching someone stare at a dead rack is the
  /// fastest way to kill a party game, so they can hand the device on early.
  void passTurn() {
    if (!isInteractive) return;

    _haptics.notify();
    _endTurn(
      WordPlay.passed(playerId: currentPlayer.id, secondsTaken: _clock.elapsed),
    );
  }

  /// Moves the device on from the turn result.
  void continueFromTurn() {
    if (_phase != PartyPhase.turnResult) return;
    _advanceAfterTurn();
  }

  /// Moves to the next round, or ends the game after the last one.
  Future<void> continueFromRecap() async {
    if (_phase != PartyPhase.roundRecap) return;

    if (_match.isComplete) {
      await _finish();
      return;
    }

    final int nextIndex = _match.currentRoundIndex + 1;
    _match = _match.copyWith(
      rounds: <PartyRound>[
        ..._match.rounds,
        PartyRound(deal: _engine.dealRound(mode: mode, index: nextIndex)),
      ],
      currentRoundIndex: nextIndex,
      turnIndex: 0,
    );
    _prepareTurn();
  }

  /// Asks before abandoning a game in progress.
  Future<void> requestQuit() async {
    if (_phase == PartyPhase.finishing) return;

    _suspend();
    final DialogResponse<dynamic>? response = await _dialog.showConfirmationDialog(
      title: 'End the game?',
      description: 'Everyone loses their scores.',
      confirmationTitle: 'End game',
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
    _stopCountdown();
    _clock.dispose();
    super.dispose();
  }

  /// Deals the current player a fresh board and waits for the handoff.
  ///
  /// The clock deliberately does not start here. The rack must not be on screen
  /// while the device is changing hands, or whoever is next gets a head start
  /// reading it over the last player's shoulder.
  void _prepareTurn() {
    _board = _engine.boardForRound(_match.currentRound.deal);
    _clock.reset(mode.secondsPerRound);
    _stopCountdown();
    _setPhase(PartyPhase.handoff);
    _revalidate();
  }

  /// Counts the player in, then starts the clock.
  ///
  /// The handoff button used to start the round on the same frame it was
  /// tapped, which meant the clock was already running before the player had
  /// finished looking down at the rack.
  void _startCountdown() {
    _stopCountdown();
    _countdownRemaining = countdownSeconds;
    _setPhase(PartyPhase.countdown);

    _countdown = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (disposed) {
        timer.cancel();
        return;
      }

      _countdownRemaining--;
      if (_countdownRemaining <= 0) {
        _stopCountdown();
        _setPhase(PartyPhase.playing);
        _clock.start();
        _haptics.notify();
        return;
      }
      rebuildUi();
    });
  }

  void _stopCountdown() {
    _countdown?.cancel();
    _countdown = null;
    _countdownRemaining = 0;
  }

  /// Banks [play] and shows its author what it was worth.
  void _endTurn(WordPlay play) {
    _clock.stop();
    _bankPlay(play);
    _setPhase(PartyPhase.turnResult);
  }

  /// Records [play] against the current player without moving the device on.
  void _bankPlay(WordPlay play) {
    final List<PartyRound> rounds = List<PartyRound>.of(_match.rounds);
    rounds[_match.currentRoundIndex] = _match.currentRound.withPlay(play.playerId, play);

    _lastPlay = play;
    _lastPlayer = currentPlayer;
    _match = _match.copyWith(rounds: rounds);
  }

  /// Either recaps the round or hands the device to the next player.
  void _advanceAfterTurn() {
    if (_match.isRoundComplete) {
      _haptics.notify();
      _setPhase(PartyPhase.roundRecap);
      return;
    }

    _match = _match.copyWith(turnIndex: _match.turnIndex + 1);
    _prepareTurn();
  }

  /// Plays whatever is on the board when time runs out, or passes.
  void _timeUp() {
    if (disposed) return;
    _haptics.error();
    _endTurn(
      _validation.isValid
          ? WordPlay(
              playerId: currentPlayer.id,
              word: _validation.word,
              breakdown: _validation.breakdown,
              secondsTaken: _clock.elapsed,
            )
          : WordPlay.passed(
              playerId: currentPlayer.id,
              secondsTaken: _clock.elapsed,
            ),
    );
  }

  /// Stops the clock for something already covering the board.
  void _suspend() {
    if (_isSuspended) return;
    _isSuspended = true;
    _stopCountdown();
    _clock.pause();
  }

  /// Hands the turn back after a [_suspend].
  void _release() {
    if (!_isSuspended) return;
    _isSuspended = false;

    // A turn interrupted part way through is counted back in rather than
    // resumed on the spot, for the same reason it was counted in to start.
    if (_phase == PartyPhase.countdown) {
      _startCountdown();
      return;
    }
    if (_phase == PartyPhase.playing) _clock.resume();
  }

  Future<void> _finish() async {
    _setPhase(PartyPhase.finishing);

    // No XP, coins or gems are paid out. A party game is played by guests on
    // somebody else's phone, and quietly crediting the account holder for six
    // people's words would corrupt their record.
    await _navigation.replaceWith(
      Routes.partyResults,
      arguments: PartyResultsViewArguments(match: _match),
    );
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

  void _setPhase(PartyPhase phase) {
    _phase = phase;
    rebuildUi();
  }
}
