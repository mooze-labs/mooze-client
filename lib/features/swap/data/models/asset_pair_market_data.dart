/// Chart data point from market data stream
class AssetPairMarketData {
  final double close;
  final double high;
  final double low;
  final double open;
  final String time;
  final double volume;

  AssetPairMarketData({
    required this.close,
    required this.high,
    required this.low,
    required this.open,
    required this.time,
    required this.volume,
  });

  factory AssetPairMarketData.fromJson(Map<String, dynamic> json) {
    return AssetPairMarketData(
      close: json['close'],
      high: json['high'],
      low: json['low'],
      open: json['open'],
      time: json['time'],
      volume: json['volume'],
    );
  }
}
