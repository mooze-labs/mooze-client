import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

class NoLiquidityDialog extends StatelessWidget {
  const NoLiquidityDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const NoLiquidityDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.info_outline,
              color: context.colors.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Sem liquidez',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.colors.primaryColor,
            ),
          ),
        ],
      ),
      content: Text(
        'No momento, não há liquidez disponível para este par de ativos. Tente novamente mais tarde ou escolha outro par.',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: context.colors.textSecondary,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Entendi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.colors.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
