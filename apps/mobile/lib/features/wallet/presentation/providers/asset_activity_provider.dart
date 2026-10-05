import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/asset_activity_summary.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/services/asset_activity_calculator.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/v2_legacy_transactions_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// The transaction history filtered to a single [Asset], newest-first
/// (inherits the upstream ordering of `v2LegacyTransactionsProvider`).
///
/// Reuses the already-unified legacy transaction stream — no new data source.
final assetTransactionsProvider =
    Provider.family<AsyncValue<List<Transaction>>, Asset>((ref, asset) {
      final txAsync = ref.watch(v2LegacyTransactionsProvider);
      return txAsync.whenData(
        (txs) => AssetActivityCalculator.filterForAsset(asset, txs),
      );
    });

/// Derived, non-investment activity summary for a single [Asset], recomputed
/// whenever the transaction stream emits.
final assetActivityProvider =
    Provider.family<AsyncValue<AssetActivitySummary>, Asset>((ref, asset) {
      final txAsync = ref.watch(v2LegacyTransactionsProvider);
      return txAsync.whenData(
        (txs) =>
            AssetActivityCalculator.summarize(asset: asset, transactions: txs),
      );
    });
