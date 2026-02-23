/// Server status info
class ServerStatus {
  final double elementsFeeRate;
  final int minPegInAmount;
  final int minPegOutAmount;
  final double serverFeePercentPegIn;
  final double serverFeePercentPegOut;

  ServerStatus({
    required this.elementsFeeRate,
    required this.minPegInAmount,
    required this.minPegOutAmount,
    required this.serverFeePercentPegIn,
    required this.serverFeePercentPegOut,
  });

  factory ServerStatus.fromJson(Map<String, dynamic> json) {
    return ServerStatus(
      elementsFeeRate: json['elements_fee_rate'],
      minPegInAmount: json['min_peg_in_amount'],
      minPegOutAmount: json['min_peg_out_amount'],
      serverFeePercentPegIn: json['server_fee_percent_peg_in'],
      serverFeePercentPegOut: json['server_fee_percent_peg_out'],
    );
  }
}
