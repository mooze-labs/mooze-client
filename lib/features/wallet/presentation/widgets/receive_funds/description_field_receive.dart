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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final description = ref.watch(receiveDescriptionProvider);

    if (description.isEmpty && _controller.text.isNotEmpty) {
      _controller.clear();
    }

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
          controller: _controller,
          onChanged: (value) {
            ref.read(receiveDescriptionProvider.notifier).state = value;
          },
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

Color _fillColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? theme.colorScheme.surfaceContainerHighest
      : theme.colorScheme.surface;
}

OutlineInputBorder _border(BuildContext context, {bool focused = false}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final cs = theme.colorScheme;
  final color = focused
      ? cs.primary
      : isDark
          ? cs.outlineVariant.withValues(alpha: 0.45)
          : cs.outline.withValues(alpha: 0.45);
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color, width: focused ? 1.5 : 1),
  );
}
