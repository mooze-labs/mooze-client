import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Small pill that marks a screen or a record as demonstration data.
class PixDemoBadge extends StatelessWidget {
  /// Set to true over a colored header, where the badge needs light colors.
  final bool onDarkSurface;

  const PixDemoBadge({super.key, this.onDarkSurface = false});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final foreground = onDarkSurface ? Colors.white : context.appColors.warning;
    final background = onDarkSurface
        ? Colors.white.withValues(alpha: 0.18)
        : context.appColors.warning.withValues(alpha: 0.14);

    return Semantics(
      label: t.pix_hub_demo_badge_semantics,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PixIcon(PixIcons.demo, size: 13, color: foreground),
            const SizedBox(width: 5),
            Text(
              t.pix_hub_demo_badge,
              style: context.textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
