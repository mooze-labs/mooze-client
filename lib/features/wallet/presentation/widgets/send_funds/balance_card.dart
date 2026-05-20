import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:shimmer/shimmer.dart';

import '../../providers/send_funds/selected_asset_balance_provider.dart';
import '../../providers/send_funds/selected_asset_provider.dart';

class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final selectedAsset = ref.watch(selectedAssetProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.onSurface.withValues(alpha: 0.06),
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              selectedAsset.iconPath,
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.wallet_send_available_balance,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selectedAsset.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const _BalanceValue(),
        ],
      ),
    );
  }
}

class _BalanceValue extends ConsumerWidget {
  const _BalanceValue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final balanceAsyncValue = ref.watch(selectedAssetBalanceProvider);

    return balanceAsyncValue.when(
      data: (balanceResult) => balanceResult.fold(
        (error) => Text(
          t.wallet_send_balance_unavailable,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        (formattedBalance) => Text(
          formattedBalance,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          textAlign: TextAlign.right,
        ),
      ),
      loading: () => Shimmer.fromColors(
        baseColor: context.colors.baseColor,
        highlightColor: context.colors.highlightColor,
        child: Container(
          width: 90,
          height: 18,
          decoration: BoxDecoration(
            color: context.colors.baseColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      error: (_, _) => Text(
        t.wallet_send_balance_load_error,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
