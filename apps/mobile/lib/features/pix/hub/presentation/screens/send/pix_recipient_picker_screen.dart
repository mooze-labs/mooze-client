import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_hub_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_empty_state.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_recipient_tile.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_surface_card.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

/// Full list of the recipients paid recently.
///
/// NOTE: No route opens this screen. Its recipients come from the
/// demonstration dataset, and the send flow now moves real funds, so a tap
/// starts nothing. Remove the screen, or feed it real recipients first.
class PixRecipientPickerScreen extends ConsumerWidget {
  const PixRecipientPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final recipients = ref.watch(pixHubRecipientsProvider);

    return PixScreenScaffold(
      appBarTitle: t.pix_hub_send_title,
      title: t.pix_hub_recent_recipients,
      onRefresh: () async => ref.invalidate(pixHubRecipientsProvider),
      children: [
        recipients.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(28),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => PixEmptyState(
            icon: PixIcons.offline,
            title: t.pix_hub_error_title,
            message: t.pix_hub_error_body,
            actionLabel: t.common_retry,
            onAction: () => ref.invalidate(pixHubRecipientsProvider),
          ),
          data: (list) => list.isEmpty
              ? PixEmptyState(
                  icon: PixIcons.people,
                  title: t.pix_hub_empty_recipients_title,
                  message: t.pix_hub_empty_recipients_body,
                )
              : PixSurfaceCard(
                  child: Column(
                    children: [
                      for (final recipient in list)
                        PixRecipientTile(recipient: recipient),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
