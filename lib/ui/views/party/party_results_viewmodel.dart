import 'package:spella/app/app.locator.dart';
import 'package:spella/app/app.router.dart';
import 'package:spella/core/models/party.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

/// The end of a pass-and-play game: who won, and whether to run it back.
class PartyResultsViewModel extends BaseViewModel {
  PartyResultsViewModel({required this.match});

  final PartyMatch match;

  final NavigationService _navigation = locator<NavigationService>();

  List<PartyStanding> get standings => match.standings;

  List<PartyStanding> get winners => match.winners;

  bool get isDraw => winners.length > 1;

  /// The headline. A shared first place is called a draw rather than being
  /// broken by a tiebreak nobody agreed to in advance.
  String get headline {
    if (isDraw) return 'Draw';
    return '${winners.first.player.name} wins';
  }

  String get subheadline {
    if (isDraw) {
      final String names = winners
          .map((PartyStanding standing) => standing.player.name)
          .join(' and ');
      return '$names finished level on ${winners.first.points}';
    }

    final List<PartyStanding> table = standings;
    if (table.length < 2) return '${winners.first.points} points';

    final int margin = table.first.points - table[1].points;
    return margin == 0
        ? '${winners.first.points} points'
        : '${winners.first.points} points, by a margin of $margin';
  }

  /// The best word anyone played all game, for the closing note.
  PartyStanding? get bestWordHolder {
    PartyStanding? holder;
    for (final PartyStanding standing in standings) {
      final int score = standing.bestPlay?.score ?? 0;
      if (score <= 0) continue;
      if (holder == null || score > (holder.bestPlay?.score ?? 0)) holder = standing;
    }
    return holder;
  }

  /// Plays again with the same table, replacing this screen so a long evening
  /// does not build up a stack of finished games behind it.
  Future<void> rematch() async {
    await _navigation.replaceWith(
      Routes.partyMatch,
      arguments: PartyMatchViewArguments(players: match.players),
    );
  }

  Future<void> goHome() async {
    await _navigation.clearStackAndShow(Routes.root);
  }
}
