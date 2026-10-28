import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Asks the merchant to confirm a removal, such as a product or the cart.
///
/// The dialog is opaque glass. The removal is a filled button in the error
/// color with white text, above 4.5:1 in both themes, and the cancel button
/// has the primary text color. Returns true when the merchant confirms.
Future<bool> showMerchantConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final t = AppLocalizations.of(dialogContext);
      final colorScheme = dialogContext.colorScheme;
      return GlassAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(
              foregroundColor: dialogContext.colors.textPrimary,
              minimumSize: const Size(64, 48),
            ),
            child: Text(t.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              minimumSize: const Size(64, 48),
            ),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
