import 'package:flutter/material.dart';
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_typography.dart';
import 'package:spella/ui/common/ui_helpers.dart';

/// The app's text input.
///
/// Owns its focus and clear behaviour so screens do not each grow a controller
/// and a listener for the same job. Focus is shown by lifting the fill and
/// brightening the hairline - not by a glowing ring, which on a dark page
/// draws more attention than whatever the player is typing.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    required this.hint,
    required this.onChanged,
    this.onCleared,
    this.icon = Icons.search_rounded,
    super.key,
  });

  final String hint;
  final ValueChanged<String> onChanged;

  /// Called after the field is emptied by the clear button.
  final VoidCallback? onCleared;

  final IconData icon;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
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

  void _clear() {
    _controller.clear();
    _focusNode.unfocus();
    widget.onChanged('');
    widget.onCleared?.call();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool hasFocus = _focusNode.hasFocus;
    final bool hasText = _controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: AppMotion.quick,
      curve: AppMotion.enter,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: hasFocus ? palette.surfaceElevated : palette.surface,
        borderRadius: AppRadius.control,
        border: Border.all(color: hasFocus ? palette.borderStrong : palette.border),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            widget.icon,
            size: 17,
            color: hasFocus ? palette.textSecondary : palette.textMuted,
          ),
          horizontalSpace(AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: (String value) {
                widget.onChanged(value);
                setState(() {});
              },
              textInputAction: TextInputAction.search,
              cursorWidth: 1.5,
              cursorRadius: const Radius.circular(1),
              style: AppTextStyles.body.copyWith(color: palette.textPrimary),
              decoration: InputDecoration(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: widget.hint,
                hintStyle: AppTextStyles.body.copyWith(color: palette.textMuted),
              ),
            ),
          ),
          // The clear affordance only exists once there is something to clear,
          // so the resting field is one icon and a prompt.
          AnimatedSize(
            duration: AppMotion.quick,
            curve: AppMotion.enter,
            child: hasText
                ? GestureDetector(
                    onTap: _clear,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: Icon(
                        Icons.cancel_rounded,
                        size: 16,
                        color: palette.textMuted,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
