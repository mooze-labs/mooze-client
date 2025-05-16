enum Network { bitcoin, liquid }

class NetworkFee {
  final int absoluteFees;
  final double feeRate;

  NetworkFee({required this.absoluteFees, required this.feeRate});
}
