import 'package:flutter/material.dart';

/// Warning/info card for legal document screens.
///
/// Use [containerColor], [borderColor], [iconColor], and [textColor]
/// to customize the card's appearance (e.g. error colors for terms,
/// tertiary colors for license).
class LegalDocumentWarningCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color containerColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;

  const LegalDocumentWarningCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.containerColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: textTheme.bodySmall?.copyWith(
                    color: textColor.withValues(alpha: 0.9),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
