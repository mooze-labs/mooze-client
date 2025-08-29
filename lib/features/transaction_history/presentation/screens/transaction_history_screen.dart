import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/transaction_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/home/widgets/transaction_list.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/transaction_history/widgets/transaction_filter.dart';
import 'package:mooze_mobile/features/transaction_history/widgets/asset_filter_entity.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de transações'),
        leading: IconButton(
          onPressed: () {
            context.go('/menu');
          },
          icon: Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_alt_outlined,
              color: AppColors.primaryColor,
            ),
            onPressed: _openFilterSheet,
            tooltip: 'Filtros',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer(
          builder: (context, ref, _) {
            final transactionHistory = ref.watch(transactionHistoryProvider);
            final isVisible = ref.watch(isVisibleProvider);
            return transactionHistory.when(
              data:
                  (data) => data.fold((err) => ErrorTransactionList(), (
                    transactions,
                  ) {
                    final filteredTransactions = _applyFilters(transactions);

                    if (filteredTransactions.isEmpty) {
                      return Column(
                        children: [
                          if (_hasActiveFilters) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primaryColor.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppColors.primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Filtros ativos - ${_getActiveFiltersDescription()}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _clearFilters,
                                    child: const Text('Limpar'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          EmptyTransactionList(),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        if (_hasActiveFilters) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primaryColor.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.filter_alt,
                                  // color: Theme.of(,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${filteredTransactions.length} de ${transactions.length} transações - ${_getActiveFiltersDescription().isNotEmpty ? _getActiveFiltersDescription() : 'Todos'}',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _clearFilters,
                                  child: const Text('Limpar'),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Expanded(
                          child: SuccessfulTransactionList(
                            transactions: filteredTransactions,
                            isVisible: isVisible,
                          ),
                        ),
                      ],
                    );
                  }),
              error: (err, stackTrace) => ErrorTransactionList(),
              loading: () => LoadingTransactionList(),
            );
          },
        ),
      ),
    );
  }

  String _getActiveFiltersDescription() {
    List<String> descriptions = [];

    final type = _filters.filter?['type'] as String?;
    if (type != null && type != 'all') {
      switch (type) {
        case 'send':
          descriptions.add('Envios');
          break;
        case 'receive':
          descriptions.add('Recebimentos');
          break;
        case 'swap':
          descriptions.add('Swaps');
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
        descriptions.add('A partir de ${_formatDate(_filters.startDate!)}');
      } else if (_filters.endDate != null) {
        descriptions.add('Até ${_formatDate(_filters.endDate!)}');
      }
    }

    if (_filters.orderByMostRecent != null && !_filters.orderByMostRecent!) {
      descriptions.add('Mais antigos primeiro');
    }

    return descriptions.join(' • ');
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}
