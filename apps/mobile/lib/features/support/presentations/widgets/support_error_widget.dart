import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The load error of the user code, in a glass panel.
///
/// The negative color marks the state on the icon well only. The retry
/// action is a neutral lens pill, because the brand pink stays on the
/// main action of the screen.
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

  static const double _wellSize = 48;

  @override
  Widget build(BuildContext context) {
    final negative = context.colors.negativeColor;

    return GlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _wellSize,
            height: _wellSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: negative.withValues(alpha: 0.14),
              border: Border.all(color: negative.withValues(alpha: 0.24)),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: negative,
              size: _wellSize / 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _RetryPill(
            label: 'Tentar novamente',
            isLoading: isLoading,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

/// A full-width neutral pill with the lens fill and a hairline border.
class _RetryPill extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _RetryPill({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  static const _radius = BorderRadius.all(Radius.circular(999));

  @override
  Widget build(BuildContext context) {
    final textColor = context.colors.textPrimary;

    return Semantics(
      button: true,
      enabled: !isLoading,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: _radius,
          child: Ink(
            height: 48,
            decoration: BoxDecoration(
              color: GlassStyle.of(context).lensFill,
              borderRadius: _radius,
              border: Border.all(color: AppSurfaces.hairline(context)),
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: textColor,
                      ),
                    )
                  : Text(
                      label,
                      style: context.textTheme.labelLarge?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
