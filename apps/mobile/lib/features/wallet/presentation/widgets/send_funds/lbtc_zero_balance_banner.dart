import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_asset_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import 'send_flow_parts.dart';

/// Banner shown on the Send screen when the user has zero L-BTC balance.
/// L-BTC is required to pay Liquid network fees for any asset transfer.
class LbtcZeroBalanceBanner extends ConsumerWidget {
  const LbtcZeroBalanceBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAsset = ref.watch(selectedAssetProvider);
    final relevantAssets = {Asset.depix, Asset.usdt};
    if (!relevantAssets.contains(selectedAsset)) return const SizedBox.shrink();

    final lbtcBalanceAsync = ref.watch(balanceProvider(Asset.lbtc));

    return lbtcBalanceAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (either) {
        final balance = either.fold((_) => BigInt.zero, (b) => b);
        // Original gate, restored after the 2026-05-12 repro. The line was
        // committed already commented out in `d8b2a2c9` — looked like a
        // forgotten visual-test leftover. With the gate disabled, the
        // banner rendered on every DEPIX/USDT send regardless of actual
        // L-BTC balance, so users saw a "you don't have L-BTC" prompt
        // even with 1.2M sats in the L-BTC pool.
        if (balance > BigInt.zero) {
          return const SizedBox.shrink();
        }
        try {
          AppLoggerService().info(
            'LbtcZeroBalanceBanner',
            'rendering banner asset=${selectedAsset.ticker} '
                'lbtcBalanceSats=$balance',
          );
        } catch (_) {}
        return _LbtcZeroBalanceBannerContent();
      },
    );
  }
}

/// The banner: a wallet icon, the reason, and a link to SWAP.
///
/// The whole banner opens SWAP. The warning tint, the icon, and the text
/// carry the state together.
class _LbtcZeroBalanceBannerContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final linkColor = context.colors.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        button: true,
        child: SendNotice(
          icon: PixIcons.deposit,
          tone: PixTone.warning,
          title: t.wallet_send_lbtc_banner_title,
          message: t.wallet_send_lbtc_banner_body,
          onTap: () => context.go('/swap'),
          body: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    t.wallet_send_lbtc_banner_action,
                    style: context.textTheme.labelLarge?.copyWith(
                      color: linkColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                PixIcon(PixIcons.chevronRight, size: 16, color: linkColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
