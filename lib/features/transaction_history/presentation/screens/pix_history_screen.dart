import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/pix/presentation/controllers/pix_history_controller.dart';
import 'package:mooze_mobile/features/pix/presentation/providers/pix_history_provider.dart';
import 'package:mooze_mobile/features/pix/presentation/widgets/pix_filter_entity.dart';
import 'package:mooze_mobile/features/pix/presentation/widgets/pix_filter.dart';
import 'package:mooze_mobile/features/pix/presentation/widgets/pix_deposit_list.dart';
import 'package:mooze_mobile/features/pix/presentation/widgets/providers/pix_history_state_notifier.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class PixHistoryScreen extends ConsumerStatefulWidget {
  const PixHistoryScreen({super.key});

  @override
  ConsumerState<PixHistoryScreen> createState() => _PixHistoryScreenState();
}

class _PixHistoryScreenState extends ConsumerState<PixHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  PixFiltersEntity _filters = PixFiltersEntity();
  List<AssetEntity> _allAssets = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollListener);
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

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  List<PixDeposit> _applyFilters(List<PixDeposit> deposits) {
    return deposits.applyFilters(_filters);
  }

  /// Usado para detectar quando estiver próximo do fim da lista atual.
  /// Consulta mais valores quando perto do fim da tela.
  void _onScrollListener() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    const delta = 200.0;

    if (maxScroll - currentScroll <= delta) {
      ref.read(pixHistoryNotifierProvider.notifier).loadNextPage();
    }
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
          OfflineIndicator(onTap: () => OfflinePriceInfoOverlay.show(context)),
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
            final pixHistoryState = ref.watch(pixHistoryNotifierProvider);
            final isVisible = ref.watch(isVisibleProvider);

            return pixHistoryState.when(
              data: (deposits) {
                final filteredDeposits = _applyFilters(deposits.items);

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
                        filterClosure: _applyFilters,
                        isVisible: isVisible,
                        scrollController: _scrollController,
                        onRefresh: () {
                          ref
                              .read(pixHistoryNotifierProvider.notifier)
                              .refresh();
                        },
                      ),
                    ),
                  ],
                );
              },
              error:
                  (err, stackTrace) => ErrorPixDepositList(
                    onRetry: () {
                      ref.read(pixHistoryNotifierProvider.notifier).refresh();
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
