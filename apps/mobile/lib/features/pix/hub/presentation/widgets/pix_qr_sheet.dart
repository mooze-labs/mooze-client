import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_qr_panel.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Shows [data] as a QR Code in a floating glass sheet, for a payer in
/// person: a payment link, or the copy-and-paste code of a Pix deposit.
///
/// The header names the QR Code, with [subtitle] below it, such as the
/// amount. [caption] says how to use the code.
Future<void> showPixQrSheet(
  BuildContext context, {
  required String data,
  required String subtitle,
  required String caption,
}) {
  final t = AppLocalizations.of(context);
  return showFloatingGlassSheet<void>(
    context,
    builder: (context) => GlassSheet(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassSheetHeader(title: t.pix_hub_method_qr, subtitle: subtitle),
          const SizedBox(height: 16),
          PixQrPanel(data: data, semanticLabel: t.pix_hub_method_qr),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              caption,
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
