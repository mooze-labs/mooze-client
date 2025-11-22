class BitcoinFeeEstimate {
  final int lowFeeSatPerVByte;
  final int mediumFeeSatPerVByte;
  final int fastFeeSatPerVByte;
  final Map<String, double> feeByBlockTarget;

  BitcoinFeeEstimate({
    required this.lowFeeSatPerVByte,
    required this.mediumFeeSatPerVByte,
    required this.fastFeeSatPerVByte,
    required this.feeByBlockTarget,
  });
}
