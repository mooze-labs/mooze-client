import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_hub_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_empty_state.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_key_tile.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_surface_card.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Pix key management.
///
/// Mooze has no service to register or delete a Pix key, so the screen lists
/// the keys and states which operations are unavailable instead of offering
/// buttons that cannot work.
class PixKeysScreen extends ConsumerWidget {
  const PixKeysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final keys = ref.watch(pixHubKeysProvider);

    return PixScreenScaffold(
      title: t.pix_hub_my_keys,
      onRefresh: () async => ref.invalidate(pixHubKeysProvider),
      children: [
        keys.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(28),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => PixEmptyState(
            icon: PixIcons.offline,
            title: t.pix_hub_error_title,
            message: t.pix_hub_error_body,
            actionLabel: t.common_retry,
            onAction: () => ref.invalidate(pixHubKeysProvider),
          ),
          data: (list) => PixSurfaceCard(
            child: list.isEmpty
                ? PixEmptyState(
                    icon: PixIcons.key,
                    title: t.pix_hub_empty_keys_title,
                    message: t.pix_hub_empty_keys_body,
                    isCompact: true,
                  )
                : Column(
                    children: [for (final key in list) PixKeyTile(pixKey: key)],
                  ),
          ),
        ),
        const SizedBox(height: 20),
        const _UnavailableOperations(),
      ],
    );
  }
}

/// States the key operations the app cannot perform today.
class _UnavailableOperations extends StatelessWidget {
  const _UnavailableOperations();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: context.colors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.pix_hub_keys_unavailable_title,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            t.pix_hub_keys_unavailable_body,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
