import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/v2_legacy_transactions_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/transaction_list.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/transaction_history/widgets/transaction_filter.dart';
import 'package:mooze_mobile/features/transaction_history/widgets/asset_filter_entity.dart';
import 'package:mooze_mobile/features/transaction_history/widgets/filter_glass_widgets.dart';
import 'package:mooze_mobile/shared/widgets/backdrop_page_scaffold.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  TransactionFiltersEntity _filters = TransactionFiltersEntity();
  List<AssetEntity> _allAssets = [];

  @override
  void initState() {
    super.initState();
    _allAssets =
        Asset.values
            .map(
              (asset) => AssetEntity(
                id: asset.id,
                name: asset.name,
                iconPath: asset.iconPath,
              ),
            )
            .toList();
  }

  List<Transaction> _applyFilters(List<Transaction> transactions) {
    List<Transaction> filtered = List.from(transactions);

    final type = _filters.filter?['type'] as String?;
    if (type != null && type != 'all') {
      filtered = filtered.where((tx) => tx.type.name == type).toList();
    }

    final status = _filters.filter?['status'] as String?;
    if (status != null && status != 'all') {
      filtered = filtered.where((tx) => tx.status.name == status).toList();
    }

    final assetIds = _filters.filter?['assets'] as List<String>?;
    if (assetIds != null && assetIds.isNotEmpty) {
      filtered =
          filtered.where((tx) => assetIds.contains(tx.asset.id)).toList();
    }

    if (_filters.startDate != null) {
      filtered =
          filtered
              .where(
                (tx) =>
                    tx.createdAt.isAfter(_filters.startDate!) ||
                    tx.createdAt.isAtSameMomentAs(_filters.startDate!),
              )
              .toList();
    }
    if (_filters.endDate != null) {
      final endOfDay = DateTime(
        _filters.endDate!.year,
        _filters.endDate!.month,
        _filters.endDate!.day,
        23,
        59,
        59,
        999,
      );
      filtered =
          filtered
              .where(
                (tx) =>
                    tx.createdAt.isBefore(endOfDay) ||
                    tx.createdAt.isAtSameMomentAs(endOfDay),
              )
              .toList();
    }

    final orderByMostRecent = _filters.orderByMostRecent ?? true;
    filtered.sort((a, b) {
      if (orderByMostRecent) {
        return b.createdAt.compareTo(a.createdAt);
      } else {
        return a.createdAt.compareTo(b.createdAt);
      }
    });

    return filtered;
  }

  void _openFilterSheet() async {
    final result = await showTransactionFilterDraggableSheet(
      contextFlow: context,
      start: _filters.startDate,
      end: _filters.endDate,
      assets: _allAssets,
      filters: _filters,
    );
    if (result != null) {
      setState(() {
        _filters = result;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _filters = TransactionFiltersEntity();
    });
  }

  bool get _hasActiveFilters {
    return _filters.filter != null && _filters.filter!.isNotEmpty ||
        _filters.startDate != null ||
        _filters.endDate != null ||
        (_filters.orderByMostRecent != null && !_filters.orderByMostRecent!);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return BackdropPageScaffold(
      title: t.tx_history_title,
      leading: BackButton(
        onPressed: () {
          context.pop();
        },
      ),
      actions: [
        OfflineIndicator(onTap: () => OfflinePriceInfoOverlay.show(context)),
        HistoryFilterButton(
          active: _hasActiveFilters,
          onPressed: _openFilterSheet,
          tooltip: t.tx_filter_title,
        ),
        const SizedBox(width: 8),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(v2LegacyTransactionsProvider);
          try {
            await ref.read(v2LegacyTransactionsProvider.future);
          } catch (_) {}
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight -
                  32,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                BackdropPageScaffold.gutter,
                8,
                BackdropPageScaffold.gutter,
                0,
              ),
              child: Consumer(
                builder: (context, ref, _) {
                  final transactionHistory = ref.watch(
                    v2LegacyTransactionsProvider,
                  );
                  final isVisible = ref.watch(isVisibleProvider);
                  return transactionHistory.when(
                    data: (transactions) {
                          final filteredTransactions = _applyFilters(
                            transactions,
                          );

                            if (filteredTransactions.isEmpty) {
                              return Column(
                                children: [
                                  if (_hasActiveFilters)
                                    ActiveFiltersBar(
                                      icon: Icons.info_outline_rounded,
                                      text: t.tx_history_filters_active(
                                        _getActiveFiltersDescription(),
                                      ),
                                      clearLabel: t.tx_history_clear,
                                      onClear: _clearFilters,
                                    ),
                                  const EmptyTransactionList(glass: true),
                                  SizedBox(height: _listBottomSpace(context)),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                if (_hasActiveFilters)
                                  ActiveFiltersBar(
                                    text: t.tx_history_filter_count(
                                      filteredTransactions.length,
                                      transactions.length,
                                      _getActiveFiltersDescription().isNotEmpty
                                          ? _getActiveFiltersDescription()
                                          : t.tx_history_filter_default,
                                    ),
                                    clearLabel: t.tx_history_clear,
                                    onClear: _clearFilters,
                                  ),
                                SuccessfulTransactionList(
                                  transactions: filteredTransactions,
                                  isVisible: isVisible,
                                  glass: true,
                                ),
                                SizedBox(height: _listBottomSpace(context)),
                              ],
                            );
                          },
                    error: (err, stackTrace) => ErrorTransactionList(),
                    loading: () => const LoadingTransactionList(glass: true),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getActiveFiltersDescription() {
    final t = AppLocalizations.of(context);
    List<String> descriptions = [];

    final type = _filters.filter?['type'] as String?;
    if (type != null && type != 'all') {
      switch (type) {
        case 'send':
          descriptions.add(t.tx_type_send);
          break;
        case 'receive':
          descriptions.add(t.tx_type_receive);
          break;
        case 'swap':
          descriptions.add(t.tx_type_swap);
          break;
        case 'refund':
          descriptions.add(t.tx_history_filter_refunds);
          break;
      }
    }

    final assetIds = _filters.filter?['assets'] as List<String>?;
    if (assetIds != null && assetIds.isNotEmpty) {
      final assetNames = assetIds
          .map((id) {
            final asset = Asset.values.firstWhere(
              (a) => a.id == id,
              orElse: () => Asset.btc,
            );
            return asset.ticker;
          })
          .join(', ');
      descriptions.add(assetNames);
    }

    if (_filters.startDate != null || _filters.endDate != null) {
      if (_filters.startDate != null && _filters.endDate != null) {
        descriptions.add(
          '${_formatDate(_filters.startDate!)} - ${_formatDate(_filters.endDate!)}',
        );
      } else if (_filters.startDate != null) {
        descriptions.add(
          t.tx_history_filter_from(_formatDate(_filters.startDate!)),
        );
      } else if (_filters.endDate != null) {
        descriptions.add(
          t.tx_history_filter_until(_formatDate(_filters.endDate!)),
        );
      }
    }

    if (_filters.orderByMostRecent != null && !_filters.orderByMostRecent!) {
      descriptions.add(t.tx_history_filter_oldest_first);
    }

    return descriptions.join(' • ');
  }

  /// Space under the list, so its end clears the floating navigation
  /// capsule that overlaps the page.
  double _listBottomSpace(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + 24;

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}
