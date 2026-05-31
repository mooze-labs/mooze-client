import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_activity_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_activity/asset_activity_card.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/transaction_list.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// Transaction history filtered to the selected asset. Reuses the existing
/// [SuccessfulTransactionList] so rows, swap rendering, privacy masking, and
/// tap-to-detail behave exactly like the home/history lists.
class AssetTransactionsSection extends ConsumerWidget {
  final Asset asset;

  const AssetTransactionsSection({super.key, required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final isVisible = ref.watch(isVisibleProvider);
    final txAsync = ref.watch(assetTransactionsProvider(asset));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AssetSectionTitle(t.asset_activity_history_title),
        const SizedBox(height: 8),
        txAsync.when(
          skipLoadingOnRefresh: true,
          skipLoadingOnReload: true,
          data:
              (transactions) =>
                  transactions.isEmpty
                      ? const EmptyTransactionList()
                      : SuccessfulTransactionList(
                        transactions: transactions,
                        isVisible: isVisible,
                      ),
          loading: () => const LoadingTransactionList(),
          error: (_, _) => const ErrorTransactionList(),
        ),
      ],
    );
  }
}
