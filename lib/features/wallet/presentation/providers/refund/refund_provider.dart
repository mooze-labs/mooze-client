import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:bdk_flutter/bdk_flutter.dart' as bdk;
import 'package:mooze_mobile/shared/infra/breez/providers/client_provider.dart';
import 'package:mooze_mobile/shared/infra/bdk/providers/datasource_provider.dart';

/// A class that encapsulates refund request parameters
class RefundParams {
  /// The refund amount
  final int refundAmountSat;

  /// The swap address for the refund
  final String swapAddress;

  /// The destination address for the refund
  final String toAddress;

  /// Constructor for RefundParams
  const RefundParams({
    required this.refundAmountSat,
    required this.swapAddress,
    required this.toAddress,
  });
}

/// Represents a fee option for refund with associated cost details
class RefundFeeOption {
  final BigInt feeRateSatPerVbyte;
  final BigInt txFeeSat;

  RefundFeeOption({required this.feeRateSatPerVbyte, required this.txFeeSat});

  /// Check if this fee option is affordable given the refund amount
  bool isAffordable({required int feeCoverageSat}) {
    return txFeeSat <= BigInt.from(feeCoverageSat);
  }
}

class RefundState {
  final List<RefundableSwap>? refundableSwaps;
  final RecommendedFees? recommendedFees;
  final List<RefundFeeOption>? refundFeeOptions;
  final String? bitcoinAddress;
  final BigInt? selectedFeeRate;
  final bool isLoading;
  final String? error;
  final String? refundTxId;
  final DateTime? lastFeeUpdate;
  final int? currentRetry;
  final int? maxRetries;

  RefundState({
    this.refundableSwaps,
    this.recommendedFees,
    this.refundFeeOptions,
    this.bitcoinAddress,
    this.selectedFeeRate,
    this.isLoading = false,
    this.error,
    this.refundTxId,
    this.lastFeeUpdate,
    this.currentRetry,
    this.maxRetries,
  });

  RefundState copyWith({
    List<RefundableSwap>? refundableSwaps,
    RecommendedFees? recommendedFees,
    List<RefundFeeOption>? refundFeeOptions,
    String? bitcoinAddress,
    BigInt? selectedFeeRate,
    bool? isLoading,
    String? error,
    String? refundTxId,
    DateTime? lastFeeUpdate,
    int? currentRetry,
    int? maxRetries,
  }) {
    return RefundState(
      refundableSwaps: refundableSwaps ?? this.refundableSwaps,
      recommendedFees: recommendedFees ?? this.recommendedFees,
      refundFeeOptions: refundFeeOptions ?? this.refundFeeOptions,
      bitcoinAddress: bitcoinAddress ?? this.bitcoinAddress,
      selectedFeeRate: selectedFeeRate ?? this.selectedFeeRate,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      refundTxId: refundTxId ?? this.refundTxId,
      lastFeeUpdate: lastFeeUpdate ?? this.lastFeeUpdate,
      currentRetry: currentRetry,
      maxRetries: maxRetries,
    );
  }
}

class FallbackFees {
  static const int economy = 2;
  static const int hour = 5;
  static const int halfHour = 10;
  static const int fastest = 20;
  static const int minimum = 1;

  static RecommendedFees toRecommendedFees() {
    return RecommendedFees(
      economyFee: BigInt.from(economy),
      hourFee: BigInt.from(hour),
      halfHourFee: BigInt.from(halfHour),
      fastestFee: BigInt.from(fastest),
      minimumFee: BigInt.from(minimum),
    );
  }
}

class RefundNotifier extends StateNotifier<RefundState> {
  final Ref ref;

  static const Duration _cacheDuration = Duration(minutes: 5);
  // Aumentado para internet lenta: 5 tentativas com delays maiores
  static const int _maxRetries = 5;
  static const Duration _initialRetryDelay = Duration(seconds: 3);

  RefundNotifier(this.ref) : super(RefundState());

  /// Executes an async function with retry logic and exponential backoff
  Future<T> _retryWithBackoff<T>(Future<T> Function() operation) async {
    int attempts = 0;
    Duration delay = _initialRetryDelay;

    while (attempts < _maxRetries) {
      try {
        // Update state with current retry attempt
        if (mounted && attempts > 0) {
          state = state.copyWith(
            currentRetry: attempts,
            maxRetries: _maxRetries,
          );
        }

        return await operation();
      } catch (e) {
        attempts++;
        final errorString = e.toString().toLowerCase();

        // Check if it's a timeout or network error that can be retried
        final isRetryable =
            errorString.contains('timedout') ||
            errorString.contains('timeout') ||
            errorString.contains('connection') ||
            errorString.contains('network');

        if (!isRetryable || attempts >= _maxRetries) {
          rethrow;
        }

        // Wait before retrying with exponential backoff
        await Future.delayed(delay);
        delay *= 2; // Double the delay for next attempt (3s, 6s, 12s, 24s, 48s)
      }
    }

    throw Exception('Retry limit exceeded');
  }

  /// Formats error messages for better user experience
  String _formatErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timedout') || errorString.contains('timeout')) {
      return 'Tempo esgotado ao conectar com o servidor. Verifique sua conexão com a internet e tente novamente.';
    }

    if (errorString.contains('connection') || errorString.contains('network')) {
      return 'Erro de conexão. Verifique sua internet e tente novamente.';
    }

    if (errorString.contains('429') ||
        errorString.contains('too many requests') ||
        errorString.contains('rate limit')) {
      return 'Muitas requisições. Aguarde alguns minutos e tente novamente.';
    }

    return 'Erro ao carregar dados de reembolso: $error';
  }

  Future<void> loadRefundData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final breezClientResult = await ref.read(breezClientProvider.future);

      await breezClientResult.fold(
        (error) {
          state = state.copyWith(
            isLoading: false,
            error: 'Erro ao conectar com Breez SDK: $error',
          );
        },
        (client) async {
          try {
            // Use retry logic for listRefundables which accesses external APIs
            final results = await Future.wait([
              _retryWithBackoff(() => client.listRefundables()),
              _loadRecommendedFeesWithFallback(client),
            ]);

            final refundables = results[0] as List<RefundableSwap>;
            final fees = results[1] as RecommendedFees;

            String? address;
            try {
              final datasourceResult = await ref.read(
                bdkDatasourceProvider.future,
              );
              await datasourceResult.fold((error) {}, (datasource) async {
                final addressInfo = datasource.wallet.getAddress(
                  addressIndex: const bdk.AddressIndex.increase(),
                );
                address = addressInfo.address.toString();
              });
            } catch (e) {
              // Error getting address
            }

            if (!mounted) return;

            state = state.copyWith(
              refundableSwaps: refundables,
              recommendedFees: fees,
              bitcoinAddress: address,
              selectedFeeRate: fees.hourFee,
              isLoading: false,
              lastFeeUpdate: DateTime.now(),
              currentRetry: null,
              maxRetries: null,
            );
          } catch (e) {
            if (!mounted) return;

            state = state.copyWith(
              isLoading: false,
              error: _formatErrorMessage(e),
            );
          }
        },
      );
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(isLoading: false, error: _formatErrorMessage(e));
    }
  }

  Future<RecommendedFees> _loadRecommendedFeesWithFallback(
    BreezSdkLiquid client,
  ) async {
    // Check if mounted before accessing state
    if (mounted) {
      if (state.recommendedFees != null && state.lastFeeUpdate != null) {
        final timeSinceUpdate = DateTime.now().difference(state.lastFeeUpdate!);
        if (timeSinceUpdate < _cacheDuration) {
          return state.recommendedFees!;
        }
      }
    }

    try {
      return await client.recommendedFees();
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('429') ||
          errorString.contains('too many requests') ||
          errorString.contains('rate limit')) {
        return FallbackFees.toRecommendedFees();
      }
      rethrow;
    }
  }

  void setSelectedFeeRate(BigInt feeRate) {
    state = state.copyWith(selectedFeeRate: feeRate);
  }

  void setBitcoinAddress(String address) {
    state = state.copyWith(bitcoinAddress: address);
  }

  /// Fetches refund fee options for a given [params].
  ///
  /// Returns a list of [RefundFeeOption] representing different fee rates.
  /// Estimates transaction fees based on typical refund transaction size (~150 vBytes).
  Future<List<RefundFeeOption>> fetchRefundFeeOptions({
    required RefundParams params,
  }) async {
    try {
      final breezClientResult = await ref.read(breezClientProvider.future);

      return await breezClientResult.fold(
        (error) {
          throw Exception('Erro ao conectar com Breez SDK: $error');
        },
        (client) async {
          final recommendedFees = await _loadRecommendedFeesWithFallback(
            client,
          );

          // Estimated transaction size for a typical refund transaction
          // Refunds are usually ~150-200 vBytes
          const estimatedTxVsize = 150;

          // Build fee options list with all fee rates
          final feeOptions = <RefundFeeOption>[
            RefundFeeOption(
              feeRateSatPerVbyte: recommendedFees.economyFee,
              txFeeSat:
                  recommendedFees.economyFee * BigInt.from(estimatedTxVsize),
            ),
            RefundFeeOption(
              feeRateSatPerVbyte: recommendedFees.hourFee,
              txFeeSat: recommendedFees.hourFee * BigInt.from(estimatedTxVsize),
            ),
            RefundFeeOption(
              feeRateSatPerVbyte: recommendedFees.halfHourFee,
              txFeeSat:
                  recommendedFees.halfHourFee * BigInt.from(estimatedTxVsize),
            ),
            RefundFeeOption(
              feeRateSatPerVbyte: recommendedFees.fastestFee,
              txFeeSat:
                  recommendedFees.fastestFee * BigInt.from(estimatedTxVsize),
            ),
          ];

          // Optionally try to get exact fees using prepareRefund (non-blocking)
          // This will update the estimates if successful, but won't fail if it doesn't work
          try {
            final prepareResponse = await client.prepareRefund(
              req: PrepareRefundRequest(
                swapAddress: params.swapAddress,
                refundAddress: params.toAddress,
                feeRateSatPerVbyte: recommendedFees.hourFee.toInt(),
              ),
            );

            // If prepareRefund succeeds, we can use the actual vsize
            final actualVsize = prepareResponse.txVsize;

            // Update all fee options with actual transaction size
            return [
              RefundFeeOption(
                feeRateSatPerVbyte: recommendedFees.economyFee,
                txFeeSat: recommendedFees.economyFee * BigInt.from(actualVsize),
              ),
              RefundFeeOption(
                feeRateSatPerVbyte: recommendedFees.hourFee,
                txFeeSat: recommendedFees.hourFee * BigInt.from(actualVsize),
              ),
              RefundFeeOption(
                feeRateSatPerVbyte: recommendedFees.halfHourFee,
                txFeeSat:
                    recommendedFees.halfHourFee * BigInt.from(actualVsize),
              ),
              RefundFeeOption(
                feeRateSatPerVbyte: recommendedFees.fastestFee,
                txFeeSat: recommendedFees.fastestFee * BigInt.from(actualVsize),
              ),
            ];
          } catch (e) {
            // prepareRefund failed, but that's ok - use estimated fees
            // This can happen if the swap is not ready yet or other temporary issues
          }

          return feeOptions;
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Prepares a refund transaction for a failed or expired swap.
  ///
  /// Returns a [PrepareRefundResponse] with transaction details.
  Future<PrepareRefundResponse> prepareRefund({
    required PrepareRefundRequest req,
  }) async {
    try {
      final breezClientResult = await ref.read(breezClientProvider.future);

      return await breezClientResult.fold(
        (error) {
          throw Exception('Erro ao conectar com Breez SDK: $error');
        },
        (client) async {
          final response = await client.prepareRefund(req: req);
          return response;
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Validates a Bitcoin address format
  bool _isValidBitcoinAddress(String address) {
    // Basic validation for Bitcoin addresses
    // Legacy (P2PKH): starts with 1, 26-35 chars
    // SegWit (P2SH): starts with 3, 26-35 chars
    // Native SegWit (Bech32): starts with bc1, 42-62 chars
    // Testnet: starts with tb1, m, n, or 2

    if (address.isEmpty) return false;

    // Check for valid Bitcoin address patterns
    final legacyPattern = RegExp(r'^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$');
    final segwitPattern = RegExp(r'^bc1[a-z0-9]{39,59}$');
    final testnetPattern = RegExp(r'^(tb1|[mn2])[a-z0-9]{25,59}$');

    return legacyPattern.hasMatch(address) ||
        segwitPattern.hasMatch(address) ||
        testnetPattern.hasMatch(address);
  }

  /// Broadcasts a refund transaction for a failed or expired swap.
  ///
  /// Returns the refund transaction ID upon success.
  Future<RefundResponse> processRefund({required RefundRequest req}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Validate address format before sending to Breez SDK
      if (!_isValidBitcoinAddress(req.refundAddress)) {
        throw Exception(
          'Endereço Bitcoin inválido. Use um endereço Bitcoin válido (Legacy, SegWit ou Native SegWit).',
        );
      }

      final breezClientResult = await ref.read(breezClientProvider.future);

      final response = await breezClientResult.fold(
        (error) {
          throw Exception('Erro ao conectar com Breez SDK: $error');
        },
        (client) async {
          final refundResponse = await client.refund(req: req);

          if (!mounted) return refundResponse;

          state = state.copyWith(
            isLoading: false,
            refundTxId: refundResponse.refundTxId,
          );

          // Refresh refundables list after successful refund
          // Only if still mounted to avoid dispose errors
          if (mounted) {
            await loadRefundData();
          }

          return refundResponse;
        },
      );

      return response;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Erro ao processar reembolso: $e',
        );
      }
      rethrow;
    }
  }
}

final refundProvider =
    StateNotifierProvider.autoDispose<RefundNotifier, RefundState>((ref) {
      return RefundNotifier(ref);
    });
