import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: onSurface),
      label: Text(label, style: Theme.of(context).textTheme.labelLarge),
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.actionButtonBackground,
        foregroundColor: onSurface,
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
