import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_stream_controller.dart';

class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(anySyncInProgressProvider);

    return syncStatus.when(
      data: (isSyncing) {
        if (!isSyncing) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Sincronizando...',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class DetailedSyncProgress extends ConsumerWidget {
  const DetailedSyncProgress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liquidSync = ref.watch(datasourceSyncProgressProvider('Liquid'));
    final bitcoinSync = ref.watch(datasourceSyncProgressProvider('BDK'));
    final breezSync = ref.watch(datasourceSyncProgressProvider('Breez'));

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status de Sincronização',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDatasourceStatus(context, 'Liquid', liquidSync),
            const Divider(),
            _buildDatasourceStatus(context, 'Bitcoin', bitcoinSync),
            const Divider(),
            _buildDatasourceStatus(context, 'Lightning', breezSync),
          ],
        ),
      ),
    );
  }

  Widget _buildDatasourceStatus(
    BuildContext context,
    String name,
    AsyncValue<SyncProgress> progress,
  ) {
    return progress.when(
      data: (p) {
        final icon = switch (p.status) {
          SyncStatus.completed => Icons.check_circle,
          SyncStatus.syncing => Icons.sync,
          SyncStatus.error => Icons.error,
          _ => Icons.circle_outlined,
        };

        final color = switch (p.status) {
          SyncStatus.completed => Colors.green,
          SyncStatus.syncing => Colors.blue,
          SyncStatus.error => Colors.red,
          _ => Colors.grey,
        };

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading:
              p.status == SyncStatus.syncing
                  ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(color),
                      value: p.progress,
                    ),
                  )
                  : Icon(icon, color: color, size: 24),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(_getStatusText(p)),
          trailing:
              p.progress != null && p.status == SyncStatus.syncing
                  ? Text(
                    '${(p.progress! * 100).toStringAsFixed(0)}%',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  )
                  : null,
        );
      },
      loading:
          () => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text(name),
            subtitle: const Text('Carregando...'),
          ),
      error:
          (err, _) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.error, color: Colors.red, size: 24),
            title: Text(name),
            subtitle: Text('Erro: ${err.toString()}'),
          ),
    );
  }

  String _getStatusText(SyncProgress progress) {
    switch (progress.status) {
      case SyncStatus.completed:
        return 'Sincronizado';
      case SyncStatus.syncing:
        if (progress.progress != null) {
          return 'Sincronizando ${(progress.progress! * 100).toStringAsFixed(0)}%';
        }
        return 'Sincronizando...';
      case SyncStatus.error:
        return 'Erro: ${progress.errorMessage ?? "Desconhecido"}';
      default:
        return 'Aguardando...';
    }
  }
}

void showSyncProgressBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder:
        (context) => DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder:
              (context, scrollController) => SingleChildScrollView(
                controller: scrollController,
                child: const DetailedSyncProgress(),
              ),
        ),
  );
}
