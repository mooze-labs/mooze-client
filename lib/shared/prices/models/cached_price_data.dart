import 'dart:convert';

class CachedPriceData {
  final double price;
  final DateTime timestamp;
  final String currency;
  final String assetId;

  CachedPriceData({
    required this.price,
    required this.timestamp,
    required this.currency,
    required this.assetId,
  });

  bool get isValid {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inMinutes <= 5;
  }

  bool get isRecentEnough {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inHours <= 1;
  }

  Map<String, dynamic> toJson() {
    return {
      'price': price,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'currency': currency,
      'assetId': assetId,
    };
  }

  factory CachedPriceData.fromJson(Map<String, dynamic> json) {
    return CachedPriceData(
      price: (json['price'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      currency: json['currency'] as String,
      assetId: json['assetId'] as String,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  static CachedPriceData fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return CachedPriceData.fromJson(json);
  }
}
