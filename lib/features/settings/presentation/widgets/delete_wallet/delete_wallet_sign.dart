import 'package:flutter/material.dart';

class DeleteWalletSign extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const DeleteWalletSign({
    super.key,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final colorScheme = theme.colorScheme;
    final textColor = isSelected ? primaryColor : colorScheme.onSurface;
    final borderColor = isSelected ? primaryColor : colorScheme.onSurface;
    final checkBorderColor = isSelected ? primaryColor : colorScheme.outline;
    final iconBackground =
        isSelected ? primaryColor : colorScheme.surfaceContainerLowest;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título e ícone de seleção
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: iconBackground,
                          border: Border.all(color: checkBorderColor, width: 2),
                        ),
                        child: isSelected ? Icon(Icons.check, size: 16) : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
