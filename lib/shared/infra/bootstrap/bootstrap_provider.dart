import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/services/providers/app_logger_provider.dart';
import '../breez/providers.dart';

class BootstrapState {
  final bool isInitialized;
  final String? error;

  const BootstrapState({required this.isInitialized, this.error});

  bool get hasError => error != null;
  bool get isReady => isInitialized && !hasError;
}

final bootstrapProvider = FutureProvider<BootstrapState>((ref) async {
  final logger = ref.read(appLoggerProvider);
  logger.info('Bootstrap', 'Starting application bootstrap process');

  try {
    // Wait for Breez client to initialize
    logger.debug('Bootstrap', 'Waiting for Breez client initialization...');
    final breezResult = await ref.read(breezClientProvider.future);

    return breezResult.fold(
      (error) {
        logger.error('Bootstrap', 'Breez initialization failed', error: error);
        return BootstrapState(
          isInitialized: false,
          error: 'Breez initialization failed: $error',
        );
      },
      (breezClient) {
        logger.info('Bootstrap', 'Bootstrap completed successfully');
        return const BootstrapState(isInitialized: true);
      },
    );
  } catch (e, stackTrace) {
    logger.critical(
      'Bootstrap',
      'Bootstrap failed with exception',
      error: e,
      stackTrace: stackTrace,
    );
    return BootstrapState(
      isInitialized: false,
      error: 'Bootstrap failed: ${e.toString()}',
    );
  }
});
