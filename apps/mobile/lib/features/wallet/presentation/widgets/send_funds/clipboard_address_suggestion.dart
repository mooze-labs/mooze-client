import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/clipboard_suggestion_banner.dart';

import '../../providers/send_funds/address_provider.dart';
import '../../providers/send_funds/payment_request_applier.dart';
import '../../providers/send_funds/qr_validation_service.dart';

/// Offers to fill the address field with a valid payment request found in
/// the clipboard when the send screen opens.
///
/// Reads the clipboard once on mount. Shows nothing when the clipboard is
/// empty, holds something the wallet cannot pay, or the form already has an
/// address.
class ClipboardAddressSuggestion extends ConsumerStatefulWidget {
  const ClipboardAddressSuggestion({super.key});

  @override
  ConsumerState<ClipboardAddressSuggestion> createState() =>
      _ClipboardAddressSuggestionState();
}

class _ClipboardAddressSuggestionState
    extends ConsumerState<ClipboardAddressSuggestion> {
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
    if (text == null || text.isEmpty || text.length > 2048) return;
    if (!QrValidationService.validateQrData(text).isValid) return;
    if (ref.read(addressStateProvider).isNotEmpty) return;
    setState(() => _candidate = text);
  }

  void _use() {
    final text = _candidate;
    if (text == null) return;
    HapticFeedback.selectionClick();
    PaymentRequestApplier.apply(ref, text);
    setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    final candidate = _candidate;
    if (candidate == null || _dismissed) return const SizedBox.shrink();

    // Hide as soon as the user types or pastes an address by other means.
    if (ref.watch(addressStateProvider).isNotEmpty) {
      return const SizedBox.shrink();
    }

    return ClipboardSuggestionBanner(
      title: AppLocalizations.of(context).send_clipboard_address_found,
      preview: PaymentRequestApplier.displayAddress(candidate),
      onUse: _use,
      onDismiss: () => setState(() => _dismissed = true),
    );
  }
}
