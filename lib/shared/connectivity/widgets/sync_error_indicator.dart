import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/authentication/providers/ensure_auth_session_provider.dart';

final syncErrorProvider = StateProvider<bool>((ref) => false);

final syncErrorMessageProvider = StateProvider<String?>((ref) => null);

class SyncErrorIndicator extends ConsumerWidget {
  final VoidCallback? onRetry;

  const SyncErrorIndicator({super.key, this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSyncError = ref.watch(syncErrorProvider);
    final authState = ref.watch(ensureAuthSessionProvider);

    if (!hasSyncError || authState.isLoading) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _showSyncErrorDialog(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sync_problem_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 5),
            Text(
              'Erro de Sync',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSyncErrorDialog(BuildContext context, WidgetRef ref) {
    final errorMessage = ref.read(syncErrorMessageProvider);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.sync_problem_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text('Erro de Sincronização'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Não foi possível sincronizar com a API da Mooze.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: Theme.of(context).colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sem sincronização, não é possível usar o PIX',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Detalhes: $errorMessage',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onRetry?.call();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ),
    );
  }
}

class SyncErrorIndicatorIcon extends ConsumerWidget {
  final VoidCallback? onRetry;

  const SyncErrorIndicatorIcon({super.key, this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSyncError = ref.watch(syncErrorProvider);
    final authState = ref.watch(ensureAuthSessionProvider);

    if (!hasSyncError || authState.isLoading) {
      return const SizedBox.shrink();
    }

    return IconButton(
      onPressed: () => _showSyncErrorDialog(context, ref),
      icon: Icon(
        Icons.sync_problem_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
      tooltip: 'Erro ao sincronizar com API - PIX indisponível',
    );
  }

  void _showSyncErrorDialog(BuildContext context, WidgetRef ref) {
    final errorMessage = ref.read(syncErrorMessageProvider);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.sync_problem_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text('Erro de Sincronização'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Não foi possível sincronizar com a API da Mooze.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: Theme.of(context).colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sem sincronização, não é possível usar o PIX',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Detalhes: $errorMessage',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onRetry?.call();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ),
    );
  }
}
