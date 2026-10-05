import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/infra/core/core_sync_helpers.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/clipboard_suggestion_banner.dart';

/// Heuristic detector for the PIX key formats the send flow accepts.
///
/// Mirrors the "accepted types" list shown on the input screen: e-mail,
/// phone, CPF/CNPJ and random (EVP) keys, plus a full "PIX copia e cola"
/// BR Code payload, which the field also accepts from the QR scanner.
class PixKeyDetector {
  PixKeyDetector._();

  /// True if [value] looks like a PIX key or a BR Code payload. The rules
  /// run in mooze-core.
  static bool looksLikePixKey(String value) =>
      CoreSyncHelpers.instance.pixLooksLikeKey(value);
}

/// Offers to fill the PIX key field with a key found in the clipboard.
class ClipboardPixKeySuggestion extends StatefulWidget {
  final ValueChanged<String> onUse;
  final bool enabled;

  const ClipboardPixKeySuggestion({
    super.key,
    required this.onUse,
    this.enabled = true,
  });

  @override
  State<ClipboardPixKeySuggestion> createState() =>
      _ClipboardPixKeySuggestionState();
}

class _ClipboardPixKeySuggestionState extends State<ClipboardPixKeySuggestion> {
  String? _candidate;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _checkClipboard();
  }

  Future<void> _checkClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text?.trim();
    if (text == null || !PixKeyDetector.looksLikePixKey(text)) return;
    setState(() => _candidate = text);
  }

  @override
  Widget build(BuildContext context) {
    final candidate = _candidate;
    if (candidate == null || _dismissed || !widget.enabled) {
      return const SizedBox.shrink();
    }
    return ClipboardSuggestionBanner(
      title: AppLocalizations.of(context).pix_clipboard_key_found,
      preview: candidate,
      onUse: () {
        HapticFeedback.selectionClick();
        widget.onUse(candidate);
        setState(() => _dismissed = true);
      },
      onDismiss: () => setState(() => _dismissed = true),
    );
  }
}
