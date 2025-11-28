import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:bdk_flutter/bdk_flutter.dart' as bdk;
import 'package:mooze_mobile/shared/infra/breez/providers/client_provider.dart';
import 'package:mooze_mobile/shared/infra/bdk/providers/datasource_provider.dart';

class RefundState {
  final List<RefundableSwap>? refundableSwaps;
  final RecommendedFees? recommendedFees;
  final String? bitcoinAddress;
  final BigInt? selectedFeeRate;
  final bool isLoading;
  final String? error;
  final String? refundTxId;
  final DateTime? lastFeeUpdate;

  RefundState({
    this.refundableSwaps,
    this.recommendedFees,
    this.bitcoinAddress,
    this.selectedFeeRate,
    this.isLoading = false,
    this.error,
    this.refundTxId,
    this.lastFeeUpdate,
  });

  RefundState copyWith({
    List<RefundableSwap>? refundableSwaps,
    RecommendedFees? recommendedFees,
    String? bitcoinAddress,
    BigInt? selectedFeeRate,
    bool? isLoading,
    String? error,
    String? refundTxId,
    DateTime? lastFeeUpdate,
  }) {
    return RefundState(
      refundableSwaps: refundableSwaps ?? this.refundableSwaps,
      recommendedFees: recommendedFees ?? this.recommendedFees,
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

  RefundNotifier(this.ref) : super(RefundState());

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
            final results = await Future.wait([
              client.listRefundables(),
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

            state = state.copyWith(
              refundableSwaps: refundables,
              recommendedFees: fees,
              bitcoinAddress: address,
              selectedFeeRate: fees.hourFee,
              isLoading: false,
              lastFeeUpdate: DateTime.now(),
            );
          } catch (e) {
            state = state.copyWith(
              isLoading: false,
              error: 'Erro ao carregar dados de reembolso: $e',
            );
          }
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erro inesperado: $e');
    }
  }

  Future<RecommendedFees> _loadRecommendedFeesWithFallback(
    BreezSdkLiquid client,
  ) async {
    if (state.recommendedFees != null && state.lastFeeUpdate != null) {
      final timeSinceUpdate = DateTime.now().difference(state.lastFeeUpdate!);
      if (timeSinceUpdate < _cacheDuration) {
        return state.recommendedFees!;
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

  Future<void> processRefund() async {
    if (state.bitcoinAddress == null || state.bitcoinAddress!.trim().isEmpty) {
      state = state.copyWith(
        error: 'Por favor, insira um endereço Bitcoin válido',
      );
      return;
    }

    if (state.refundableSwaps == null || state.refundableSwaps!.isEmpty) {
      state = state.copyWith(error: 'Nenhum swap reembolsável encontrado');
      return;
    }

    if (state.selectedFeeRate == null) {
      state = state.copyWith(error: 'Por favor, selecione uma taxa');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

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
          final swap = state.refundableSwaps!.first;

          final refundRequest = RefundRequest(
            swapAddress: swap.swapAddress,
            refundAddress: state.bitcoinAddress!.trim(),
            feeRateSatPerVbyte: state.selectedFeeRate!.toInt(),
          );

          final response = await client.refund(req: refundRequest);

          state = state.copyWith(
            isLoading: false,
            refundTxId: response.refundTxId,
          );
        } catch (e) {
          state = state.copyWith(
            isLoading: false,
            error: 'Erro ao processar reembolso: $e',
          );
        }
      },
    );
  }
}

final refundProvider =
    StateNotifierProvider.autoDispose<RefundNotifier, RefundState>((ref) {
      return RefundNotifier(ref);
    });
