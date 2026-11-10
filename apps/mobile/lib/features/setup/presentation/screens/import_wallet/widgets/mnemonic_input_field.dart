import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import '../providers/seed_phrase_provider.dart';
import 'import_status_note.dart';

class MnemonicInputField extends ConsumerStatefulWidget {
  const MnemonicInputField({super.key});

  @override
  ConsumerState<MnemonicInputField> createState() => _MnemonicInputFieldState();
}

class _MnemonicInputFieldState extends ConsumerState<MnemonicInputField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _controller.text;

    final words = text.trim().split(RegExp(r'\s+'));
    if (words.length >= 12) {
      final notifier = ref.read(seedPhraseProvider.notifier);
      final success = notifier.importFullPhrase(text.trim());
      if (success) {
        _controller.clear();
        return;
      }
      return;
    }

    if (text.endsWith(' ')) {
      final trimmedText = text.trim();
      if (trimmedText.isNotEmpty) {
        final state = ref.read(seedPhraseProvider);
        if (state.suggestions.isNotEmpty) {
          ref.read(seedPhraseProvider.notifier).confirmFirstSuggestion();
          _controller.clear();
          return;
        }
      }
      _controller.text = trimmedText;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: trimmedText.length),
      );
      return;
    }

    ref.read(seedPhraseProvider.notifier).updateCurrentInput(text);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(seedPhraseProvider);

    ref.listen<SeedPhraseState>(seedPhraseProvider, (previous, next) {
      if (next.isEditing && _controller.text != next.currentInput) {
        Future.microtask(() {
          if (mounted) {
            _controller.text = next.currentInput;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
            _focusNode.requestFocus();
          }
        });
      } else if (!next.isEditing &&
          next.currentInput.isEmpty &&
          _controller.text.isNotEmpty) {
        Future.microtask(() {
          if (mounted) {
            _controller.clear();
          }
        });
      }
    });

    // A glass input, as in the other forms: the lens fill, a hairline, and
    // the brand border on focus.
    final hairline = AppSurfaces.hairline(context);
    OutlineInputBorder frame(Color color, double width) => OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: color, width: width),
    );
    final inputStyle = context.textTheme.bodyLarge?.copyWith(
      color: context.colors.textPrimary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: inputStyle,
          cursorColor: context.colorScheme.primary,
          decoration: InputDecoration(
            hintText: state.suggestions.isNotEmpty
                ? t.setup_input_hint_press_space(state.suggestions.first)
                : t.setup_input_hint_default,
            hintStyle: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textTertiary,
            ),
            filled: true,
            fillColor: GlassStyle.of(context).lensFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            border: frame(hairline, 1),
            enabledBorder: frame(hairline, 1),
            focusedBorder: frame(context.colorScheme.primary, 1.5),
            prefixIcon: Icon(
              Icons.edit_rounded,
              size: 20,
              color: context.colors.textSecondary,
            ),
            suffixIcon: state.currentInput.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: context.colors.textSecondary,
                    onPressed: () {
                      _controller.clear();
                      if (state.isEditing) {
                        ref.read(seedPhraseProvider.notifier).cancelEditing();
                      }
                    },
                  )
                : null,
          ),
          textCapitalization: TextCapitalization.none,
          keyboardType: TextInputType.text,
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-z ]')),
            LowerCaseTextFormatter(),
          ],
        ),
        if (state.error != null) ...[
          const SizedBox(height: 8),
          ImportStatusNote(
            tone: ImportStatusTone.negative,
            text: state.error!.localize(context),
          ),
        ],
      ],
    );
  }
}

class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
    );
  }
}
