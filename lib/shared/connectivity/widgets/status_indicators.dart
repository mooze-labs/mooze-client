import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/connectivity/widgets.dart';

class StatusIndicators extends ConsumerWidget {
  final VoidCallback? onRetrySync;

  const StatusIndicators({super.key, this.onRetrySync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ApiDownIndicator(onRetry: onRetrySync),
        SyncErrorIndicator(onRetry: onRetrySync),
        const OfflineIndicator(),
      ],
    );
  }
}

class StatusIndicatorsIcons extends ConsumerWidget {
  final VoidCallback? onRetrySync;
  final VoidCallback? onOfflineTap;

  const StatusIndicatorsIcons({super.key, this.onRetrySync, this.onOfflineTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ApiDownIndicatorIcon(onRetry: onRetrySync),
        SyncErrorIndicatorIcon(onRetry: onRetrySync),
        OfflineIndicatorIcon(onTap: onOfflineTap),
      ],
    );
  }
}
