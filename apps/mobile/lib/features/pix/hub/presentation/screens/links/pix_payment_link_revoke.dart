import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_hub_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_labels.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';

/// Asks for a confirmation, then turns the payment [link] off.
///
/// The API keeps a revoked link in the list, so every screen that shows the
/// link turns to the new status at once, and the list then reloads from the
/// API. Payments already started still finish. Returns true when the link
/// was revoked.
Future<bool> confirmAndRevokePaymentLink(
  BuildContext context,
  WidgetRef ref,
  PixPaymentLink link,
) async {
  final t = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(t.pix_hub_link_revoke_title),
      content: Text(t.pix_hub_link_revoke_body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(t.common_cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(t.pix_hub_link_revoke_confirm),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  final result = await ref
      .read(pixHubPaymentLinksProvider.notifier)
      .revoke(link.id);
  if (!context.mounted) return result.isRight();

  return result.fold(
    (failure) {
      AppSnackBar.error(context, pixHubFailureMessage(t, failure));
      return false;
    },
    (_) {
      AppSnackBar.success(context, t.pix_hub_link_revoked);
      return true;
    },
  );
}
