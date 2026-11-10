import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/shared/widgets/clipboard_suggestion_banner.dart';

import '../providers/seed_phrase_provider.dart';

class ClipboardPasteDetector extends ConsumerStatefulWidget {
  const ClipboardPasteDetector({super.key});

  @override
  ConsumerState<ClipboardPasteDetector> createState() =>
      _ClipboardPasteDetectorState();
}

class _ClipboardPasteDetectorState
    extends ConsumerState<ClipboardPasteDetector> {
  String? _clipboardContent;
  bool _isChecking = false;
  bool _showBanner = true;

  @override
  void initState() {
    super.initState();
    _checkClipboard();
  }

  Future<void> _checkClipboard() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text?.trim();

      if (text != null && text.isNotEmpty) {
        final words = text.split(RegExp(r'\s+'));
        if (words.length == 12 ||
            words.length == 15 ||
            words.length == 18 ||
            words.length == 21 ||
            words.length == 24) {
          setState(() {
            _clipboardContent = text;
          });
        }
      }
    } finally {
      _isChecking = false;
    }
  }

  void _pasteFromClipboard() {
    if (_clipboardContent == null) return;

    final notifier = ref.read(seedPhraseProvider.notifier);
    final success = notifier.importFullPhrase(_clipboardContent!);

    if (success) {
      setState(() {
        _showBanner = false;
      });
    } else {
      if (mounted) {
        final state = ref.read(seedPhraseProvider);
        if (state.error != null) {
          AppSnackBar.error(context, state.error!.localize(context));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(seedPhraseProvider);

    if (!_showBanner ||
        _clipboardContent == null ||
        state.confirmedWords.isNotEmpty) {
      return const SizedBox.shrink();
    }

    // The banner names the phrase and never shows it: it is the secret of
    // the wallet.
    return ClipboardSuggestionBanner(
      title: t.setup_clipboard_detected_title,
      preview: t.setup_clipboard_detected_body,
      showsValue: false,
      actionLabel: t.setup_clipboard_paste_button,
      dismissTooltip: t.setup_clipboard_ignore_button,
      onUse: _pasteFromClipboard,
      onDismiss: () => setState(() => _showBanner = false),
    );
  }
}
