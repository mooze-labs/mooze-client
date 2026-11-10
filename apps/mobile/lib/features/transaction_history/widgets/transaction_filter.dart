import 'package:flutter/material.dart';

import 'package:mooze_mobile/features/transaction_history/widgets/asset_filter_entity.dart';
import 'package:mooze_mobile/features/transaction_history/widgets/filter_glass_widgets.dart';
import 'package:mooze_mobile/features/transaction_history/widgets/transaction_filter_by_asset.dart';
import 'package:mooze_mobile/features/transaction_history/widgets/transaction_filter_by_order.dart';
import 'package:mooze_mobile/features/transaction_history/widgets/transaction_filter_by_date.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

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
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final t = AppLocalizations.of(context);
          return FilterSheetFrame(
            title: t.tx_filter_title,
            actions: FilterSheetActions(
              clearLabel: t.tx_filter_clear_filters,
              onClear: () {
                Navigator.of(context).pop(TransactionFiltersEntity());
              },
              applyLabel: t.tx_filter_apply,
              onApply: () {
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
            children: [
              FilterSection(
                title: t.tx_filter_sort_by,
                child: FilterOrderBy(
                  isMostRecentSelected: isMostRecentSelected,
                  onSelectionChanged: (isRecent) {
                    setState(() {
                      isMostRecentSelected = isRecent;
                    });
                  },
                ),
              ),

              FilterSection(
                title: t.tx_filter_type,
                child: Wrap(
                  spacing: 8,
                  children: TransactionTypeEntity.values.map((type) {
                    return FilterChipPill(
                      label: _getTransactionTypeLabel(t, type),
                      selected: selectedType == type,
                      onTap: () {
                        setState(() {
                          selectedType = type;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

              FilterSection(
                title: t.tx_filter_status,
                child: Wrap(
                  spacing: 8,
                  children: TransactionStatusEntity.values.map((status) {
                    return FilterChipPill(
                      label: _getTransactionStatusLabel(t, status),
                      selected: selectedStatus == status,
                      onTap: () {
                        setState(() {
                          selectedStatus = status;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

              FilterSection(
                title: t.tx_filter_currency,
                child: FilterByAsset(
                  assets: assets,
                  selectedAssetIds: selectedAssetIds,
                  onSelectionChanged: (ids) {
                    setState(() {
                      selectedAssetIds = ids;
                    });
                  },
                ),
              ),

              FilterSection(
                title: t.tx_filter_period,
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setDateState) {
                    final isCustomRange =
                        startDate != null &&
                        endDate != null &&
                        selectedDateRangeIndex == null;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilterChipRow(
                          children: dateRanges.map((days) {
                            final index = dateRanges.indexOf(days);
                            return FilterChipPill(
                              label: '${days}D',
                              expand: true,
                              selected: selectedDateRangeIndex == index,
                              onTap: () {
                                setDateState(() {
                                  if (selectedDateRangeIndex == index) {
                                    selectedDateRangeIndex = null;
                                    startDate = null;
                                    endDate = null;
                                  } else {
                                    selectedDateRangeIndex = index;
                                    final dateRange = calculateDateRange(
                                      days: days,
                                    );
                                    startDate = dateRange.start;
                                    endDate = dateRange.end;
                                  }
                                });
                                setState(() {});
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 8),

                        GlassPickerField(
                          leadingIcon: Icons.calendar_today_rounded,
                          active: isCustomRange,
                          placeholder: !isCustomRange,
                          text: isCustomRange
                              ? '${_formatDate(startDate!)} - ${_formatDate(endDate!)}'
                              : t.tx_filter_period_custom,
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
                        ),

                        if (startDate != null || endDate != null) ...[
                          const SizedBox(height: 4),
                          Center(
                            child: FilterTextAction(
                              icon: Icons.close_rounded,
                              label: t.tx_filter_clear_period,
                              onPressed: () {
                                setDateState(() {
                                  selectedDateRangeIndex = null;
                                  startDate = null;
                                  endDate = null;
                                });
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    },
  );
  return result;
}

DateTimeRange calculateDateRange({required int days}) {
  final now = DateTime.now();
  final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
  final startDate = DateTime(now.year, now.month, now.day - days + 1);
  return DateTimeRange(start: startDate, end: endDate);
}

String _getTransactionTypeLabel(
  AppLocalizations t,
  TransactionTypeEntity type,
) {
  switch (type) {
    case TransactionTypeEntity.all:
      return t.tx_type_all;
    case TransactionTypeEntity.send:
      return t.tx_type_send;
    case TransactionTypeEntity.receive:
      return t.tx_type_receive;
    case TransactionTypeEntity.swap:
      return t.tx_type_swap;
  }
}

String _getTransactionStatusLabel(
  AppLocalizations t,
  TransactionStatusEntity status,
) {
  switch (status) {
    case TransactionStatusEntity.all:
      return t.tx_status_all;
    case TransactionStatusEntity.pending:
      return t.tx_status_pending;
    case TransactionStatusEntity.confirmed:
      return t.tx_status_confirmed;
    case TransactionStatusEntity.failed:
      return t.tx_status_failed;
    case TransactionStatusEntity.refundable:
      return t.tx_status_refundable;
  }
}

String _formatDate(DateTime date) {
  return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
}
