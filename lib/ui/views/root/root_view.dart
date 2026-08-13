import 'package:flutter/material.dart';
import 'package:spella/core/services/app_tab_service.dart';
import 'package:spella/ui/views/friends/friends_view.dart';
import 'package:spella/ui/views/home/home_view.dart';
import 'package:spella/ui/views/ranks/ranks_view.dart';
import 'package:spella/ui/views/root/root_viewmodel.dart';
import 'package:spella/ui/views/shop/shop_view.dart';
import 'package:spella/ui/widgets/app_bottom_nav.dart';
import 'package:stacked/stacked.dart';

/// The bottom navigation shell that hosts the four main tabs.
class RootView extends StackedView<RootViewModel> {
  const RootView({super.key});

  static const List<Widget> _tabViews = <Widget>[
    HomeView(),
    FriendsView(),
    RanksView(),
    ShopView(),
  ];

  static const Map<AppTab, NavDestination> _destinations = <AppTab, NavDestination>{
    AppTab.home: NavDestination(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Home',
    ),
    AppTab.friends: NavDestination(
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
      label: 'Friends',
    ),
    AppTab.ranks: NavDestination(
      icon: Icons.leaderboard_outlined,
      activeIcon: Icons.leaderboard_rounded,
      label: 'Ranks',
    ),
    AppTab.shop: NavDestination(
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront_rounded,
      label: 'Shop',
    ),
  };

  @override
  Widget builder(BuildContext context, RootViewModel viewModel, Widget? child) {
    return Scaffold(
      extendBody: true,
      // An IndexedStack rather than a switcher: tabs keep their scroll position
      // and their view models, so coming back to Home lands exactly where you
      // left it. Switching is instant by design - a transition here would put
      // a delay on the most frequent interaction in the app.
      body: IndexedStack(index: viewModel.currentIndex, children: _tabViews),
      bottomNavigationBar: AppBottomNav(
        destinations: _destinations.values.toList(growable: false),
        currentIndex: viewModel.currentIndex,
        onSelected: viewModel.setIndex,
      ),
    );
  }

  @override
  RootViewModel viewModelBuilder(BuildContext context) => RootViewModel();
}
