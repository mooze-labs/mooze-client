import 'package:flutter/material.dart';

import 'package:mooze_mobile/features/transaction_history/widgets/asset_filter_entity.dart';
import 'package:mooze_mobile/features/transaction_history/widgets/transaction_filter_by_asset.dart';
import 'package:mooze_mobile/features/transaction_history/widgets/transaction_filter_by_order.dart';
import 'package:mooze_mobile/features/transaction_history/widgets/transaction_filter_by_date.dart';
import 'package:mooze_mobile/shared/widgets/buttons.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

Future<TransactionFiltersEntity?> showTransactionFilterDraggableSheet({
  required BuildContext contextFlow,
  required DateTime? start,
  required DateTime? end,
  required List<AssetEntity> assets,
  required TransactionFiltersEntity filters,
}) async {
  TransactionTypeEntity selectedType = TransactionTypeEntity.all;
  TransactionStatusEntity selectedStatus = TransactionStatusEntity.all;
  List<String> selectedAssetIds = [];
  bool isMostRecentSelected = filters.orderByMostRecent ?? true;
  DateTime? startDate = filters.startDate;
  DateTime? endDate = filters.endDate;

  List<int> dateRanges = [7, 30, 90];
  int? selectedDateRangeIndex;

  if (filters.filter != null) {
    final type = filters.filter!['type'] as String?;
    if (type != null) {
      selectedType = TransactionTypeEntity.values.firstWhere(
        (t) => t.name == type,
        orElse: () => TransactionTypeEntity.all,
      );
    }
    final status = filters.filter!['status'] as String?;
    if (status != null) {
      selectedStatus = TransactionStatusEntity.values.firstWhere(
        (s) => s.name == status,
        orElse: () => TransactionStatusEntity.all,
      );
    }
    final assetIds = filters.filter!['assets'] as List<String>?;
    if (assetIds != null) {
      selectedAssetIds = List.from(assetIds);
    }
  }

  if (startDate != null && endDate != null) {
    final now = DateTime.now();
    final daysDifference = now.difference(startDate).inDays;

    for (int i = 0; i < dateRanges.length; i++) {
      if (daysDifference == dateRanges[i]) {
        selectedDateRangeIndex = i;
        break;
      }
    }
  }

  final result = await showModalBottomSheet<TransactionFiltersEntity>(
    context: contextFlow,
    isScrollControlled: true,
    useRootNavigator: true,
    elevation: 0,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.7,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Container(
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 16,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 50,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Text(
                                'Filtros',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),

                          _buildFilterSection(
                            title: 'Ordenar por',
                            child: FilterOrderBy(
                              isMostRecentSelected: isMostRecentSelected,
                              onSelectionChanged: (isRecent) {
                                setState(() {
                                  isMostRecentSelected = isRecent;
                                });
                              },
                            ),
                            context: context,
                          ),

                          _buildFilterSection(
                            title: 'Tipo de transação',
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children:
                                  TransactionTypeEntity.values.map((type) {
                                    final isSelected = selectedType == type;

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedType = type;
                                        });
                                      },
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final double totalWidth =
                                              constraints.maxWidth;
                                          const double totalSpacing = 2 * 10;
                                          final double itemWidth =
                                              (totalWidth - totalSpacing) / 3;
                                          return Container(
                                            width: itemWidth,
                                            height: 47,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              color:
                                                  isSelected
                                                      ? AppColors.primaryColor
                                                          .withValues(
                                                            alpha: 0.3,
                                                          )
                                                      : Colors.grey,
                                              border:
                                                  isSelected
                                                      ? Border.all(
                                                        color:
                                                            AppColors
                                                                .primaryColor,
                                                        width: 2,
                                                      )
                                                      : null,
                                            ),
                                            child: Center(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 5.0,
                                                    ),
                                                child: Text(
                                                  _getTransactionTypeLabel(
                                                    type,
                                                  ),
                                                  maxLines: 2,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  }).toList(),
                            ),
                            context: context,
                          ),

                          _buildFilterSection(
                            title: 'Status',
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children:
                                  TransactionStatusEntity.values.map((status) {
                                    final isSelected = selectedStatus == status;

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedStatus = status;
                                        });
                                      },
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final double totalWidth =
                                              constraints.maxWidth;
                                          const double totalSpacing = 2 * 10;
                                          final double itemWidth =
                                              (totalWidth - totalSpacing) / 3;
                                          return Container(
                                            width: itemWidth,
                                            height: 47,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              color:
                                                  isSelected
                                                      ? AppColors.primaryColor
                                                          .withValues(
                                                            alpha: 0.3,
                                                          )
                                                      : Colors.grey,
                                              border:
                                                  isSelected
                                                      ? Border.all(
                                                        color:
                                                            AppColors
                                                                .primaryColor,
                                                        width: 2,
                                                      )
                                                      : null,
                                            ),
                                            child: Center(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 5.0,
                                                    ),
                                                child: Text(
                                                  _getTransactionStatusLabel(
                                                    status,
                                                  ),
                                                  maxLines: 2,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  }).toList(),
                            ),
                            context: context,
                          ),

                          _buildFilterSection(
                            title: 'Moeda',
                            child: FilterByAsset(
                              assets: assets,
                              selectedAssetIds: selectedAssetIds,
                              onSelectionChanged: (ids) {
                                setState(() {
                                  selectedAssetIds = ids;
                                });
                              },
                            ),
                            context: context,
                          ),

                          _buildFilterSection(
                            title: 'Período',
                            child: StatefulBuilder(
                              builder: (
                                BuildContext context,
                                StateSetter setDateState,
                              ) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children:
                                          dateRanges.map((days) {
                                            final index = dateRanges.indexOf(
                                              days,
                                            );
                                            final isSelected =
                                                selectedDateRangeIndex == index;

                                            return Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  right:
                                                      index <
                                                              dateRanges
                                                                      .length -
                                                                  1
                                                          ? 8
                                                          : 0,
                                                ),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setDateState(() {
                                                      if (selectedDateRangeIndex ==
                                                          index) {
                                                        selectedDateRangeIndex =
                                                            null;
                                                        startDate = null;
                                                        endDate = null;
                                                      } else {
                                                        selectedDateRangeIndex =
                                                            index;
                                                        final dateRange =
                                                            calculateDateRange(
                                                              days: days,
                                                            );
                                                        startDate =
                                                            dateRange.start;
                                                        endDate = dateRange.end;
                                                      }
                                                    });
                                                    setState(() {});
                                                  },
                                                  child: Container(
                                                    height: 47,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            15,
                                                          ),
                                                      color:
                                                          isSelected
                                                              ? AppColors
                                                                  .primaryColor
                                                                  .withValues(
                                                                    alpha: 0.3,
                                                                  )
                                                              : Colors.grey,
                                                      border:
                                                          isSelected
                                                              ? Border.all(
                                                                color:
                                                                    AppColors
                                                                        .primaryColor,
                                                                width: 2,
                                                              )
                                                              : null,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        '${days}D',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                    ),

                                    const SizedBox(height: 16),

                                    GestureDetector(
                                      onTap: () async {
                                        final dateRange = await datapicker(
                                          context,
                                          initialStartDate: startDate,
                                          initialEndDate: endDate,
                                        );
                                        if (dateRange != null) {
                                          setDateState(() {
                                            selectedDateRangeIndex = null;
                                            startDate = dateRange.start;
                                            endDate = dateRange.end;
                                          });
                                          setState(() {});
                                        }
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        height: 47,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          color:
                                              startDate != null &&
                                                      endDate != null &&
                                                      selectedDateRangeIndex ==
                                                          null
                                                  ? AppColors.primaryColor
                                                      .withValues(alpha: 0.3)
                                                  : Colors.grey,
                                          border:
                                              startDate != null &&
                                                      endDate != null &&
                                                      selectedDateRangeIndex ==
                                                          null
                                                  ? Border.all(
                                                    color:
                                                        AppColors.primaryColor,
                                                    width: 2,
                                                  )
                                                  : null,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              startDate != null &&
                                                      endDate != null &&
                                                      selectedDateRangeIndex ==
                                                          null
                                                  ? '${_formatDate(startDate!)} - ${_formatDate(endDate!)}'
                                                  : 'Período personalizado',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    if (startDate != null ||
                                        endDate != null) ...[
                                      const SizedBox(height: 12),
                                      Center(
                                        child: TextButton.icon(
                                          onPressed: () {
                                            setDateState(() {
                                              selectedDateRangeIndex = null;
                                              startDate = null;
                                              endDate = null;
                                            });
                                            setState(() {});
                                          },
                                          icon: Icon(
                                            Icons.clear,
                                            size: 18,
                                            color: Colors.grey[600],
                                          ),
                                          label: Text(
                                            'Limpar período',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                            context: context,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: SecondaryButton(
                                  text: 'Limpar filtros',
                                  onPressed: () {
                                    Navigator.of(
                                      context,
                                    ).pop(TransactionFiltersEntity());
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: PrimaryButton(
                                  text: 'Aplicar filtros',
                                  onPressed: () {
                                    final filterMap = <String, dynamic>{};
                                    filterMap['type'] = selectedType.name;
                                    filterMap['status'] = selectedStatus.name;
                                    if (selectedAssetIds.isNotEmpty) {
                                      filterMap['assets'] = selectedAssetIds;
                                    }

                                    final result = TransactionFiltersEntity(
                                      filter: filterMap,
                                      orderByMostRecent: isMostRecentSelected,
                                      startDate: startDate,
                                      endDate: endDate,
                                    );
                                    Navigator.of(context).pop(result);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    },
  );
  return result;
}

Widget _buildFilterSection({
  required String title,
  required Widget child,
  required BuildContext context,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}

DateTimeRange calculateDateRange({required int days}) {
  final now = DateTime.now();
  final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
  final startDate = DateTime(now.year, now.month, now.day - days + 1);
  return DateTimeRange(start: startDate, end: endDate);
}

String _getTransactionTypeLabel(TransactionTypeEntity type) {
  switch (type) {
    case TransactionTypeEntity.all:
      return 'Todas';
    case TransactionTypeEntity.send:
      return 'Envio';
    case TransactionTypeEntity.receive:
      return 'Recebimento';
    case TransactionTypeEntity.swap:
      return 'Swap';
  }
}

String _getTransactionStatusLabel(TransactionStatusEntity status) {
  switch (status) {
    case TransactionStatusEntity.all:
      return 'Todos';
    case TransactionStatusEntity.pending:
      return 'Pendente';
    case TransactionStatusEntity.confirmed:
      return 'Confirmado';
    case TransactionStatusEntity.failed:
      return 'Falhou';
    case TransactionStatusEntity.refundable:
      return 'Reembolsável';
  }
}

String _formatDate(DateTime date) {
  return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
}
