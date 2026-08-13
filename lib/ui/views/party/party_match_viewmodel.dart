import 'dart:async';

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
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:uuid/uuid.dart';

/// Where a party game is in its turn cycle.
enum PartyPhase {
  /// The device is being handed over. Nothing playable is on screen.
  handoff,

  /// The clock is running for whoever is holding it.
  playing,

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
class PartyMatchViewModel extends BaseViewModel {
  PartyMatchViewModel({required this.roster});

  /// Turn order, as set on the setup screen.
  final List<PartyPlayer> roster;

  final GameEngineService _engine = locator<GameEngineService>();
  final NavigationService _navigation = locator<NavigationService>();
  final DialogService _dialog = locator<DialogService>();
  final HapticService _haptics = locator<HapticService>();

  late PartyMatch _match;
  late RoundBoard _board;

  Timer? _clock;
  PartyPhase _phase = PartyPhase.handoff;
  PlayValidation _validation = const PlayValidation.invalid(
    word: '',
    reason: PlayRejection.empty,
  );
  int _secondsRemaining = 0;
  bool _showRejection = false;

  GameMode get mode => GameMode.party;

  PartyMatch get match => _match;

  PartyPhase get phase => _phase;

  PlayValidation get validation => _validation;

  /// Whoever is holding the device.
  PartyPlayer get currentPlayer => _match.currentPlayer;

  int get turnNumber => _match.turnIndex + 1;

  int get playerCount => _match.players.length;

  int get roundNumber => _match.roundNumber;

  int get totalRounds => mode.totalRounds;

  int get secondsRemaining => _secondsRemaining;

  double get clockProgress =>
      mode.secondsPerRound == 0 ? 0 : _secondsRemaining / mode.secondsPerRound;

  bool get isTimeCritical => _secondsRemaining <= 10;

  List<LetterTile> get rack => _board.rack;

  List<LetterTile> get placedTiles => _board.placed;

  List<SlotBonus> get bonuses => _board.bonuses;

  int get slotCount => _board.slotCount;

  /// Set briefly when an invalid word is submitted, so the view can shake.
  bool get showRejection => _showRejection;

  bool get isInteractive => _phase == PartyPhase.playing;

  bool get canClear => isInteractive && !_board.isEmpty;

  String get bestPossibleWord => _match.currentRound.deal.bestPossibleWord.toUpperCase();

  bool get isFinalRound => _match.isFinalRound;

  /// The table so far, highest total first.
  List<PartyStanding> get standings => _match.standings;

  /// What the player holding the device has banked so far.
  int get currentPlayerTotal => _match.totalFor(currentPlayer.id);

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
    _match = PartyMatch(
      id: const Uuid().v4(),
      mode: mode,
      players: roster,
      rounds: <PartyRound>[PartyRound(deal: _engine.dealRound(mode: mode, index: 0))],
    );
    _prepareTurn();
  }

  /// Called from the handoff screen once the next player has the device.
  void beginTurn() {
    if (_phase != PartyPhase.handoff) return;

    _setPhase(PartyPhase.playing);
    _startClock();
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
    _recordPlay(
      WordPlay(
        playerId: currentPlayer.id,
        word: _validation.word,
        breakdown: _validation.breakdown,
        secondsTaken: mode.secondsPerRound - _secondsRemaining,
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
    _recordPlay(
      WordPlay.passed(
        playerId: currentPlayer.id,
        secondsTaken: mode.secondsPerRound - _secondsRemaining,
      ),
    );
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
        PartyRound(
          deal: _engine.dealRound(mode: mode, index: nextIndex),
        ),
      ],
      currentRoundIndex: nextIndex,
      turnIndex: 0,
    );
    _prepareTurn();
  }

  /// Asks before abandoning a game in progress.
  Future<void> requestQuit() async {
    if (_phase == PartyPhase.finishing) return;

    _stopClock();
    final DialogResponse<dynamic>? response = await _dialog.showConfirmationDialog(
      title: 'End the game?',
      description: 'Everyone loses their scores.',
      confirmationTitle: 'End game',
      cancelTitle: 'Keep playing',
    );

    if (response?.confirmed ?? false) {
      _navigation.back();
      return;
    }
    if (_phase == PartyPhase.playing) _startClock();
  }

  @override
  void dispose() {
    _stopClock();
    super.dispose();
  }

  /// Deals the current player a fresh board and waits for the handoff.
  ///
  /// The clock deliberately does not start here. The rack must not be on screen
  /// while the device is changing hands, or whoever is next gets a head start
  /// reading it over the last player's shoulder.
  void _prepareTurn() {
    _board = _engine.boardForRound(_match.currentRound.deal);
    _secondsRemaining = mode.secondsPerRound;
    _setPhase(PartyPhase.handoff);
    _revalidate();
  }

  /// Banks [play] and moves the device on.
  void _recordPlay(WordPlay play) {
    _stopClock();

    final List<PartyRound> rounds = List<PartyRound>.of(_match.rounds);
    rounds[_match.currentRoundIndex] = _match.currentRound.withPlay(play.playerId, play);
    _match = _match.copyWith(rounds: rounds);

    if (_match.isRoundComplete) {
      _haptics.notify();
      _setPhase(PartyPhase.roundRecap);
      return;
    }

    _match = _match.copyWith(turnIndex: _match.turnIndex + 1);
    _prepareTurn();
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
        _timeUp();
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
  void _timeUp() {
    _haptics.error();
    _recordPlay(
      _validation.isValid
          ? WordPlay(
              playerId: currentPlayer.id,
              word: _validation.word,
              breakdown: _validation.breakdown,
              secondsTaken: mode.secondsPerRound,
            )
          : WordPlay.passed(
              playerId: currentPlayer.id,
              secondsTaken: mode.secondsPerRound,
            ),
    );
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
      secondsRemaining: _secondsRemaining,
    );
    rebuildUi();
  }

  void _setPhase(PartyPhase phase) {
    _phase = phase;
    rebuildUi();
  }
}
