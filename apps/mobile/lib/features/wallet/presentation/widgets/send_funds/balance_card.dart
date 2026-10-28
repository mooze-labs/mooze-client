import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import '../../providers/send_funds/selected_asset_balance_provider.dart';
import 'send_flow_parts.dart';

/// The available balance of the selected asset, as one quiet line.
///
/// The asset selector shows it below the asset name. The figure uses
/// tabular digits. While the balance loads, a skeleton bar holds its place.
/// An error shows an alert icon and a message.
class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final balanceAsyncValue = ref.watch(selectedAssetBalanceProvider);
    final labelStyle = context.textTheme.bodySmall?.copyWith(
      color: context.colors.textSecondary,
    );

    final Widget value = balanceAsyncValue.when(
      data: (balanceResult) => balanceResult.fold(
        (error) => _BalanceError(
          key: const ValueKey('error'),
          message: t.wallet_send_balance_unavailable,
        ),
        (formattedBalance) => Text(
          formattedBalance,
          key: ValueKey(formattedBalance),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w600,
            fontFeatures: sendTabularFigures,
          ),
        ),
      ),
      loading: () => const SkeletonShimmer(
        key: ValueKey('loading'),
        child: SkeletonBox(width: 90, height: 12),
      ),
      error: (_, _) => _BalanceError(
        key: const ValueKey('error'),
        message: t.wallet_send_balance_load_error,
      ),
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text(t.wallet_send_available_balance, style: labelStyle),
        SizeFadeSwitcher(alignment: Alignment.centerLeft, child: value),
      ],
    );
  }
}

class _BalanceError extends StatelessWidget {
  const _BalanceError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.negativeColor;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PixIcon(PixIcons.error, size: 13, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            message,
            style: context.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
