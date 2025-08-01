import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../breez/providers.dart';

class BootstrapState {
  final bool isInitialized;
  final String? error;

  const BootstrapState({
    required this.isInitialized,
    this.error,
  });

  bool get hasError => error != null;
  bool get isReady => isInitialized && !hasError;
}

final bootstrapProvider = FutureProvider<BootstrapState>((ref) async {
  try {
    // Wait for Breez client to initialize
    final breezResult = await ref.read(breezClientProvider.future);
    
    return breezResult.fold(
      (error) => BootstrapState(
        isInitialized: false,
        error: 'Breez initialization failed: $error',
      ),
      (breezClient) => const BootstrapState(isInitialized: true),
    );
  } catch (e) {
    return BootstrapState(
      isInitialized: false,
      error: 'Bootstrap failed: ${e.toString()}',
    );
  }
});