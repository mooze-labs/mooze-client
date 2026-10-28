import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

final receiveDescriptionProvider = StateProvider<String>((ref) => '');

/// The optional description of the receive request.
///
/// At rest it is a quiet "Add description" action. A tap opens a simple
/// underline field and focuses it. The field closes again when it loses
/// the focus while empty.
class DescriptionFieldReceive extends ConsumerStatefulWidget {
  const DescriptionFieldReceive({super.key});

  @override
  ConsumerState<DescriptionFieldReceive> createState() =>
      _DescriptionFieldReceiveState();
}

class _DescriptionFieldReceiveState
    extends ConsumerState<DescriptionFieldReceive> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _userExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!mounted) return;
    if (!_focusNode.hasFocus && _controller.text.isEmpty && _userExpanded) {
      setState(() => _userExpanded = false);
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _expandAndFocus() {
    setState(() => _userExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final description = ref.watch(receiveDescriptionProvider);

    if (description.isEmpty && _controller.text.isNotEmpty) {
      _controller.clear();
    }

    final shouldExpand =
        description.isNotEmpty || _userExpanded || _focusNode.hasFocus;

    return SizeFadeSwitcher(
      alignment: AlignmentDirectional.topStart,
      child: shouldExpand
          ? _ExpandedField(
              key: const ValueKey('expanded'),
              controller: _controller,
              focusNode: _focusNode,
              onChanged: (value) {
                ref.read(receiveDescriptionProvider.notifier).state = value;
              },
            )
          : _CollapsedAction(
              key: const ValueKey('collapsed'),
              onTap: _expandAndFocus,
            ),
    );
  }
}

/// A quiet text action. The brand pink stays on the main action.
class _CollapsedAction extends StatelessWidget {
  final VoidCallback onTap;
  const _CollapsedAction({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final color = context.colors.textPrimary;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(48, 48),
          // The icon lines up with the page content on the left.
          padding: const EdgeInsetsDirectional.only(start: 2, end: 12),
          textStyle: context.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: PixIcon(PixIcons.add, size: 18, color: color),
        label: Text(t.receive_description_add),
      ),
    );
  }
}

class _ExpandedField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _ExpandedField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.receive_description_label,
          style: context.textTheme.labelLarge?.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          maxLines: 2,
          maxLength: 100,
          cursorColor: context.colors.primaryColor,
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colors.textPrimary,
          ),
          decoration: receiveUnderlineDecoration(
            context,
            hintText: t.receive_description_hint,
          ),
        ),
      ],
    );
  }
}

/// Bare underline decoration for the text fields of the receive step.
///
/// The app theme fills its fields with a box. These fields sit on the
/// page: the text, then one line. The line turns brand pink and thicker
/// with the focus.
InputDecoration receiveUnderlineDecoration(
  BuildContext context, {
  required String hintText,
}) {
  UnderlineInputBorder line(Color color, double width) => UnderlineInputBorder(
    borderSide: BorderSide(color: color, width: width),
  );
  final outline = context.colorScheme.outline;
  return InputDecoration(
    hintText: hintText,
    hintStyle: context.textTheme.bodyLarge?.copyWith(
      color: context.colors.textTertiary,
    ),
    filled: false,
    isDense: true,
    contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 10),
    border: line(outline, 1),
    enabledBorder: line(outline, 1),
    disabledBorder: line(outline, 1),
    focusedBorder: line(context.colors.primaryColor, 2),
    counterStyle: context.textTheme.labelSmall?.copyWith(
      color: context.colors.textTertiary,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  );
}
