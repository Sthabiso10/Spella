import 'package:spella/app/app.locator.dart';
import 'package:spella/app/app.router.dart';
import 'package:spella/core/services/dictionary_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

/// Loads everything the game needs before the first screen appears.
class StartupViewModel extends BaseViewModel {
  final DictionaryService _dictionary = locator<DictionaryService>();
  final NavigationService _navigation = locator<NavigationService>();

  /// Minimum time the splash stays up, so loading never flashes past.
  static const Duration _minimumSplash = Duration(milliseconds: 900);

  /// Word count, shown once the dictionary is ready.
  int get wordsLoaded => _dictionary.wordCount;

  /// Warms up services, then moves on to the shell.
  Future<void> runStartupLogic() async {
    final Stopwatch stopwatch = Stopwatch()..start();

    await runBusyFuture(_dictionary.initialise());

    final Duration remaining = _minimumSplash - stopwatch.elapsed;
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);

    await _navigation.replaceWith(Routes.root);
  }
}
