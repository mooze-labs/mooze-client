import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/features/sync/domain/sync_strategy.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_activity/asset_activity_header.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_activity/asset_activity_highlights_section.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_activity/asset_activity_summary_section.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_activity/asset_activity_transactions_section.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// V1 asset details: a custody/activity view of a single asset built entirely
/// from data already available locally (transactions, balances, prices). No
/// investment framing — no ROI, P/L, cost basis, or performance.
///
/// Designed for future extension: a balance-evolution chart, historical
/// snapshots, or average acquisition price can be inserted as additional
/// sections without reshaping the existing ones.
class AssetActivityScreen extends ConsumerWidget {
  final Asset asset;

  const AssetActivityScreen({super.key, required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text(asset.name)),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
          child: Column(
            children: [
              AssetActivityHeader(asset: asset),
              const SizedBox(height: 20),
              AssetSummarySection(asset: asset),
              const SizedBox(height: 20),
              AssetHighlightsSection(asset: asset),
              const SizedBox(height: 20),
              AssetTransactionsSection(asset: asset),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    try {
      final useCase = await ref.read(refreshWalletProvider.future);
      await useCase(strategy: SyncStrategy.full);
    } catch (_) {
      // Best-effort: providers stay reactive, a failed refresh just keeps
      // the last-known data on screen.
    }
  }
}
