import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/clipboard_suggestion_banner.dart';

/// Heuristic detector for the PIX key formats the send flow accepts.
///
/// Mirrors the "accepted types" list shown on the input screen: e-mail,
/// phone, CPF/CNPJ and random (EVP) keys, plus a full "PIX copia e cola"
/// BR Code payload, which the field also accepts from the QR scanner.
class PixKeyDetector {
  PixKeyDetector._();

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final _evp = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  static final _digits = RegExp(r'^\d+$');
  static final _phone = RegExp(r'^\+?55?\s?\(?\d{2}\)?\s?9?\d{4}-?\d{4}$');

  static bool looksLikePixKey(String value) {
    final v = value.trim();
    if (v.isEmpty || v.length > 1024) return false;
    if (v.startsWith('000201')) return true; // BR Code payload
    if (_email.hasMatch(v)) return true;
    if (_evp.hasMatch(v)) return true;
    if (_phone.hasMatch(v)) return true;
    final digits = v.replaceAll(RegExp(r'[.\-/\s()+]'), '');
    if (_digits.hasMatch(digits) &&
        (digits.length == 11 || digits.length == 13 || digits.length == 14)) {
      return true;
    }
    return false;
  }
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
