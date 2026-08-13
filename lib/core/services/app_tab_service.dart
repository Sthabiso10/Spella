import 'package:stacked/stacked.dart';

/// The tabs in the bottom navigation shell.
enum AppTab { home, friends, ranks, shop }

/// Holds which tab the shell is showing.
///
/// Lives in a service so any view model can move the user between tabs -
/// "See full leaderboard" on Home jumping to Ranks, for example - without
/// views reaching into each other.
class AppTabService with ListenableServiceMixin {
  AppTabService() {
    listenToReactiveValues(<ReactiveValue<AppTab>>[_currentTab]);
  }

  final ReactiveValue<AppTab> _currentTab = ReactiveValue<AppTab>(AppTab.home);

  AppTab get currentTab => _currentTab.value;

  int get currentIndex => AppTab.values.indexOf(_currentTab.value);

  void goTo(AppTab tab) => _currentTab.value = tab;

  void goToIndex(int index) {
    if (index < 0 || index >= AppTab.values.length) return;
    _currentTab.value = AppTab.values[index];
  }
}
