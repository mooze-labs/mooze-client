import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets/buttons/secondary_button.dart';

class SupportErrorWidget extends StatelessWidget {
  final String title;
  final String message;
  final ColorScheme colorScheme;
  final VoidCallback onRetry;
  final bool isLoading;

  const SupportErrorWidget({
    super.key,
    required this.title,
    required this.message,
    required this.colorScheme,
    required this.onRetry,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: colorScheme.error, size: 32),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: SecondaryButton(
              text: 'Tentar novamente',
              isLoading: isLoading,
              onPressed: onRetry,
            ),
          ),
        ],
      ),
    );
  }
}
