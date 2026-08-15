import 'package:flutter/material.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/core/models/social.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/views/friends/friends_viewmodel.dart';
import 'package:spella/ui/views/friends/widgets/friend_row.dart';
import 'package:spella/ui/views/friends/widgets/friends_starter.dart';
import 'package:spella/ui/views/friends/widgets/invite_card.dart';
import 'package:spella/ui/views/friends/widgets/suggested_match_card.dart';
import 'package:spella/ui/widgets/app_card.dart';
import 'package:spella/ui/widgets/app_search_field.dart';
import 'package:spella/ui/widgets/app_states.dart';
import 'package:spella/ui/widgets/page_width.dart';
import 'package:spella/ui/widgets/section_header.dart';
import 'package:stacked/stacked.dart';

/// The social hub.
///
/// Ordered by one question, asked top to bottom: can I get a game out of this
/// person right now? Challenges waiting on an answer come first because they
/// expire. Then friends who are online. Then people the matchmaker suggests -
/// strangers, but awake ones. Friends who are offline come last, because
/// however well you know them, nothing happens this minute.
///
/// That last move is the one worth naming: suggestions used to sit at the very
/// bottom, below a friends list of any length, which put the screen's only
/// answer to "there is nobody to play" underneath everybody who could not play.
class FriendsView extends StackedView<FriendsViewModel> {
  const FriendsView({super.key});

  @override
  Widget builder(BuildContext context, FriendsViewModel viewModel, Widget? child) {
    return Scaffold(
      backgroundColor: context.palette.canvas,
      body: SafeArea(
        bottom: false,
        child: PageWidth(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: PageHeader(title: 'Friends', subtitle: viewModel.headerSubtitle),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.navClearance,
                ),
                sliver: SliverList.list(
                  children: <Widget>[
                    // Invites are answered, not browsed, so they sit at the top
                    // and drop out entirely while a search is running.
                    if (viewModel.invites.isNotEmpty &&
                        !viewModel.isSearching) ...<Widget>[
                      SectionHeader(
                        title: 'Challenges',
                        count: '${viewModel.invites.length} waiting',
                        accentDot: true,
                      ),
                      verticalSpace(AppSpacing.md),
                      for (final GameInvite invite in viewModel.invites)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: InviteCard(
                            invite: invite,
                            onAccept: () => viewModel.acceptInvite(invite),
                            onDecline: () => viewModel.declineInvite(invite),
                          ),
                        ),
                      verticalSpace(AppSpacing.xl),
                    ],
                    // The field appears once the list is long enough to be worth
                    // filtering. Below that it would be a permanently empty
                    // input above a list you can already see all of.
                    if (viewModel.showSearch) ...<Widget>[
                      AppSearchField(
                        hint: 'Search friends',
                        onChanged: viewModel.search,
                        onCleared: viewModel.clearSearch,
                      ),
                      verticalSpace(AppSpacing.xl),
                    ],
                    if (viewModel.isSearching)
                      _SearchResults(viewModel: viewModel)
                    else
                      ..._browse(viewModel),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The screen as it reads when nobody is searching.
  List<Widget> _browse(FriendsViewModel viewModel) => <Widget>[
    if (viewModel.onlineFriends.isNotEmpty) ...<Widget>[
      SectionHeader(
        title: 'Online now',
        count: '${viewModel.onlineFriends.length}',
        accentDot: true,
      ),
      _FriendList(friends: viewModel.onlineFriends, onChallenge: viewModel.challenge),
      verticalSpace(AppSpacing.section),
    ],
    if (viewModel.suggestedMatches.isNotEmpty) ...<Widget>[
      const SectionHeader(title: 'People to play'),
      verticalSpace(AppSpacing.md),
      _SuggestionShelf(viewModel: viewModel),
      verticalSpace(AppSpacing.section),
    ],
    if (viewModel.offlineFriends.isNotEmpty) ...<Widget>[
      // Named for what it is. It used to be labelled "All friends", which is
      // what a reader would expect to contain everybody - including the people
      // listed under Online now, directly above it.
      SectionHeader(title: 'Offline', count: '${viewModel.offlineFriends.length}'),
      _FriendList(friends: viewModel.offlineFriends, onChallenge: viewModel.challenge),
    ],
    if (!viewModel.hasFriends)
      FriendsStarter(
        onPassAndPlay: viewModel.startPassAndPlay,
        onPlayBot: viewModel.playBot,
      ),
  ];

  @override
  FriendsViewModel viewModelBuilder(BuildContext context) => FriendsViewModel();
}

/// One flat list of matches, or an honest dead end.
class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.viewModel});

  final FriendsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final List<Player> results = viewModel.searchResults;

    if (results.isEmpty) {
      return AppEmptyState(
        icon: Icons.person_search_outlined,
        title: 'No one called "${viewModel.query}"',
        message: 'Check the spelling. Fitting, really.',
      );
    }

    return _FriendList(friends: results, onChallenge: viewModel.challenge);
  }
}

/// The suggestion shelf.
///
/// Boxed where the friend list is not, which is the point: these are picks
/// being offered rather than a list being browsed, and the card is what says so
/// without needing a label to explain it.
class _SuggestionShelf extends StatelessWidget {
  const _SuggestionShelf({required this.viewModel});

  final FriendsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: scaledSize(context, 178),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: viewModel.suggestedMatches.length,
        separatorBuilder: (BuildContext context, int index) =>
            horizontalSpace(AppSpacing.md),
        itemBuilder: (BuildContext context, int index) {
          final Player candidate = viewModel.suggestedMatches[index];
          return SuggestedMatchCard(
            player: candidate,
            onChallenge: () => viewModel.challenge(candidate),
          );
        },
      ),
    );
  }
}

/// A run of friends, ruled rather than boxed.
///
/// The rules are indented past the avatars, so the column of faces reads as one
/// continuous list instead of a stack of separate rows.
class _FriendList extends StatelessWidget {
  const _FriendList({required this.friends, required this.onChallenge});

  final List<Player> friends;
  final ValueChanged<Player> onChallenge;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < friends.length; i++) ...<Widget>[
          FriendRow(friend: friends[i], onChallenge: () => onChallenge(friends[i])),
          if (i != friends.length - 1) const AppDivider(indent: 52),
        ],
      ],
    );
  }
}
