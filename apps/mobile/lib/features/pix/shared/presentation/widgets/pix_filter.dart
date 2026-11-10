import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_filter_entity.dart';
import 'package:mooze_mobile/features/transaction_history/widgets/filter_glass_widgets.dart';
import 'package:mooze_mobile/features/transaction_history/widgets/transaction_filter_by_order.dart';
import 'package:mooze_mobile/features/transaction_history/widgets/transaction_filter_by_date.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

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
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final t = AppLocalizations.of(context);
          return FilterSheetFrame(
            title: t.tx_filter_pix_title,
            actions: FilterSheetActions(
              clearLabel: t.tx_filter_clear_filters,
              onClear: () {
                Navigator.of(context).pop(PixFiltersEntity());
              },
              applyLabel: t.tx_filter_apply,
              onApply: () {
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
                title: t.tx_filter_deposit_status,
                child: Wrap(
                  spacing: 8,
                  children:
                      const [
                        'all',
                        'pending',
                        'processing',
                        'finished',
                        'expired',
                      ].map((status) {
                        return FilterChipPill(
                          label: _getStatusLabel(t, status),
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
                child: Wrap(
                  spacing: 8,
                  children: assets.map((asset) {
                    final isSelected = selectedAssetIds.contains(asset.id);
                    return FilterChipPill(
                      label: asset.name,
                      selected: isSelected,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedAssetIds.remove(asset.id);
                          } else {
                            selectedAssetIds.add(asset.id);
                          }
                        });
                      },
                    );
                  }).toList(),
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

String _getStatusLabel(AppLocalizations t, String status) {
  switch (status) {
    case 'all':
      return t.tx_status_all;
    case 'pending':
      return t.pix_filter_status_pending;
    case 'processing':
      return t.pix_filter_status_processing;
    case 'finished':
      return t.pix_filter_status_finished;
    case 'expired':
      return t.pix_filter_status_expired;
    default:
      return status;
  }
}

String _formatDate(DateTime date) {
  return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
}
