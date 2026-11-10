import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import '../providers/connectivity_provider.dart';

/// A small glass pill that says the app is offline and shows saved prices.
///
/// It is the same glass pill as the parts of the `StatusIsland`: a cloud icon
/// in the warning tone and the label in the primary text color. The tap
/// target is at least 48 tall, while the pill keeps its small size.
class OfflineIndicator extends ConsumerWidget {
  final VoidCallback? onTap;

  const OfflineIndicator({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUsingCache = ref.watch(isUsingCacheProvider);

    if (!isUsingCache) {
      return const SizedBox.shrink();
    }

    final pill = LiquidGlass(
      blurBackdrop: false,
      // A small control: the short shadow keeps it light on the page.
      shadows: GlassStyle.of(context).controlShadows,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PixIcon(
              PixIcons.offline,
              size: 16,
              color: context.appColors.warning,
            ),
            const SizedBox(width: 6),
            Text(
              'Offline',
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: onTap != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Center(
              widthFactor: 1,
              child: onTap == null ? pill : PressScale(child: pill),
            ),
          ),
        ),
      ),
    );
  }
}

class OfflineIndicatorIcon extends ConsumerWidget {
  final VoidCallback? onTap;

  const OfflineIndicatorIcon({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUsingCache = ref.watch(isUsingCacheProvider);

    if (!isUsingCache) {
      return const SizedBox.shrink();
    }

    return IconButton(
      onPressed: onTap,
      icon: Icon(
        Icons.cloud_off_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
      tooltip: AppLocalizations.of(context).offline_indicator_tooltip,
    );
  }
}
