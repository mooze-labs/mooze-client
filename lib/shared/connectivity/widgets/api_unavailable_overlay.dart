import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/api_down_indicator.dart';
import 'package:mooze_mobile/shared/widgets/buttons/secondary_button.dart';

class ApiUnavailableOverlay extends ConsumerWidget {
  final VoidCallback? onRetry;
  final String? customMessage;
  final bool showBackButton;
  final VoidCallback? onBack;

  const ApiUnavailableOverlay({
    super.key,
    this.onRetry,
    this.customMessage,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isApiDown = ref.watch(apiDownProvider);
    final statusCode = ref.watch(apiStatusCodeProvider);

    if (!isApiDown) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 64,
                  color: Colors.orange[300],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'API Indisponível',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange[300],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                customMessage ??
                    'O servidor da Mooze está temporariamente indisponível.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                    width: 1,
                  ),
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
                            'Funcionalidades temporariamente indisponíveis',
                            style: TextStyle(
                              color: Colors.orange[300],
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• PIX não disponível\n'
                      '• Sincronização pausada\n'
                      '• Dados em cache sendo usados',
                      style: TextStyle(
                        color: Colors.grey[400],
                        height: 1.5,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // if (statusCode != null) ...[
              //   const SizedBox(height: 16),
              //   Text(
              //     'Código de erro: $statusCode',
              //     style: TextStyle(
              //       color: Colors.grey[500],
              //       fontFamily: 'monospace',
              //       fontSize: 12,
              //     ),
              //   ),
              // ],
              const SizedBox(height: 32),
              SecondaryButton(
                text: 'Tentar Novamente',
                onPressed: onRetry ?? () {},
              ),
              if (showBackButton) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onBack ?? () => Navigator.of(context).pop(),
                  child: Text(
                    'Voltar',
                    style: TextStyle(
                      color: Colors.orange[300],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
