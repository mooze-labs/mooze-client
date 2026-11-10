import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/transaction_history/widgets/overlay_widget.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/features/transaction_history/widgets/filter_glass_widgets.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

Future<DateTimeRange?> datapicker(
  BuildContext context, {
  DateTime? initialStartDate,
  DateTime? initialEndDate,
}) async {
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
          return FilterSheetFrame(
            title: t.tx_filter_select_period,
            initialChildSize: 0.6,
            minChildSize: 0.5,
            maxChildSize: 0.8,
            snap: true,
            scrollable: false,
            actions: FilterSheetActions(
              clearLabel: t.common_cancel,
              onClear: () {
                Navigator.pop(context);
              },
              applyLabel: t.common_confirm,
              onApply: () {
                DateTime start = startDate ?? DateTime.now();
                DateTime end = endDate ?? DateTime.now();

                if (start.isAfter(end)) {
                  showErrorOverlay(context, t.tx_filter_start_after_end_error);
                } else {
                  Navigator.pop(context, DateTimeRange(start: start, end: end));
                }
              },
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: GlassPickerField(
                      trailingIcon: null,
                      active: isSelectingStartDate,
                      placeholder: startDate == null,
                      text: startDate != null
                          ? "${startDate!.day.toString().padLeft(2, '0')}/${startDate!.month.toString().padLeft(2, '0')}/${startDate!.year}"
                          : t.tx_filter_select,
                      onTap: () {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            isSelectingStartDate = true;
                          });
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      t.tx_filter_to,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GlassPickerField(
                      trailingIcon: null,
                      active: !isSelectingStartDate,
                      placeholder: endDate == null,
                      text: endDate != null
                          ? "${endDate!.day.toString().padLeft(2, '0')}/${endDate!.month.toString().padLeft(2, '0')}/${endDate!.year}"
                          : t.tx_filter_select,
                      onTap: () {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            isSelectingStartDate = false;
                          });
                        });
                      },
                    ),
                  ),
                ],
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: Motion.of(context, Motion.durationEmphasis),
                  switchInCurve: Motion.curveEnter,
                  switchOutCurve: Motion.curveExit,
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  child: CupertinoDatePicker(
                    key: ValueKey(isSelectingStartDate),
                    initialDateTime: isSelectingStartDate
                        ? (startDate)
                        : (endDate),
                    minimumYear: 1920,
                    maximumYear: 2100,
                    mode: CupertinoDatePickerMode.date,
                    onDateTimeChanged: (DateTime newDate) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
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
            ],
          );
        },
      );
    },
  );
}
