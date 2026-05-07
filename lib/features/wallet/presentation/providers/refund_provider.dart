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

/// Refund flow state notifier.
///
/// Phase 2.3.3-prep-A2: routes through `walletRepositoryProvider` (legacy)
/// instead of reading `breezClientProvider` and `bdkDatasourceProvider`
/// directly. The legacy repository's refund methods return V2 domain
/// types (`RefundableSwap`, `MempoolFees`, etc.) — the eventual Phase
/// 2.3.3 atomic flip retargets the same call sites at the V2-backed
/// adapter without touching this file.
class RefundNotifier extends StateNotifier<RefundState> {
  final Ref ref;

  static const Duration _cacheDuration = Duration(minutes: 5);

  RefundNotifier(this.ref) : super(RefundState());

  Future<void> loadRefundData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repoResult = await ref.read(walletRepositoryProvider.future);

      await repoResult.fold(
        (error) async {
          state = state.copyWith(
            isLoading: false,
            error: 'Erro ao acessar repositório da carteira: $error',
          );
        },
        (repo) async {
          try {
            final results = await Future.wait([
              repo.listRefundableSwaps().run(),
              _loadRecommendedFeesWithFallback(repo),
            ]);

            final refundablesEither = results[0]
                as dynamic; // Either<WalletError, List<RefundableSwap>>
            final fees = results[1] as MempoolFees;

            final refundables = refundablesEither.fold<List<RefundableSwap>>(
              (_) => const <RefundableSwap>[],
              (xs) => xs as List<RefundableSwap>,
            );

            String? address;
            try {
              final addressResult = await repo.getBitcoinReceiveAddress().run();
              addressResult.fold((_) {}, (a) => address = a);
            } catch (_) {
              // Address fetch is best-effort; UI can prompt the user.
            }

            if (!mounted) return;

            state = state.copyWith(
              refundableSwaps: refundables,
              recommendedFees: fees,
              bitcoinAddress: address,
              selectedFeeRate: fees.hourFee,
              isLoading: false,
              lastFeeUpdate: DateTime.now(),
            );
          } catch (e) {
            if (!mounted) return;

            state = state.copyWith(
              isLoading: false,
              error: 'Erro ao carregar dados de reembolso: $e',
            );
          }
        },
      );
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(isLoading: false, error: 'Erro inesperado: $e');
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
  ///
  /// Returns a list of [RefundFeeOption] representing different fee rates.
  /// Estimates transaction fees based on typical refund transaction size (~150 vBytes);
  /// upgrades to actual vsize via `prepareRefund` when the SDK can compute it.
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

        // Estimated transaction size for a typical refund transaction
        // Refunds are usually ~150-200 vBytes
        const estimatedTxVsize = 150;

        // Build fee options list with all fee rates
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

        // Optionally try to get exact fees using prepareRefund (non-blocking)
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
          // prepareRefund failed, but that's ok - use estimated fees.
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
  ///
  /// Returns the [RefundOutcome] (carrying the on-chain txid) on success.
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
