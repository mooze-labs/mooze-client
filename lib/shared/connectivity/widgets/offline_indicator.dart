import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';

class OfflineIndicator extends ConsumerWidget {
  final VoidCallback? onTap;

  const OfflineIndicator({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUsingCache = ref.watch(isUsingCacheProvider);

    if (!isUsingCache) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 4),
            Text(
              'Offline',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
      tooltip: 'App está offline - usando preços em cache',
    );
  }
}
