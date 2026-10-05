import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

class ActionButton extends StatelessWidget {
  final IconData? icon;
  final String? svgAsset;
  final String label;
  final VoidCallback onPressed;

  final bool isPrimary;

  const ActionButton({
    super.key,
    this.icon,
    this.svgAsset,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  }) : assert(
         icon != null || svgAsset != null,
         'Either icon or svgAsset must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final backgroundColor =
        isPrimary ? colors.primaryColor : colors.actionButtonBackground;
    final foregroundColor = isPrimary ? colors.onPrimaryColor : onSurface;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon:
          svgAsset != null
              ? SvgPicture.asset(
                svgAsset!,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  foregroundColor,
                  BlendMode.srcIn,
                ),
              )
              : Icon(icon, size: 18, color: foregroundColor),
      label: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: foregroundColor),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
