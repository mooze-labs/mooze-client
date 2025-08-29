import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

enum TimePeriod { day, week, month }

class PeriodSelectorWidget extends StatelessWidget {
  final TimePeriod selectedPeriod;
  final Function(TimePeriod) onPeriodChanged;

  const PeriodSelectorWidget({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children:
            TimePeriod.values.map((period) {
              final isSelected = selectedPeriod == period;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onPeriodChanged(period),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.primaryColor
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _getPeriodLabel(period),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  String _getPeriodLabel(TimePeriod period) {
    switch (period) {
      case TimePeriod.day:
        return '1D';
      case TimePeriod.week:
        return '7D';
      case TimePeriod.month:
        return '1M';
    }
  }
}
