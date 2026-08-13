import 'package:flutter/material.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/core/models/social.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/views/friends/friends_viewmodel.dart';
import 'package:spella/ui/views/friends/widgets/friend_row.dart';
import 'package:spella/ui/views/friends/widgets/invite_card.dart';
import 'package:spella/ui/views/friends/widgets/suggested_match_card.dart';
import 'package:spella/ui/widgets/app_card.dart';
import 'package:spella/ui/widgets/app_search_field.dart';
import 'package:spella/ui/widgets/app_states.dart';
import 'package:spella/ui/widgets/page_width.dart';
import 'package:spella/ui/widgets/section_header.dart';
import 'package:stacked/stacked.dart';

/// The social hub: search, pending challenges, who is online, and who to play
/// next.
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
                child: PageHeader(
                  title: 'Friends',
                  subtitle:
                      '${viewModel.friendCount} friends · ${viewModel.onlineCount} online',
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                sliver: SliverToBoxAdapter(
                  child: AppSearchField(
                    hint: 'Search by username',
                    onChanged: viewModel.search,
                    onCleared: viewModel.clearSearch,
                  ),
                ),
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
                    // Invites are answered, not browsed, so they sit above the
                    // list and drop out entirely while a search is running.
                    if (viewModel.invites.isNotEmpty &&
                        !viewModel.isSearching) ...<Widget>[
                      SectionHeader(
                        title: 'Game Invites',
                        count: '${viewModel.invites.length} pending',
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
                    // Two different nothings, which deserve two different
                    // answers: a search that found no one is a dead end, but an
                    // empty friends list is a first run, and should say what
                    // can be done in the meantime.
                    if (!viewModel.hasResults)
                      viewModel.isSearching
                          ? AppEmptyState(
                              icon: Icons.person_search_outlined,
                              title: 'No one called "${viewModel.query}"',
                              message: 'Check the spelling. Fitting, really.',
                            )
                          : const AppEmptyState(
                              icon: Icons.person_add_alt_outlined,
                              title: 'No friends yet',
                              message:
                                  'Add people to challenge them and see who is '
                                  'online. In the meantime, Pass & Play works '
                                  'with anyone in the room.',
                            )
                    else ...<Widget>[
                      if (viewModel.onlineFriends.isNotEmpty) ...<Widget>[
                        SectionHeader(
                          title: 'Online now',
                          count: '${viewModel.onlineFriends.length}',
                          accentDot: true,
                        ),
                        _FriendList(
                          friends: viewModel.onlineFriends,
                          onChallenge: viewModel.challenge,
                        ),
                        verticalSpace(AppSpacing.xl),
                      ],
                      if (viewModel.offlineFriends.isNotEmpty) ...<Widget>[
                        SectionHeader(
                          title: 'All friends',
                          count: '${viewModel.offlineFriends.length}',
                        ),
                        _FriendList(
                          friends: viewModel.offlineFriends,
                          onChallenge: viewModel.challenge,
                        ),
                      ],
                    ],
                    // The suggestion shelf is a browsing aid, so it drops away
                    // while the player is looking for someone specific.
                    if (!viewModel.isSearching &&
                        viewModel.suggestedMatches.isNotEmpty) ...<Widget>[
                      verticalSpace(AppSpacing.section),
                      const SectionHeader(title: 'Suggested matches'),
                      verticalSpace(AppSpacing.md),
                      SizedBox(
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
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  FriendsViewModel viewModelBuilder(BuildContext context) => FriendsViewModel();
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
