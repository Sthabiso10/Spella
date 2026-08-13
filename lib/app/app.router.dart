import 'package:flutter/material.dart';
import 'package:spella/core/models/game_mode.dart';
import 'package:spella/core/models/match_result.dart';
import 'package:spella/core/models/party.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/views/match/match_view.dart';
import 'package:spella/ui/views/party/party_match_view.dart';
import 'package:spella/ui/views/party/party_results_view.dart';
import 'package:spella/ui/views/party/party_setup_view.dart';
import 'package:spella/ui/views/results/results_view.dart';
import 'package:spella/ui/views/root/root_view.dart';
import 'package:spella/ui/views/startup/startup_view.dart';

/// Named routes for the app.
///
/// Hand written rather than generated so the route table, its arguments and
/// its transitions all live together and stay readable.
class Routes {
  const Routes._();

  static const String startup = '/';
  static const String root = '/root';
  static const String match = '/match';
  static const String results = '/results';
  static const String partySetup = '/party';
  static const String partyMatch = '/party/match';
  static const String partyResults = '/party/results';
}

/// Arguments for [Routes.match].
class MatchViewArguments {
  const MatchViewArguments({required this.mode, required this.opponent});

  final GameMode mode;
  final Player opponent;
}

/// Arguments for [Routes.results].
class ResultsViewArguments {
  const ResultsViewArguments({required this.result});

  final MatchResult result;
}

/// Arguments for [Routes.partyMatch].
class PartyMatchViewArguments {
  const PartyMatchViewArguments({required this.players});

  final List<PartyPlayer> players;
}

/// Arguments for [Routes.partyResults].
class PartyResultsViewArguments {
  const PartyResultsViewArguments({required this.match});

  final PartyMatch match;
}

/// Builds a route for [settings]. Wired into `MaterialApp.onGenerateRoute`.
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  return switch (settings.name) {
    Routes.startup => _fade(const StartupView(), settings),
    Routes.root => _fade(const RootView(), settings),
    Routes.match => _riseUp(
      MatchView(arguments: settings.arguments! as MatchViewArguments),
      settings,
    ),
    Routes.results => _riseUp(
      ResultsView(arguments: settings.arguments! as ResultsViewArguments),
      settings,
    ),
    Routes.partySetup => _riseUp(const PartySetupView(), settings),
    Routes.partyMatch => _riseUp(
      PartyMatchView(arguments: settings.arguments! as PartyMatchViewArguments),
      settings,
    ),
    Routes.partyResults => _riseUp(
      PartyResultsView(arguments: settings.arguments! as PartyResultsViewArguments),
      settings,
    ),
    _ => _fade(const _UnknownRouteView(), settings),
  };
}

/// Cross fade, used for shell level navigation.
PageRoute<T> _fade<T>(Widget view, RouteSettings settings) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: AppMotion.normal,
    pageBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondary,
        ) => view,
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondary,
          Widget child,
        ) => FadeTransition(opacity: animation, child: child),
  );
}

/// Slide up with a fade, used when entering a game or its results.
///
/// Longer than a shell transition on purpose: crossing into a match is the one
/// navigation in the app that should feel like walking into a room.
PageRoute<T> _riseUp<T>(Widget view, RouteSettings settings) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: AppMotion.entrance,
    pageBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondary,
        ) => view,
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondary,
          Widget child,
        ) {
          final Animation<double> eased = CurvedAnimation(
            parent: animation,
            curve: AppMotion.enter,
          );
          return FadeTransition(
            opacity: eased,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(eased),
              child: child,
            ),
          );
        },
  );
}

/// Shown when a route name has no match. Should never appear in practice.
class _UnknownRouteView extends StatelessWidget {
  const _UnknownRouteView();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('That screen does not exist')));
}
