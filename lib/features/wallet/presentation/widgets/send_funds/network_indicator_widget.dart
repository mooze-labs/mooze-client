import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import '../../providers/send_funds/address_provider.dart';
import '../../providers/send_funds/network_detection_provider.dart';

class NetworkIndicatorWidget extends ConsumerWidget {
  const NetworkIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final address = ref.watch(addressStateProvider);

    if (address.isEmpty) return const SizedBox.shrink();

    final networkType = ref.watch(networkDetectionProvider(address));
    final isUnknown = networkType == NetworkType.unknown;

    final fg = isUnknown ? cs.error : cs.onSurface;
    final bg =
        isUnknown
            ? cs.error.withValues(alpha: 0.10)
            : cs.onSurface.withValues(alpha: 0.05);
    final borderColor =
        isUnknown
            ? cs.error.withValues(alpha: 0.35)
            : cs.onSurface.withValues(alpha: 0.08);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icon(networkType),
              size: 14,
              color: isUnknown ? cs.error : context.colors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              isUnknown
                  ? t.wallet_send_network_unidentified
                  : _label(t, networkType),
              style: theme.textTheme.labelMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(NetworkType type) => switch (type) {
    NetworkType.bitcoin => Icons.link_rounded,
    NetworkType.lightning => Icons.bolt_rounded,
    NetworkType.liquid => Icons.water_drop_outlined,
    NetworkType.unknown => Icons.error_outline_rounded,
  };

  String _label(AppLocalizations t, NetworkType type) => switch (type) {
    NetworkType.bitcoin => t.wallet_send_network_bitcoin,
    NetworkType.lightning => t.wallet_send_network_lightning,
    NetworkType.liquid => t.wallet_send_network_liquid,
    NetworkType.unknown => t.wallet_send_network_unknown,
  };
}
