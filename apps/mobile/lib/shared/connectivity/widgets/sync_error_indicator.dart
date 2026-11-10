import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/authentication/providers/ensure_auth_session_provider.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/glass_sheet_badge.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

final syncErrorProvider = StateProvider<bool>((ref) => false);

final syncErrorMessageProvider = StateProvider<String?>((ref) => null);

/// Whether the app shows the failed sync. It waits for the session check
/// to end, so a retry does not flash the error.
final syncErrorVisibleProvider = Provider<bool>(
  (ref) =>
      ref.watch(syncErrorProvider) &&
      !ref.watch(ensureAuthSessionProvider).isLoading,
);

class SyncErrorIndicatorIcon extends ConsumerWidget {
  final VoidCallback? onRetry;

  const SyncErrorIndicatorIcon({super.key, this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(syncErrorVisibleProvider)) {
      return const SizedBox.shrink();
    }

    return IconButton(
      onPressed: () => showSyncErrorSheet(context, ref, onRetry: onRetry),
      icon: Icon(
        Icons.sync_problem_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
      tooltip: AppLocalizations.of(context).sync_error_warning,
    );
  }
}

/// Opens the [SyncErrorSheet], which explains the failed sync and offers
/// [onRetry].
void showSyncErrorSheet(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onRetry,
}) {
  // Technical details surface only in debug builds — never to end users.
  final debugDetails = kDebugMode ? ref.read(syncErrorMessageProvider) : null;

  showFloatingGlassSheet<void>(
    context,
    builder: (_) =>
        SyncErrorSheet(onRetry: onRetry, debugDetails: debugDetails),
  );
}

/// Floating glass sheet that explains a failed sync of the Mooze services
/// and offers to retry it.
class SyncErrorSheet extends StatelessWidget {
  const SyncErrorSheet({super.key, this.onRetry, this.debugDetails});

  final VoidCallback? onRetry;

  /// Technical details of the error. Only debug builds pass them.
  final String? debugDetails;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final debugDetails = this.debugDetails;

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
            title: t.sync_error_dialog_title,
            leading: GlassSheetBadge(
              icon: PixIcons.error,
              color: context.colorScheme.error,
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
                    t.sync_error_dialog_body,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ErrorNotice(message: t.sync_error_warning),
                  if (debugDetails != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'debug: $debugDetails',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textTertiary,
                      ),
                    ),
                  ],
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

/// The reason of the error, in a tint of the error color. The icon and the
/// tint carry the color; the text keeps the primary text color, so it stays
/// readable.
class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final error = context.colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PixIcon(PixIcons.warning, size: 20, color: error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
