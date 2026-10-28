import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

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
    // Hide as soon as the user types or pastes an address by other means.
    final visible =
        candidate != null &&
        !_dismissed &&
        ref.watch(addressStateProvider).isEmpty;

    return SizeFadeSwitcher(
      child: visible
          ? _SuggestionBanner(
              key: const ValueKey('suggestion'),
              title: AppLocalizations.of(context).send_clipboard_address_found,
              preview: PaymentRequestApplier.displayAddress(candidate),
              onUse: _use,
              onDismiss: () => setState(() => _dismissed = true),
            )
          : const SizedBox(key: ValueKey('none'), width: double.infinity),
    );
  }
}

/// A lens row above the address field: the clipboard value, "Use", and a
/// close button.
class _SuggestionBanner extends StatelessWidget {
  const _SuggestionBanner({
    super.key,
    required this.title,
    required this.preview,
    required this.onUse,
    required this.onDismiss,
  });

  final String title;
  final String preview;
  final VoidCallback onUse;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        container: true,
        label: '$title: $preview',
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
          decoration: BoxDecoration(
            color: GlassStyle.of(context).lensFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppSurfaces.hairline(context)),
          ),
          child: Row(
            children: [
              PixIcon(
                PixIcons.paste,
                size: 18,
                color: context.colors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.labelLarge?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onUse,
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.textPrimary,
                  textStyle: context.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(t.send_clipboard_use),
              ),
              IconButton(
                onPressed: onDismiss,
                tooltip: t.common_close,
                icon: PixIcon(
                  PixIcons.close,
                  size: 16,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
