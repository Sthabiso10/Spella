import 'package:spella/app/app.locator.dart';
import 'package:spella/app/app.router.dart';
import 'package:spella/core/models/game_mode.dart';
import 'package:spella/core/models/party.dart';
import 'package:spella/core/services/player_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:uuid/uuid.dart';

/// Builds the line-up for a pass-and-play game.
///
/// Owns the roster and nothing else - the game itself is not created until the
/// player taps start, so backing out of this screen leaves no trace.
class PartySetupViewModel extends BaseViewModel {
  final PlayerService _playerService = locator<PlayerService>();
  final NavigationService _navigation = locator<NavigationService>();
  final Uuid _uuid = const Uuid();

  /// Faces handed out in order, so no two people at the table share one.
  static const List<String> avatars = <String>['🦊', '🐙', '🦉', '🐉', '🐳', '🦁'];

  final List<PartyPlayer> _players = <PartyPlayer>[];

  List<PartyPlayer> get players => List<PartyPlayer>.unmodifiable(_players);

  GameMode get mode => GameMode.party;

  bool get canAddPlayer => _players.length < PartyMatch.maxPlayers;

  bool get canStart => _players.length >= PartyMatch.minPlayers;

  /// How many more names are needed before the game can start.
  int get playersNeeded =>
      (PartyMatch.minPlayers - _players.length).clamp(0, PartyMatch.minPlayers);

  /// Seeds the table with the signed-in player, since they are holding the
  /// phone and would otherwise have to type their own name in every time.
  void initialise() {
    if (_players.isNotEmpty) return;
    _add(_playerService.currentPlayer.username);
  }

  /// Adds [name], ignoring blanks and duplicates.
  ///
  /// Duplicates are rejected because the scoreboard is read across a table -
  /// two rows both saying "Sam" is an argument waiting to happen.
  bool addPlayer(String name) {
    final String trimmed = name.trim();
    if (trimmed.isEmpty || !canAddPlayer) return false;
    if (_players.any((PartyPlayer player) => _matches(player.name, trimmed))) {
      return false;
    }

    _add(trimmed);
    rebuildUi();
    return true;
  }

  void removePlayer(PartyPlayer player) {
    _players.remove(player);
    rebuildUi();
  }

  /// `true` when [name] would be rejected, so the field can say why.
  bool isDuplicate(String name) {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    return _players.any((PartyPlayer player) => _matches(player.name, trimmed));
  }

  Future<void> start() async {
    if (!canStart) return;

    await _navigation.navigateTo(
      Routes.partyMatch,
      arguments: PartyMatchViewArguments(players: players),
    );
  }

  void back() => _navigation.back();

  void _add(String name) {
    _players.add(
      PartyPlayer(
        id: _uuid.v4(),
        name: name,
        // Wraps rather than running out, though the roster cap means it never
        // has to on a legal table.
        avatar: avatars[_players.length % avatars.length],
      ),
    );
  }

  bool _matches(String a, String b) => a.toLowerCase() == b.toLowerCase();
}
