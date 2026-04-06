import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_asset_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

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
        // if (balance > BigInt.zero) return const SizedBox.shrink();

        return _LbtcZeroBalanceBannerContent();
      },
    );
  }
}

class _LbtcZeroBalanceBannerContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => context.go('/swap'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.error.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: colorScheme.error,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bitcoin L2 necessário para taxas',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Para enviar DePIX ou USDT, você precisa ter Bitcoin L2 na carteira para pagar as taxas da rede.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer.withValues(
                        alpha: 0.85,
                      ),
                      height: 1.4,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Obter via SWAP',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: colorScheme.primary,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colorScheme.primary,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
