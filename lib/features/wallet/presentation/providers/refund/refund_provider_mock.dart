import 'package:mooze_mobile/domain/entities/refund.dart';
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
        timestamp: DateTime(2026, 2, 4, 0, 17, 10),
        amountSat: 52574,
        lastRefundTxId: null,
      ),
      RefundableSwap(
        swapAddress: 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        amountSat: 100000, // 0.001 BTC
        lastRefundTxId: null,
      ),
      RefundableSwap(
        swapAddress: 'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        amountSat: 250000, // 0.0025 BTC
        lastRefundTxId:
            '2622dd4f5a1c69f7cea5763482fa470d726dd3cfa316790b22067cf62e6bc268',
      ),
    ];

    final mockFees = const MempoolFees(
      minimumFee: 1,
      economyFee: 3,
      hourFee: 6,
      halfHourFee: 12,
      fastestFee: 25,
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
  void setSelectedFeeRate(int feeRate) {
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
      RefundFeeOption(feeRateSatPerVbyte: 3, txFeeSat: 450),
      RefundFeeOption(feeRateSatPerVbyte: 6, txFeeSat: 900),
      RefundFeeOption(feeRateSatPerVbyte: 12, txFeeSat: 1800),
      RefundFeeOption(feeRateSatPerVbyte: 25, txFeeSat: 3750),
    ];

    return feeOptions;
  }

  @override
  Future<RefundOutcome> processRefund({
    required ExecuteRefundParams params,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    await Future.delayed(const Duration(seconds: 2));

    final random = DateTime.now().millisecond;
    if (random % 10 != 0) {
      final mockTxId =
          'refund${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';

      state = state.copyWith(isLoading: false, refundTxId: mockTxId);

      await loadRefundData();

      return RefundOutcome(refundTxId: mockTxId);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Simulated error: transaction broadcast failed',
      );
      throw Exception('Simulated error: transaction broadcast failed');
    }
  }
}
