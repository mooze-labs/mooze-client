import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/connectivity/widgets.dart';
import 'package:mooze_mobile/themes/motion.dart';

/// The service statuses that need the user, as banners under the home
/// header: the API down. The offline state and the failed sync are not
/// here: the status island in the header shows them.
class StatusIndicators extends ConsumerWidget {
  final VoidCallback? onRetrySync;

  const StatusIndicators({super.key, this.onRetrySync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A banner that shows or hides moves the content below it smoothly.
    return AnimatedSize(
      duration: Motion.of(context, Motion.durationBase),
      curve: Motion.curveMove,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [ApiDownIndicator(onRetry: onRetrySync)],
      ),
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
