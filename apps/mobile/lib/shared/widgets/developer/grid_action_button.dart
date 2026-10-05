import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Action button used inside the developer tools grid
class GridActionButton extends StatelessWidget {
  const GridActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.enabled = true,
    this.loading = false,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final bool enabled;
  final bool loading;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final extra = context.appColors;

    final dim = !enabled || loading;
    final effectiveIconColor = enabled
        ? (iconColor ?? cs.primary)
        : cs.onSurface.withValues(alpha: 0.25);
    final effectiveLabelColor = enabled
        ? (textColor ?? cs.onSurface)
        : cs.onSurface.withValues(alpha: 0.30);
    final effectiveBgColor = enabled
        ? (backgroundColor ?? cs.onSurface.withValues(alpha: 0.04))
        : cs.onSurface.withValues(alpha: 0.02);
    final borderColor = loading
        ? cs.primary.withValues(alpha: 0.30)
        : cs.onSurface.withValues(alpha: enabled ? 0.07 : 0.04);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled && !loading ? onPressed : null,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: effectiveBgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
              boxShadow: loading
                  ? [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.18),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                _LeadingGlyph(
                  icon: icon,
                  color: effectiveIconColor,
                  loading: loading,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: dim && !loading ? 0.55 : 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: tt.bodyMedium?.copyWith(
                            color: effectiveLabelColor,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: tt.bodySmall?.copyWith(
                              color: extra.textTertiary,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeadingGlyph extends StatelessWidget {
  const _LeadingGlyph({
    required this.icon,
    required this.color,
    required this.loading,
  });

  final IconData icon;
  final Color color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: loading ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: loading
            ? SizedBox(
                key: const ValueKey('spinner'),
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            : Icon(icon, key: ValueKey(icon), color: color, size: 18),
      ),
    );
  }
}
