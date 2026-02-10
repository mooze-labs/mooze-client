import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/refund/refund_provider.dart';

class MockRefundNotifier extends RefundNotifier {
  MockRefundNotifier(super.ref);

  @override
  Future<void> loadRefundData() async {
    state = state.copyWith(isLoading: true, error: null);

    await Future.delayed(const Duration(seconds: 1));

    final mockSwaps = [
      RefundableSwap(
        swapAddress:
            'bc1p62e2r4jnr3v985uqk06yjc2s7422js2qqp35kumg03xwyw8wzyfqz678nc',
        timestamp:
            DateTime(2026, 2, 4, 0, 17, 10).millisecondsSinceEpoch ~/ 1000,
        amountSat: BigInt.from(52574),
        lastRefundTxId: null,
      ),
      RefundableSwap(
        swapAddress: 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh',
        timestamp:
            DateTime.now()
                .subtract(const Duration(hours: 6))
                .millisecondsSinceEpoch ~/
            1000,
        amountSat: BigInt.from(100000), // 0.001 BTC
        lastRefundTxId: null,
      ),
      RefundableSwap(
        swapAddress: 'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq',
        timestamp:
            DateTime.now()
                .subtract(const Duration(days: 2))
                .millisecondsSinceEpoch ~/
            1000,
        amountSat: BigInt.from(250000), // 0.0025 BTC
        lastRefundTxId:
            '2622dd4f5a1c69f7cea5763482fa470d726dd3cfa316790b22067cf62e6bc268',
      ),
    ];

    final mockFees = RecommendedFees(
      economyFee: BigInt.from(3),
      hourFee: BigInt.from(6),
      halfHourFee: BigInt.from(12),
      fastestFee: BigInt.from(25),
      minimumFee: BigInt.from(1),
    );

    state = state.copyWith(
      refundableSwaps: mockSwaps,
      recommendedFees: mockFees,
      bitcoinAddress: 'bc1qtest1234567890abcdefghijklmnopqrstuvwxyz',
      selectedFeeRate: mockFees.hourFee,
      isLoading: false,
      lastFeeUpdate: DateTime.now(),
    );
  }

  @override
  void setSelectedFeeRate(BigInt feeRate) {
    state = state.copyWith(selectedFeeRate: feeRate);
  }

  @override
  void setBitcoinAddress(String address) {
    state = state.copyWith(bitcoinAddress: address);
  }

  @override
  Future<List<RefundFeeOption>> fetchRefundFeeOptions({
    required RefundParams params,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final feeOptions = <RefundFeeOption>[
      RefundFeeOption(
        feeRateSatPerVbyte: BigInt.from(3),
        txFeeSat: BigInt.from(450), // ~150 vBytes * 3 sat/vB
      ),
      RefundFeeOption(
        feeRateSatPerVbyte: BigInt.from(6),
        txFeeSat: BigInt.from(900), // ~150 vBytes * 6 sat/vB
      ),
      RefundFeeOption(
        feeRateSatPerVbyte: BigInt.from(12),
        txFeeSat: BigInt.from(1800), // ~150 vBytes * 12 sat/vB
      ),
      RefundFeeOption(
        feeRateSatPerVbyte: BigInt.from(25),
        txFeeSat: BigInt.from(3750), // ~150 vBytes * 25 sat/vB
      ),
    ];

    return feeOptions;
  }

  @override
  Future<PrepareRefundResponse> prepareRefund({
    required PrepareRefundRequest req,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return PrepareRefundResponse(
      txVsize: 150,
      txFeeSat: BigInt.from(req.feeRateSatPerVbyte * 150),
    );
  }

  @override
  Future<RefundResponse> processRefund({required RefundRequest req}) async {
    state = state.copyWith(isLoading: true, error: null);

    await Future.delayed(const Duration(seconds: 2));

    final random = DateTime.now().millisecond;
    if (random % 10 != 0) {
      final mockTxId =
          'refund${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';

      state = state.copyWith(isLoading: false, refundTxId: mockTxId);

      await loadRefundData();

      return RefundResponse(refundTxId: mockTxId);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro simulado: Falha na transmissão da transação',
      );
      throw Exception('Erro simulado: Falha na transmissão da transação');
    }
  }
}
