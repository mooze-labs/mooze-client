import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_empty_state.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_surface_card.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_notice_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

/// Says that payment links start at the Silver level, in place of the form
/// that creates a link.
///
/// See `pixPaymentLinkLockedProvider`. The screen gives the way forward, the
/// level screen, as its bottom action.
class PixPaymentLinkLevelNotice extends StatelessWidget {
  const PixPaymentLinkLevelNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return PixSurfaceCard(
      child: PixEmptyState(
        icon: PixIcons.lock,
        title: t.pix_hub_link_level_locked_title,
        message: t.pix_hub_link_level_locked_body,
      ),
    );
  }
}

/// Says that payment links start at the Silver level, in a floating glass
/// sheet, when the user picks a link among other options.
///
/// The user opened it with a tap, so it closes at once: by its button, a tap
/// outside, or a drag.
Future<void> showPixPaymentLinkLevelSheet(BuildContext context) {
  return showFloatingGlassSheet<void>(
    context,
    builder: (context) {
      final t = AppLocalizations.of(context);
      return PixNoticeSheet(
        icon: PixIcons.lock,
        title: t.pix_hub_link_level_locked_title,
        intro: t.pix_hub_link_level_locked_body,
        actionLabel: t.common_understood,
        onAction: () => Navigator.of(context).pop(),
        dismissible: true,
      );
    },
  );
}
