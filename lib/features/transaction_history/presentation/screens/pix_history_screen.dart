import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/pix/presentation/controllers/pix_history_controller.dart';
import 'package:mooze_mobile/features/pix/presentation/widgets/pix_filter_entity.dart';
import 'package:mooze_mobile/features/pix/presentation/widgets/pix_filter.dart';
import 'package:mooze_mobile/features/pix/presentation/widgets/pix_deposit_list.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class PixHistoryScreen extends StatefulWidget {
  const PixHistoryScreen({super.key});

  @override
  State<PixHistoryScreen> createState() => _PixHistoryScreenState();
}

class _PixHistoryScreenState extends State<PixHistoryScreen> {
  PixFiltersEntity _filters = PixFiltersEntity();
  List<AssetEntity> _allAssets = [];

  @override
  void initState() {
    super.initState();
    _allAssets =
        Asset.values
            .where((asset) => asset != Asset.usdt)
            .map(
              (asset) => AssetEntity(
                id: asset.id,
                name: asset.name,
                iconPath: asset.iconPath,
              ),
            )
            .toList();
  }

  List<PixDeposit> _applyFilters(List<PixDeposit> deposits) {
    return deposits.applyFilters(_filters);
  }

  void _openFilterSheet() async {
    final result = await showPixFilterDraggableSheet(
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
      _filters = PixFiltersEntity();
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
        title: const Text('Histórico do PIX'),
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
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
            final pixHistoryState = ref.watch(pixHistoryControllerProvider);
            final isVisible = ref.watch(isVisibleProvider);

            return pixHistoryState.when(
              data: (deposits) {
                final filteredDeposits = _applyFilters(deposits);

                if (filteredDeposits.isEmpty) {
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
                              Icon(Icons.filter_alt, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getActiveFiltersDescription(),
                                  style: const TextStyle(fontSize: 14),
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
                      const Expanded(child: EmptyPixDepositList()),
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
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.filter_alt, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getActiveFiltersDescription(),
                                style: const TextStyle(fontSize: 14),
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
                      child: PixDepositList(
                        deposits: filteredDeposits,
                        isVisible: isVisible,
                        onRefresh: () {
                          ref
                              .read(pixHistoryControllerProvider.notifier)
                              .refreshPixHistory();
                        },
                      ),
                    ),
                  ],
                );
              },
              error:
                  (err, stackTrace) => ErrorPixDepositList(
                    onRetry: () {
                      ref
                          .read(pixHistoryControllerProvider.notifier)
                          .refreshPixHistory();
                    },
                  ),
              loading: () => const LoadingPixDepositList(),
            );
          },
        ),
      ),
    );
  }

  String _getActiveFiltersDescription() {
    List<String> descriptions = [];

    final status = _filters.filter?['status'] as String?;
    if (status != null && status != 'all') {
      switch (status) {
        case 'pending':
          descriptions.add('Pendentes');
          break;
        case 'processing':
          descriptions.add('Processando');
          break;
        case 'finished':
          descriptions.add('Finalizados');
          break;
        case 'expired':
          descriptions.add('Expirados');
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
