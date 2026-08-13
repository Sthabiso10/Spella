import 'package:spella/app/app.locator.dart';
import 'package:spella/app/app.router.dart';
import 'package:spella/core/models/game_match.dart';
import 'package:spella/core/models/match_result.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/core/models/word_play.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

/// The post-match screen: who won, what it paid, and where to go next.
class ResultsViewModel extends BaseViewModel {
  ResultsViewModel({required this.result});

  final MatchResult result;

  final NavigationService _navigation = locator<NavigationService>();

  GameMatch get match => result.match;

  Player get me => match.host;

  Player get opponent => match.guest;

  MatchOutcome get outcome => result.outcome;

  bool get didWin => result.didWin;

  bool get didLose => outcome == MatchOutcome.lost;

  bool get isMvp => result.isMvp;

  String get headline => switch (outcome) {
    MatchOutcome.won => 'Game Over!',
    MatchOutcome.lost => 'Good Game',
    MatchOutcome.draw => 'Dead Even',
  };

  String get subheadline => result.headline;

  WordPlay? get myBestPlay => match.hostBestPlay;

  WordPlay? get opponentBestPlay => match.guestBestPlay;

  /// Plays the same opponent again in the same mode, replacing this screen so
  /// the results do not pile up on the back stack.
  Future<void> rematch() =>
      _navigation.replaceWith(
        Routes.match,
        arguments: MatchViewArguments(mode: match.mode, opponent: opponent),
      ) ??
      Future<void>.value();

  /// Returns to the shell, clearing the match out of the stack.
  Future<void> goHome() =>
      _navigation.clearStackAndShow(Routes.root) ?? Future<void>.value();
}
