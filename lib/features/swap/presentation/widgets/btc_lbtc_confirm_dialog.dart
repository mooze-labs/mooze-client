import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class BtcLbtcConfirmDialog extends StatelessWidget {
  final BigInt amount;
  final bool isPegIn;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const BtcLbtcConfirmDialog({
    super.key,
    required this.amount,
    required this.isPegIn,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final amountBtc = amount.toDouble() / 100000000;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surfaceColor,
      title: Text(
        isPegIn ? 'Confirmar Peg-in' : 'Confirmar Peg-out',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPegIn
                ? 'Você vai enviar BTC onchain e receberá LBTC na Liquid Network.'
                : 'Você vai enviar LBTC e receberá BTC onchain.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _InfoRow(
            label: 'Quantidade:',
            value: '${amountBtc.toStringAsFixed(8)} BTC',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Taxa estimada:',
            value: '~0.00001 BTC',
            isSecondary: true,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Tempo estimado:',
            value: '~10-60 minutos',
            isSecondary: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Confirmar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isSecondary;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSecondary ? Colors.grey[500] : Colors.grey[400],
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isSecondary ? FontWeight.normal : FontWeight.bold,
            color: isSecondary ? Colors.grey[400] : Colors.white,
          ),
        ),
      ],
    );
  }
}
