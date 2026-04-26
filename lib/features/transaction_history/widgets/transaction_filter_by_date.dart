import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/transaction_history/widgets/overlay_widget.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

Future<DateTimeRange?> datapicker(
  BuildContext context, {
  DateTime? initialStartDate,
  DateTime? initialEndDate,
}) async {
  final ThemeData theme = Theme.of(context);
  DateTime? startDate = initialStartDate;
  DateTime? endDate = initialEndDate;
  bool isSelectingStartDate = true;

  return showModalBottomSheet<DateTimeRange>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          final t = AppLocalizations.of(context);
          return Container(
            decoration: BoxDecoration(
              color: context.colors.surfaceColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.5,
              maxChildSize: 0.8,
              expand: false,
              snap: true,
              builder: (context, scrollController) {
                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: Container(
                    padding: EdgeInsets.only(
                      top: 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                      right: 24,
                      left: 24,
                    ),
                    child: Column(
                      children: [
                        // Handle indicator
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
                            Expanded(
                              child: Text(
                                t.tx_filter_select_period,
                                style: Theme.of(context).textTheme.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ButtonStyle(
                                  shape: WidgetStateProperty.all<
                                    RoundedRectangleBorder
                                  >(
                                    RoundedRectangleBorder(
                                      side: BorderSide(
                                        color:
                                            isSelectingStartDate
                                                ? theme.colorScheme.primary
                                                    .withValues(alpha: 0.5)
                                                : Colors.transparent,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  backgroundColor:
                                      WidgetStateProperty.all<Color>(
                                        theme.colorScheme.surface.withValues(
                                          alpha: 1,
                                        ),
                                      ),
                                  elevation: WidgetStateProperty.all(0),
                                ),
                                onPressed: () {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    setState(() {
                                      isSelectingStartDate = true;
                                    });
                                  });
                                },
                                child: Text(
                                  startDate != null
                                      ? "${startDate!.day.toString().padLeft(2, '0')}/${startDate!.month.toString().padLeft(2, '0')}/${startDate!.year}"
                                      : t.tx_filter_select,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(t.tx_filter_to),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: ButtonStyle(
                                  shape: WidgetStateProperty.all<
                                    RoundedRectangleBorder
                                  >(
                                    RoundedRectangleBorder(
                                      side: BorderSide(
                                        color:
                                            !isSelectingStartDate
                                                ? theme.colorScheme.primary
                                                    .withValues(alpha: 0.5)
                                                : Colors.transparent,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  backgroundColor:
                                      WidgetStateProperty.all<Color>(
                                        theme.colorScheme.surface.withValues(
                                          alpha: 1,
                                        ),
                                      ),
                                  elevation: WidgetStateProperty.all(0),
                                ),
                                onPressed: () {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    setState(() {
                                      isSelectingStartDate = false;
                                    });
                                  });
                                },
                                child: Text(
                                  endDate != null
                                      ? "${endDate!.day.toString().padLeft(2, '0')}/${endDate!.month.toString().padLeft(2, '0')}/${endDate!.year}"
                                      : t.tx_filter_select,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (
                              Widget child,
                              Animation<double> animation,
                            ) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            child: CupertinoDatePicker(
                              key: ValueKey(isSelectingStartDate),
                              initialDateTime:
                                  isSelectingStartDate
                                      ? (startDate)
                                      : (endDate),
                              minimumYear: 1920,
                              maximumYear: 2100,
                              mode: CupertinoDatePickerMode.date,
                              onDateTimeChanged: (DateTime newDate) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  setState(() {
                                    if (isSelectingStartDate) {
                                      startDate = newDate;
                                    } else {
                                      endDate = newDate;
                                    }
                                  });
                                });
                              },
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: SecondaryButton(
                                text: t.common_cancel,
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: PrimaryButton(
                                text: t.common_confirm,
                                onPressed: () {
                                  DateTime start = startDate ?? DateTime.now();
                                  DateTime end = endDate ?? DateTime.now();

                                  if (start.isAfter(end)) {
                                    showErrorOverlay(
                                      context,
                                      t.tx_filter_start_after_end_error,
                                    );
                                  } else {
                                    Navigator.pop(
                                      context,
                                      DateTimeRange(start: start, end: end),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 30),
                      ],
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
}
