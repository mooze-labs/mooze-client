import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/domain/entities/refund.dart';
import 'package:mooze_mobile/features/wallet/di/providers/wallet_repository_provider.dart';

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
  final int feeRateSatPerVbyte;
  final int txFeeSat;

  RefundFeeOption({required this.feeRateSatPerVbyte, required this.txFeeSat});

  /// Check if this fee option is affordable given the refund amount
  bool isAffordable({required int feeCoverageSat}) {
    return txFeeSat <= feeCoverageSat;
  }
}

class RefundState {
  final List<RefundableSwap>? refundableSwaps;
  final MempoolFees? recommendedFees;
  final List<RefundFeeOption>? refundFeeOptions;
  final String? bitcoinAddress;
  final int? selectedFeeRate;
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
    MempoolFees? recommendedFees,
    List<RefundFeeOption>? refundFeeOptions,
    String? bitcoinAddress,
    int? selectedFeeRate,
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

  static MempoolFees toMempoolFees() {
    return const MempoolFees(
      minimumFee: minimum,
      economyFee: economy,
      hourFee: hour,
      halfHourFee: halfHour,
      fastestFee: fastest,
    );
  }
}

/// Refund flow state notifier (retry-aware variant).
///
/// Phase 2.3.3-prep-A3: routes through `walletRepositoryProvider` (legacy)
/// instead of `breezClientProvider` and `bdkDatasourceProvider` directly.
/// The retry/backoff layer is preserved — it now wraps repository calls
/// (which themselves wrap Breez SDK calls), so behavior is unchanged.
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
      final repoResult = await ref.read(walletRepositoryProvider.future);

      await repoResult.fold(
        (error) {
          state = state.copyWith(
            isLoading: false,
            error: 'Erro ao acessar repositório da carteira: $error',
          );
        },
        (repo) async {
          try {
            // Use retry logic for listRefundables which accesses external APIs
            final results = await Future.wait([
              _retryWithBackoff(() async {
                final r = await repo.listRefundableSwaps().run();
                return r.fold<List<RefundableSwap>>(
                  (err) => throw Exception(err.toString()),
                  (xs) => xs,
                );
              }),
              _loadRecommendedFeesWithFallback(repo),
            ]);

            final refundables = results[0] as List<RefundableSwap>;
            final fees = results[1] as MempoolFees;

            String? address;
            try {
              final addressResult =
                  await repo.getBitcoinReceiveAddress().run();
              addressResult.fold((_) {}, (a) => address = a);
            } catch (_) {
              // Address fetch is best-effort; UI prompts user otherwise.
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

  Future<MempoolFees> _loadRecommendedFeesWithFallback(dynamic repo) async {
    if (mounted) {
      if (state.recommendedFees != null && state.lastFeeUpdate != null) {
        final timeSinceUpdate = DateTime.now().difference(state.lastFeeUpdate!);
        if (timeSinceUpdate < _cacheDuration) {
          return state.recommendedFees!;
        }
      }
    }

    try {
      final result = await repo.getRecommendedFees().run();
      return result.fold<MempoolFees>(
        (err) {
          final errorString = err.toString().toLowerCase();
          if (errorString.contains('429') ||
              errorString.contains('too many requests') ||
              errorString.contains('rate limit')) {
            return FallbackFees.toMempoolFees();
          }
          throw Exception(err.toString());
        },
        (fees) => fees as MempoolFees,
      );
    } catch (_) {
      return FallbackFees.toMempoolFees();
    }
  }

  void setSelectedFeeRate(int feeRate) {
    state = state.copyWith(selectedFeeRate: feeRate);
  }

  void setBitcoinAddress(String address) {
    state = state.copyWith(bitcoinAddress: address);
  }

  /// Fetches refund fee options for a given [params].
  Future<List<RefundFeeOption>> fetchRefundFeeOptions({
    required RefundParams params,
  }) async {
    final repoResult = await ref.read(walletRepositoryProvider.future);

    return await repoResult.fold(
      (error) {
        throw Exception('Erro ao acessar repositório da carteira: $error');
      },
      (repo) async {
        final recommendedFees = await _loadRecommendedFeesWithFallback(repo);

        const estimatedTxVsize = 150;

        final feeOptions = <RefundFeeOption>[
          RefundFeeOption(
            feeRateSatPerVbyte: recommendedFees.economyFee,
            txFeeSat: recommendedFees.economyFee * estimatedTxVsize,
          ),
          RefundFeeOption(
            feeRateSatPerVbyte: recommendedFees.hourFee,
            txFeeSat: recommendedFees.hourFee * estimatedTxVsize,
          ),
          RefundFeeOption(
            feeRateSatPerVbyte: recommendedFees.halfHourFee,
            txFeeSat: recommendedFees.halfHourFee * estimatedTxVsize,
          ),
          RefundFeeOption(
            feeRateSatPerVbyte: recommendedFees.fastestFee,
            txFeeSat: recommendedFees.fastestFee * estimatedTxVsize,
          ),
        ];

        try {
          final prepareResult = await repo
              .prepareRefund(PrepareRefundParams(
                swapAddress: params.swapAddress,
                refundAddress: params.toAddress,
                feeRateSatPerVbyte: recommendedFees.hourFee,
              ))
              .run();

          return prepareResult.fold<List<RefundFeeOption>>(
            (_) => feeOptions, // prepareRefund failed; use estimates
            (outcome) {
              final actualVsize = outcome.txVsize;
              return [
                RefundFeeOption(
                  feeRateSatPerVbyte: recommendedFees.economyFee,
                  txFeeSat: recommendedFees.economyFee * actualVsize,
                ),
                RefundFeeOption(
                  feeRateSatPerVbyte: recommendedFees.hourFee,
                  txFeeSat: recommendedFees.hourFee * actualVsize,
                ),
                RefundFeeOption(
                  feeRateSatPerVbyte: recommendedFees.halfHourFee,
                  txFeeSat: recommendedFees.halfHourFee * actualVsize,
                ),
                RefundFeeOption(
                  feeRateSatPerVbyte: recommendedFees.fastestFee,
                  txFeeSat: recommendedFees.fastestFee * actualVsize,
                ),
              ];
            },
          );
        } catch (_) {
          return feeOptions;
        }
      },
    );
  }

  /// Validates a Bitcoin address format
  bool _isValidBitcoinAddress(String address) {
    if (address.isEmpty) return false;

    final legacyPattern = RegExp(r'^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$');
    final segwitPattern = RegExp(r'^bc1[a-z0-9]{39,59}$');
    final testnetPattern = RegExp(r'^(tb1|[mn2])[a-z0-9]{25,59}$');

    return legacyPattern.hasMatch(address) ||
        segwitPattern.hasMatch(address) ||
        testnetPattern.hasMatch(address);
  }

  /// Broadcasts a refund transaction for a failed or expired swap.
  Future<RefundOutcome> processRefund({
    required ExecuteRefundParams params,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (!_isValidBitcoinAddress(params.refundAddress)) {
        throw Exception(
          'Endereço Bitcoin inválido. Use um endereço Bitcoin válido (Legacy, SegWit ou Native SegWit).',
        );
      }

      final repoResult = await ref.read(walletRepositoryProvider.future);

      final outcome = await repoResult.fold<Future<RefundOutcome>>(
        (error) async {
          throw Exception('Erro ao acessar repositório da carteira: $error');
        },
        (repo) async {
          final result = await repo.executeRefund(params).run();
          return result.fold<RefundOutcome>(
            (err) =>
                throw Exception('Erro ao processar reembolso: ${err.toString()}'),
            (o) => o,
          );
        },
      );

      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          refundTxId: outcome.refundTxId,
        );
        await loadRefundData();
      }

      return outcome;
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
