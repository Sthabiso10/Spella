import 'package:spella/app/app.locator.dart';
import 'package:spella/core/services/app_tab_service.dart';
import 'package:stacked/stacked.dart';

/// Drives the bottom navigation shell.
///
/// The selected tab lives in [AppTabService] rather than here, so other view
/// models can move the user between tabs without touching this one.
class RootViewModel extends ReactiveViewModel {
  final AppTabService _tabService = locator<AppTabService>();

  @override
  List<ListenableServiceMixin> get listenableServices => <ListenableServiceMixin>[
    _tabService,
  ];

  int get currentIndex => _tabService.currentIndex;

  AppTab get currentTab => _tabService.currentTab;

  void setIndex(int index) => _tabService.goToIndex(index);
}
