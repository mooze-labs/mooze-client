import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/refund/refund_provider.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

/// Widget to display and choose between different fee options
class FeeChooser extends StatelessWidget {
  final int amountSat;
  final List<RefundFeeOption> feeOptions;
  final int selectedFeeIndex;
  final Function(int) onSelect;

  const FeeChooser({
    super.key,
    required this.amountSat,
    required this.feeOptions,
    required this.selectedFeeIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    // Get affordable options
    final affordableFees =
        feeOptions
            .where((f) => f.isAffordable(feeCoverageSat: amountSat))
            .toList();

    if (affordableFees.isEmpty) {
      return Center(
        child: Text(
          'Valor muito pequeno para cobrir as taxas',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      );
    }

    // Define fee labels based on position
    final labels = _getFeeLabels(affordableFees.length);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Text(
            'Selecione a velocidade da transação',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        ...List.generate(affordableFees.length, (index) {
          final feeOption = affordableFees[index];
          final isSelected = index == selectedFeeIndex;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildFeeOptionCard(
              label: labels[index]['label']!,
              estimatedTime: labels[index]['time']!,
              feeRate: feeOption.feeRateSatPerVbyte.toInt(),
              txFee: feeOption.txFeeSat.toInt(),
              isSelected: isSelected,
              onTap: () => onSelect(index),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFeeOptionCard({
    required String label,
    required String estimatedTime,
    required int feeRate,
    required int txFee,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primaryColor.withValues(alpha: 0.1)
                  : AppColors.backgroundCard,
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              estimatedTime,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Taxa: $feeRate sat/vB',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Total: ${_formatSats(txFee)} sats',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, String>> _getFeeLabels(int count) {
    if (count == 1) {
      return [
        {'label': 'Padrão', 'time': '~1 hora'},
      ];
    } else if (count == 2) {
      return [
        {'label': 'Economia', 'time': '~24 horas'},
        {'label': 'Rápido', 'time': '~30 minutos'},
      ];
    } else if (count == 3) {
      return [
        {'label': 'Economia', 'time': '~24 horas'},
        {'label': 'Padrão', 'time': '~1 hora'},
        {'label': 'Rápido', 'time': '~30 minutos'},
      ];
    } else {
      // 4 or more options
      return [
        {'label': 'Economia', 'time': '~24 horas'},
        {'label': 'Padrão', 'time': '~1 hora'},
        {'label': 'Rápido', 'time': '~30 minutos'},
        {'label': 'Urgente', 'time': '~10 minutos'},
      ];
    }
  }

  String _formatSats(int sats) {
    return sats.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
