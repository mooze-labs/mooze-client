import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

final receiveDescriptionProvider = StateProvider<String>((ref) => '');

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
    if (!_focusNode.hasFocus &&
        _controller.text.isEmpty &&
        _userExpanded) {
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

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: child,
        ),
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
      ),
    );
  }
}

class _CollapsedAction extends StatelessWidget {
  final VoidCallback onTap;
  const _CollapsedAction({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final accent = theme.colorScheme.primary;

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 18, color: accent),
                const SizedBox(width: 6),
                Text(
                  t.receive_description_add,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
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
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.receive_description_label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          maxLines: 2,
          maxLength: 100,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: t.receive_description_hint,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: context.colors.textTertiary,
            ),
            border: _border(context),
            enabledBorder: _border(context),
            focusedBorder: _border(context, focused: true),
            disabledBorder: _border(context),
            filled: true,
            fillColor: _fillColor(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            counterStyle: theme.textTheme.labelSmall?.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}


Color _fillColor(BuildContext context) =>
    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05);

OutlineInputBorder _border(BuildContext context, {bool focused = false}) {
  final cs = Theme.of(context).colorScheme;
  final color = focused
      ? cs.primary
      : cs.onSurface.withValues(alpha: 0.08);
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color, width: focused ? 1.5 : 1),
  );
}
