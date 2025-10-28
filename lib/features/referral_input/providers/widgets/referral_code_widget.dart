import 'package:flutter/material.dart';

class ReferralCodeWidget extends StatelessWidget {
  final String code;
  final TextEditingController controller;
  final ColorScheme colorScheme;
  final bool isLoading;
  final Function()? onSubmit;

  const ReferralCodeWidget({
    super.key,
    required this.code,
    required this.controller,
    required this.colorScheme,
    this.isLoading = false,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_add_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Digite o código de indicação',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            enabled: !isLoading,
            decoration: InputDecoration(
              hintText: 'Ex: ABC123',
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              suffixIcon:
                  isLoading
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary,
                            ),
                          ),
                        ),
                      )
                      : IconButton(
                        onPressed: onSubmit,
                        icon: Icon(
                          Icons.arrow_forward_rounded,
                          color: colorScheme.primary,
                        ),
                      ),
            ),
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit?.call(),
          ),
        ],
      ),
    );
  }
}
