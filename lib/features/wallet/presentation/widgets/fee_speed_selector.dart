import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

enum FeeSpeed { low, medium, fast }

class FeeSpeedSelector extends StatefulWidget {
  final FeeSpeed selectedSpeed;
  final ValueChanged<FeeSpeed> onSpeedChanged;
  final int? lowFeeSatPerVByte;
  final int? mediumFeeSatPerVByte;
  final int? fastFeeSatPerVByte;

  const FeeSpeedSelector({
    super.key,
    required this.selectedSpeed,
    required this.onSpeedChanged,
    this.lowFeeSatPerVByte,
    this.mediumFeeSatPerVByte,
    this.fastFeeSatPerVByte,
  });

  @override
  State<FeeSpeedSelector> createState() => _FeeSpeedSelectorState();
}

class _FeeSpeedSelectorState extends State<FeeSpeedSelector> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Velocidade da transação',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _FeeSpeedOption(
                title: 'Econômica',
                subtitle: '~60+ min',
                feeRate: widget.lowFeeSatPerVByte ?? 1,
                isSelected: widget.selectedSpeed == FeeSpeed.low,
                onTap: () => widget.onSpeedChanged(FeeSpeed.low),
                isLoading: widget.lowFeeSatPerVByte == null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FeeSpeedOption(
                title: 'Normal',
                subtitle: '~30 min',
                feeRate: widget.mediumFeeSatPerVByte ?? 3,
                isSelected: widget.selectedSpeed == FeeSpeed.medium,
                onTap: () => widget.onSpeedChanged(FeeSpeed.medium),
                isLoading: widget.mediumFeeSatPerVByte == null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FeeSpeedOption(
                title: 'Rápida',
                subtitle: '~10 min',
                feeRate: widget.fastFeeSatPerVByte ?? 5,
                isSelected: widget.selectedSpeed == FeeSpeed.fast,
                onTap: () => widget.onSpeedChanged(FeeSpeed.fast),
                isLoading: widget.fastFeeSatPerVByte == null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeeSpeedOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final int feeRate;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isLoading;

  const _FeeSpeedOption({
    required this.title,
    required this.subtitle,
    required this.feeRate,
    required this.isSelected,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = AppColors.baseColor;
    final highlightColor = AppColors.highlightColor;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFFE91E63).withOpacity(0.1)
                  : const Color(0xFF2C2C2C),
          border: Border.all(
            color: isSelected ? const Color(0xFFE91E63) : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFE91E63) : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            isLoading
                ? Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  child: Container(
                    width: 60,
                    height: 12,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )
                : Text(
                  '$feeRate sat/vB',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
                ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
