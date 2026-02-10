import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget que exibe uma linha de status com label e valor
class StatusItem extends StatelessWidget {
  final String label;
  final String value;
  final bool copiable;
  final VoidCallback? onTap;

  const StatusItem({
    super.key,
    required this.label,
    required this.value,
    this.copiable = false,
    this.onTap,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        if (copiable) ...[
          const SizedBox(width: 8),
          Icon(Icons.copy, size: 16, color: Colors.grey[500]),
        ],
      ],
    );

    if (copiable || onTap != null) {
      return InkWell(
        onTap: onTap ?? () => _copyToClipboard(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: content,
    );
  }
}
