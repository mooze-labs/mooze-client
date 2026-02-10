import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/authentication/providers/ensure_auth_session_provider.dart';

final apiDownProvider = StateProvider<bool>((ref) => false);

final apiStatusCodeProvider = StateProvider<int?>((ref) => null);

void _showApiDownDialog(
  BuildContext context,
  WidgetRef ref,
  VoidCallback? onRetry,
) {
  final statusCode = ref.read(apiStatusCodeProvider);

  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.cloud_off_rounded,
                color: Colors.orange[300],
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text('API Indisponível'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A API da Mooze está temporariamente indisponível.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: Colors.orange[300],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'O servidor pode estar em manutenção',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Colors.orange[300],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• PIX não disponível\n• Sincronização pausada\n• Dados em cache sendo usados',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[400],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              // if (statusCode != null) ...[
              //   const SizedBox(height: 12),
              //   Text(
              //     'Código de erro: $statusCode',
              //     style: Theme.of(context).textTheme.bodySmall?.copyWith(
              //       color: Colors.grey[400],
              //       fontFamily: 'monospace',
              //     ),
              //   ),
              // ],
              const SizedBox(height: 12),
              Text(
                'Por favor, tente novamente em alguns minutos.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
              ),
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
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange[700],
              ),
            ),
          ],
        ),
  );
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

    return GestureDetector(
      onTap: () => _showApiDownDialog(context, ref, onRetry),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 16, color: Colors.orange[300]),
            const SizedBox(width: 5),
            Text(
              'API Indisponível',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.orange[300],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
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
      onPressed: () => _showApiDownDialog(context, ref, onRetry),
      icon: Icon(Icons.cloud_off_rounded, color: Colors.orange[300]),
      tooltip: 'API da Mooze indisponível',
    );
  }
}
