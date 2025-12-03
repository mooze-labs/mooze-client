import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/seed_phrase_provider.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText:
                state.suggestions.isNotEmpty
                    ? 'Pressione espaço para confirmar "${state.suggestions.first}"'
                    : 'Digite uma palavra BIP39...',
            hintStyle: TextStyle(
              fontSize: 14,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            prefixIcon: Icon(
              Icons.edit,
              color: Theme.of(context).colorScheme.primary,
            ),
            suffixIcon:
                state.currentInput.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.clear),
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
        if (state.errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
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
