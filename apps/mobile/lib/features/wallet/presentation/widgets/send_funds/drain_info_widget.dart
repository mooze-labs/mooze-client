import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import '../../providers/send_funds/drain_provider.dart';
import '../../providers/send_funds/selected_asset_provider.dart';
import 'send_flow_parts.dart';

/// Note shown when the user sends the whole balance of the asset.
class DrainInfoWidget extends ConsumerWidget {
  const DrainInfoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final isDrainTransaction = ref.watch(isDrainTransactionProvider);
    final selectedAsset = ref.watch(selectedAssetProvider);

    return SizeFadeSwitcher(
      child: !isDrainTransaction
          ? const SizedBox(key: ValueKey('none'), width: double.infinity)
          : Padding(
              key: const ValueKey('drain'),
              padding: const EdgeInsets.only(top: 16),
              child: SendNotice(
                icon: PixIcons.success,
                tone: PixTone.positive,
                title: t.wallet_send_drain_title,
                message: t.wallet_send_drain_body(selectedAsset.name),
                body: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    t.wallet_send_drain_ready,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
