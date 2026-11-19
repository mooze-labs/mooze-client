import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/authentication/providers/ensure_auth_session_provider.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/status_banner.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/glass_sheet_badge.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

final apiDownProvider = StateProvider<bool>((ref) => false);

final apiStatusCodeProvider = StateProvider<int?>((ref) => null);

/// Opens the [ApiDownSheet], which explains that the Mooze API is down and
/// offers [onRetry].
Future<void> showApiDownSheet(BuildContext context, {VoidCallback? onRetry}) {
  return showFloatingGlassSheet<void>(
    context,
    builder: (_) => ApiDownSheet(onRetry: onRetry),
  );
}

/// Floating glass sheet that explains that the Mooze API is down: what
/// stops working while it is down, and when to try again.
///
/// The retry button closes the sheet first and then runs [onRetry]. The
/// close button only closes the sheet.
class ApiDownSheet extends StatelessWidget {
  const ApiDownSheet({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return GlassSheet(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassSheetHeader(
            title: t.api_down_dialog_title,
            leading: GlassSheetBadge(
              icon: PixIcons.warning,
              color: context.appColors.warning,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t.api_down_dialog_body,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MaintenanceNotice(
                    title: t.api_down_maintenance_title,
                    effects: t.api_down_warning_list,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.api_down_dialog_footer,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: PrimaryButton(
              text: t.common_retry,
              onPressed: () {
                Navigator.of(context).pop();
                onRetry?.call();
              },
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                // The way back stays neutral. The brand color is for the
                // main action.
                foregroundColor: context.colors.textPrimary,
                minimumSize: const Size(64, 48),
              ),
              child: Text(t.common_close),
            ),
          ),
        ],
      ),
    );
  }
}

/// The likely cause and what stops working, in a tint of the warning color.
/// The icon and the tint carry the color; the text keeps the primary and
/// secondary text colors, so it stays readable.
class _MaintenanceNotice extends StatelessWidget {
  const _MaintenanceNotice({required this.title, required this.effects});

  final String title;

  /// One effect per line.
  final String effects;

  @override
  Widget build(BuildContext context) {
    final warning = context.appColors.warning;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PixIcon(PixIcons.warning, size: 20, color: warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  effects,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.5,
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

class ApiDownIndicator extends ConsumerWidget {
  final VoidCallback? onRetry;

  const ApiDownIndicator({super.key, this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isApiDown = ref.watch(apiDownProvider);
    final authState = ref.watch(ensureAuthSessionProvider);

    if (!isApiDown || authState.isLoading) {
      return const SizedBox.shrink();
    }

    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: StatusBanner(
        icon: PixIcons.warning,
        color: context.appColors.warning,
        title: t.api_down_dialog_title,
        message: t.status_banner_hint,
        onTap: () => showApiDownSheet(context, onRetry: onRetry),
      ),
    );
  }
}

class ApiDownIndicatorIcon extends ConsumerWidget {
  final VoidCallback? onRetry;

  const ApiDownIndicatorIcon({super.key, this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isApiDown = ref.watch(apiDownProvider);
    final authState = ref.watch(ensureAuthSessionProvider);

    if (!isApiDown || authState.isLoading) {
      return const SizedBox.shrink();
    }

    return IconButton(
      onPressed: () => showApiDownSheet(context, onRetry: onRetry),
      icon: PixIcon(
        PixIcons.offline,
        size: 22,
        color: context.appColors.warning,
      ),
      tooltip: AppLocalizations.of(context).api_down_dialog_title,
    );
  }
}
