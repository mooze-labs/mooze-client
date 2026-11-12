import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_hub_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_link_reference_field.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Adds or changes the name of [link] in a floating glass sheet.
///
/// The name only organizes the links of the owner: it stays on the device,
/// and the payer never sees it. Any link takes one, paid or not. An empty
/// name takes the name away, and the link shows as "Link de pagamento".
Future<void> editPaymentLinkReference(
  BuildContext context,
  WidgetRef ref,
  PixPaymentLink link,
) async {
  final reference = await showFloatingGlassSheet<String>(
    context,
    builder: (_) => _ReferenceSheet(initial: link.reference),
  );
  if (reference == null || !context.mounted) return;
  await ref
      .read(pixPaymentLinkReferencesProvider.notifier)
      .rename(link.id, reference);
}

class _ReferenceSheet extends StatefulWidget {
  const _ReferenceSheet({required this.initial});

  /// The name of the link now, empty when it has none.
  final String initial;

  @override
  State<_ReferenceSheet> createState() => _ReferenceSheetState();
}

class _ReferenceSheetState extends State<_ReferenceSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      // The keyboard opens for the field: the sheet rises above it.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: GlassSheet(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassSheetHeader(
              title: widget.initial.isEmpty
                  ? t.pix_hub_link_reference_add
                  : t.pix_hub_link_reference_edit,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t.pix_hub_link_reference_sheet_body,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PixLinkReferenceField(
                    controller: _controller,
                    // The sheet opens to type the name.
                    autofocus: true,
                    onSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(text: t.common_save, onPressed: _save),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
