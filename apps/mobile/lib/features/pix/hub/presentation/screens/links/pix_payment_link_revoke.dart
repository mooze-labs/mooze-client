import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_hub_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_labels.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Asks for a confirmation, then turns the payment [link] off.
///
/// The confirmation is a floating glass sheet, as the other notices: a
/// broken link in the negative tone, the question, what it means, a red
/// button that names the action, and a neutral way back. A tap outside
/// or a drag cancels.
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
  final confirmed = await showFloatingGlassSheet<bool>(
    context,
    builder: (_) => const _RevokeSheet(),
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

/// The confirmation of a revoke.
class _RevokeSheet extends StatelessWidget {
  const _RevokeSheet();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return GlassSheet(
      padding: const EdgeInsets.fromLTRB(8, 28, 8, 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The icon well and the title carry the meaning, never the red
            // alone.
            const Center(
              child: PixIconWell(
                icon: PixIcons.linkOff,
                tone: PixTone.negative,
                size: 56,
              ),
            ),
            const SizedBox(height: 18),
            Semantics(
              header: true,
              child: Text(
                t.pix_hub_link_revoke_title,
                textAlign: TextAlign.center,
                style: context.textTheme.titleLarge?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              t.pix_hub_link_revoke_body,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: t.pix_hub_link_revoke_confirm,
              color: context.colors.negativeColor,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                // The way back stays neutral: the red is for the action.
                foregroundColor: context.colors.textPrimary,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(t.common_cancel),
            ),
          ],
        ),
      ),
    );
  }
}
