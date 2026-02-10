import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/pix/presentation/widgets/pix_filter_entity.dart';
import 'package:mooze_mobile/features/transaction_history/widgets/transaction_filter_by_order.dart';
import 'package:mooze_mobile/features/transaction_history/widgets/transaction_filter_by_date.dart';
import 'package:mooze_mobile/shared/widgets/buttons.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

Future<PixFiltersEntity?> showPixFilterDraggableSheet({
  required BuildContext contextFlow,
  required DateTime? start,
  required DateTime? end,
  required List<AssetEntity> assets,
  required PixFiltersEntity filters,
}) async {
  String selectedStatus = 'all';
  List<String> selectedAssetIds = [];
  bool isMostRecentSelected = filters.orderByMostRecent ?? true;
  DateTime? startDate = filters.startDate;
  DateTime? endDate = filters.endDate;

  List<int> dateRanges = [7, 30, 90];
  int? selectedDateRangeIndex;

  if (filters.filter != null) {
    final status = filters.filter!['status'] as String?;
    if (status != null) {
      selectedStatus = status;
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

  final result = await showModalBottomSheet<PixFiltersEntity>(
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
                                'Filtros PIX',
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
                            title: 'Status do depósito',
                            child: _buildOptimizedGrid(
                              items: [
                                'all',
                                'pending',
                                'processing',
                                'finished',
                                'expired',
                              ],
                              selectedItem: selectedStatus,
                              onItemSelected: (status) {
                                setState(() {
                                  selectedStatus = status;
                                });
                              },
                              labelBuilder: (status) => _getStatusLabel(status),
                            ),
                            context: context,
                          ),

                          _buildFilterSection(
                            title: 'Moeda',
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children:
                                  assets.map((asset) {
                                    final isSelected = selectedAssetIds
                                        .contains(asset.id);
                                    return LayoutBuilder(
                                      builder: (context, constraints) {
                                        final double totalWidth =
                                            constraints.maxWidth;
                                        const double totalSpacing = 2 * 10;
                                        final double itemWidth =
                                            (totalWidth - totalSpacing) / 3;

                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (isSelected) {
                                                selectedAssetIds.remove(
                                                  asset.id,
                                                );
                                              } else {
                                                selectedAssetIds.add(asset.id);
                                              }
                                            });
                                          },
                                          child: Container(
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
                                                padding: const EdgeInsets.all(
                                                  8.0,
                                                ),
                                                child: Text(
                                                  asset.name,
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
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
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
                                    ).pop(PixFiltersEntity());
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: PrimaryButton(
                                  text: 'Aplicar filtros',
                                  onPressed: () {
                                    final filterMap = <String, dynamic>{};
                                    filterMap['status'] = selectedStatus;
                                    if (selectedAssetIds.isNotEmpty) {
                                      filterMap['assets'] = selectedAssetIds;
                                    }

                                    final result = PixFiltersEntity(
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

Widget _buildOptimizedGrid<T>({
  required List<T> items,
  required T selectedItem,
  required Function(T) onItemSelected,
  required String Function(T) labelBuilder,
}) {
  List<List<T>> distributeItems(List<T> items) {
    if (items.isEmpty) return [];

    final totalItems = items.length;
    final List<List<T>> rows = [];

    if (totalItems <= 3) {
      rows.add(items);
    } else if (totalItems == 4) {
      rows.add(items.sublist(0, 2));
      rows.add(items.sublist(2, 4));
    } else if (totalItems == 5) {
      rows.add(items.sublist(0, 3));
      rows.add(items.sublist(3, 5));
    } else if (totalItems == 6) {
      rows.add(items.sublist(0, 3));
      rows.add(items.sublist(3, 6));
    } else {
      for (int i = 0; i < totalItems; i += 3) {
        final end = (i + 3 < totalItems) ? i + 3 : totalItems;
        rows.add(items.sublist(i, end));
      }
    }

    return rows;
  }

  final distributedRows = distributeItems(items);

  return Column(
    children:
        distributedRows.asMap().entries.map((rowEntry) {
          final rowIndex = rowEntry.key;
          final rowItems = rowEntry.value;

          return Column(
            children: [
              if (rowIndex > 0) const SizedBox(height: 8),
              Row(
                children:
                    rowItems.asMap().entries.map((itemEntry) {
                      final itemIndex = itemEntry.key;
                      final item = itemEntry.value;
                      final isSelected = selectedItem == item;

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: itemIndex < rowItems.length - 1 ? 8 : 0,
                          ),
                          child: GestureDetector(
                            onTap: () => onItemSelected(item),
                            child: Container(
                              height: 47,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color:
                                    isSelected
                                        ? AppColors.primaryColor.withValues(
                                          alpha: 0.3,
                                        )
                                        : Colors.grey,
                                border:
                                    isSelected
                                        ? Border.all(
                                          color: AppColors.primaryColor,
                                          width: 2,
                                        )
                                        : null,
                              ),
                              child: Center(
                                child: Text(
                                  labelBuilder(item),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
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
            ],
          );
        }).toList(),
  );
}

DateTimeRange calculateDateRange({required int days}) {
  final now = DateTime.now();
  final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
  final startDate = DateTime(now.year, now.month, now.day - days + 1);
  return DateTimeRange(start: startDate, end: endDate);
}

String _getStatusLabel(String status) {
  switch (status) {
    case 'all':
      return 'Todos';
    case 'pending':
      return DepositStatus.pending.label;
    case 'under_review':
      return DepositStatus.underReview.label;
    case 'processing':
      return DepositStatus.processing.label;
    case 'funds_prepared':
      return DepositStatus.fundsPrepared.label;
    case 'depix_sent':
    case "paid":
      return DepositStatus.depixSent.label;
    case 'broadcasted':
      return DepositStatus.broadcasted.label;
    case 'finished':
      return DepositStatus.finished.label;
    case 'failed':
      return DepositStatus.failed.label;
    case 'expired':
      return DepositStatus.expired.label;
    default:
      return 'Todos';
  }
}

String _formatDate(DateTime date) {
  return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
}
