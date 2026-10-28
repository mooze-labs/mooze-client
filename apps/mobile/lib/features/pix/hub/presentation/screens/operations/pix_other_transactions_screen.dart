import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_action_tile.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_demo_badge.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_section_header.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_surface_card.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

/// The remaining Pix areas of the application, gathered in one list.
///
/// The deposit history and the fee table come from the existing screens; the
/// other entries open the hub flows.
class PixOtherTransactionsScreen extends StatelessWidget {
  const PixOtherTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return PixScreenScaffold(
      title: t.pix_hub_action_other_transactions,
      children: [
        PixSectionHeader(title: t.pix_hub_other_section_history),
        const SizedBox(height: 4),
        PixSurfaceCard(
          child: Column(
            children: [
              PixActionTile(
                icon: PixIcons.deposit,
                title: t.pix_hub_other_deposit_history,
                subtitle: t.pix_hub_other_deposit_history_subtitle,
                onTap: () => context.push('/swaps-history'),
              ),
              PixActionTile(
                icon: PixIcons.history,
                title: t.pix_hub_action_history,
                subtitle: t.pix_hub_action_history_subtitle,
                trailing: const PixDemoBadge(),
                onTap: () => context.push('/pix/history'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PixSectionHeader(title: t.pix_hub_other_section_tools),
        const SizedBox(height: 4),
        PixSurfaceCard(
          child: Column(
            children: [
              PixActionTile(
                icon: PixIcons.link,
                title: t.pix_hub_action_links,
                subtitle: t.pix_hub_action_links_subtitle,
                trailing: const PixDemoBadge(),
                onTap: () => context.push('/pix/links'),
              ),
              PixActionTile(
                icon: PixIcons.receipt,
                title: t.pix_hub_menu_fees,
                subtitle: t.pix_hub_other_fees_subtitle,
                onTap: () => context.push('/pix/fees'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
