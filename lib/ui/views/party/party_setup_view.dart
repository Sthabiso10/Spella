import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spella/core/models/party.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';
import 'package:spella/ui/views/party/party_setup_viewmodel.dart';
import 'package:spella/ui/widgets/app_avatar.dart';
import 'package:spella/ui/widgets/app_buttons.dart';
import 'package:spella/ui/widgets/app_card.dart';
import 'package:spella/ui/widgets/page_width.dart';
import 'package:spella/ui/widgets/section_header.dart';
import 'package:stacked/stacked.dart';

/// Who is playing.
///
/// The whole screen is one job - get names in - so it is a single column with
/// the field at the top, the table underneath, and the only other control
/// pinned to the bottom. Nothing else competes for the tap.
class PartySetupView extends StackedView<PartySetupViewModel> {
  const PartySetupView({super.key});

  @override
  Widget builder(BuildContext context, PartySetupViewModel viewModel, Widget? child) {
    final AppPalette palette = context.palette;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: PageWidth(
          child: Column(
            children: <Widget>[
              _Header(viewModel: viewModel),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  children: <Widget>[
                    _NameField(viewModel: viewModel),
                    verticalSpace(AppSpacing.xl),
                    SectionHeader(
                      title: 'Players',
                      count: '${viewModel.players.length}/${PartyMatch.maxPlayers}',
                    ),
                    verticalSpace(AppSpacing.sm),
                    for (int i = 0; i < viewModel.players.length; i++) ...<Widget>[
                      _PlayerRow(
                        player: viewModel.players[i],
                        position: i + 1,
                        // The first name in is whoever is holding the phone, and
                        // removing yourself from your own game is more likely to
                        // be a slip than an intention.
                        onRemove: viewModel.players.length > 1 && i > 0
                            ? () => viewModel.removePlayer(viewModel.players[i])
                            : null,
                      ),
                      if (i != viewModel.players.length - 1) const AppDivider(indent: 52),
                    ],
                  ],
                ),
              ),
              _StartBar(viewModel: viewModel),
            ],
          ),
        ),
      ),
    );
  }

  @override
  PartySetupViewModel viewModelBuilder(BuildContext context) => PartySetupViewModel();

  @override
  void onViewModelReady(PartySetupViewModel viewModel) => viewModel.initialise();
}

class _Header extends StatelessWidget {
  const _Header({required this.viewModel});

  final PartySetupViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppIconButton(
            icon: Icons.arrow_back_rounded,
            size: 40,
            isTransparent: true,
            onPressed: viewModel.back,
          ),
          horizontalSpace(AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                verticalSpace(AppSpacing.sm),
                Text(
                  'Pass & Play',
                  style: AppTextStyles.headingLarge.copyWith(color: palette.textPrimary),
                ),
                verticalSpace(AppSpacing.xs + 2),
                Text(
                  'Everyone plays the same rack, one after the other. '
                  '${viewModel.mode.totalRounds} rounds, '
                  '${viewModel.mode.secondsPerRound} seconds a turn.',
                  style: AppTextStyles.bodySmall.copyWith(color: palette.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The add-a-player field.
///
/// Stateful because it owns the text being typed; it hands finished names to
/// the view model and keeps nothing else.
class _NameField extends StatefulWidget {
  const _NameField({required this.viewModel});

  final PartySetupViewModel viewModel;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _submit() {
    if (!widget.viewModel.addPlayer(_controller.text)) return;

    _controller.clear();
    // Focus is kept so a table of six can be typed in without reaching for the
    // field again between names.
    _focusNode.requestFocus();
    HapticFeedback.selectionClick();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool isFull = !widget.viewModel.canAddPlayer;
    final bool isDuplicate = widget.viewModel.isDuplicate(_controller.text);
    final bool canSubmit = !isFull && !isDuplicate && _controller.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: AnimatedContainer(
                duration: AppMotion.quick,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: _focusNode.hasFocus ? palette.surfaceElevated : palette.surface,
                  borderRadius: AppRadius.control,
                  border: Border.all(
                    color: isDuplicate
                        ? palette.danger
                        : _focusNode.hasFocus
                        ? palette.borderStrong
                        : palette.border,
                  ),
                ),
                child: Center(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: !isFull,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submit(),
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 14,
                    cursorWidth: 1.5,
                    style: AppTextStyles.body.copyWith(color: palette.textPrimary),
                    decoration: InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      isDense: true,
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      hintText: isFull ? 'Table is full' : 'Add a player',
                      hintStyle: AppTextStyles.body.copyWith(color: palette.textMuted),
                    ),
                  ),
                ),
              ),
            ),
            horizontalSpace(AppSpacing.sm),
            AppIconButton(
              icon: Icons.add_rounded,
              size: 48,
              foreground: canSubmit ? palette.textInverse : palette.textMuted,
              background: canSubmit ? palette.textPrimary : null,
              onPressed: canSubmit ? _submit : null,
            ),
          ],
        ),
        if (isDuplicate) ...<Widget>[
          verticalSpace(AppSpacing.sm),
          Text(
            'Someone is already called that',
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w500,
              color: palette.danger,
            ),
          ),
        ],
      ],
    );
  }
}

/// One name on the team sheet, with its turn position.
class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.position,
    required this.onRemove,
  });

  final PartyPlayer player;
  final int position;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 20,
            child: Text(
              '$position',
              style: AppTextStyles.rank.copyWith(color: palette.textMuted),
            ),
          ),
          horizontalSpace(AppSpacing.md),
          AppAvatar(player: player.asPlayer, size: 36, ring: AvatarRing.none),
          horizontalSpace(AppSpacing.md),
          Expanded(
            child: Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyStrong.copyWith(
                fontSize: 14,
                color: palette.textPrimary,
              ),
            ),
          ),
          if (onRemove != null)
            AppIconButton(
              icon: Icons.remove_circle_outline_rounded,
              size: 36,
              isTransparent: true,
              foreground: palette.textMuted,
              tooltip: 'Remove ${player.name}',
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

/// The one action on the screen, held at the bottom where a thumb is.
class _StartBar extends StatelessWidget {
  const _StartBar({required this.viewModel});

  final PartySetupViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final int needed = viewModel.playersNeeded;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.canvas,
        border: Border(top: BorderSide(color: palette.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (needed > 0) ...<Widget>[
            Text(
              needed == 1 ? 'Add one more player' : 'Add $needed more players',
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w500,
                color: palette.textMuted,
              ),
            ),
            verticalSpace(AppSpacing.md),
          ],
          AppButton(
            label: 'Start Game',
            icon: Icons.play_arrow_rounded,
            size: AppButtonSize.large,
            onPressed: viewModel.canStart ? viewModel.start : null,
          ),
        ],
      ),
    );
  }
}
